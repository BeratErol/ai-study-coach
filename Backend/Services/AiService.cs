using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Backend.DTOs;
using Microsoft.Extensions.Configuration;

namespace Backend.Services
{
    public class AiService : IAiService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;

        public AiService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _apiKey = configuration["GeminiApiKey"] ?? string.Empty;
        }

        public async Task<AiPlanResponseDto> GenerateStudyPlanAsync(AiPlanRequestDto request)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "YOUR_GEMINI_API_KEY_HERE")
            {
                // Fallback / Mock behavior if API key is not set
                await Task.Delay(1500); // Simulate network delay
                return new AiPlanResponseDto
                {
                    SuggestedName = "Acil Vize Hazırlığı",
                    SuggestedDifficulty = "Zor",
                    RecommendedHours = 3.5,
                    Advice = "Gerçek Gemini API anahtarı eklenmediği için bu otomatik bir yanıttır. Lütfen appsettings.json dosyasını güncelleyin."
                };
            }

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

            var systemPrompt = "Sen bir AI eğitim koçusun. Kullanıcının hedefine göre şu JSON formatında bir plan döndür: {\"SuggestedName\": \"Ders Adı (Örn: Mat-Türev)\", \"SuggestedDifficulty\": \"Kolay\" veya \"Orta\" veya \"Zor\", \"RecommendedHours\": 2.0 (Double türünde, saat cinsinden), \"Advice\": \"Kısa motivasyon ve tavsiye\"}. Sadece ama sadece geçerli bir JSON objesi döndür, markdown tagleri (```json vb.) kullanma.";

            var payload = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = systemPrompt + "\n\nKullanıcı Hedefi: " + request.Prompt }
                        }
                    }
                }
            };

            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(url, content);

            if (!response.IsSuccessStatusCode)
            {
                var errorInfo = await response.Content.ReadAsStringAsync();
                throw new Exception($"AI API Hatası ({response.StatusCode}): {errorInfo}");
            }

            var responseString = await response.Content.ReadAsStringAsync();
            using var jsonDoc = JsonDocument.Parse(responseString);
            
            var textResult = jsonDoc.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text").GetString();

            if (textResult == null) throw new Exception("AI boş yanıt döndürdü.");

            // Temizlik (Eğer inatla markdown veya boşluk geldiyse)
            textResult = textResult.Replace("```json", "").Replace("```", "").Trim();

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var resultDto = JsonSerializer.Deserialize<AiPlanResponseDto>(textResult, options);

            return resultDto ?? throw new Exception("JSON deserialize edilemedi.");
        }
    }
}
