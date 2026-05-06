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

        public async Task<string> GenerateTextRecommendationAsync(string prompt)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "YOUR_GEMINI_API_KEY_HERE")
            {
                await Task.Delay(1000);
                return "AI Önerisi: Son denemelerinizde eksikleriniz var, bu alanlara ağırlık vermelisiniz.";
            }

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

            var systemPrompt = "Sen bir AI eğitim koçusun. Öğrencinin deneme sonuçlarına göre ona cesaret verici, kısa (1-2 cümle) ve hedefe yönelik bir tavsiye metni yaz.";

            var payload = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = systemPrompt + "\n\n" + prompt }
                        }
                    }
                }
            };

            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync(url, content);

            if (!response.IsSuccessStatusCode)
            {
                return "Tavsiye alınırken bir sorun oluştu.";
            }

            var responseString = await response.Content.ReadAsStringAsync();
            using var jsonDoc = JsonDocument.Parse(responseString);
            
            var textResult = jsonDoc.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text").GetString();

            return textResult?.Trim() ?? "Tavsiye bulunamadı.";
        }

        public async Task<DashboardCoachResponseDto> GenerateDashboardCoachAsync(DashboardCoachRequestDto ctx)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "YOUR_GEMINI_API_KEY_HERE")
                return FallbackCoachResponse(ctx.UserName);

            var lessonLines = ctx.Lessons.Select(l =>
                $"- {l.Name}: {l.CompletedTopics}/{l.TotalTopics} konu tamamlandı");

            var examLines = ctx.RecentExams.Take(3).Select(e =>
                $"- {e.Title} ({e.Type}): {e.NetScore} net — {e.Date:dd MMM}");

            var jsonSchema =
                "{\n" +
                "  \"greeting\": \"Kısa selamlama (max 10 kelime)\",\n" +
                "  \"todayFocus\": \"Bugün ne çalışmalı (max 15 kelime)\",\n" +
                "  \"weakAreaWarning\": \"Zayıf alan uyarısı (max 15 kelime, yoksa boş string)\",\n" +
                "  \"motivationNote\": \"Motivasyon cümlesi (max 12 kelime)\",\n" +
                "  \"actionItems\": [\"Madde 1 (max 8 kelime)\", \"Madde 2\", \"Madde 3\"]\n" +
                "}";

            var prompt =
                "Sen bir Türk YKS/LGS öğrenci koçusun. Öğrencinin verilerine bakarak " +
                "kısa, özlü ve motive edici dashboard mesajları üret.\n" +
                "SADECE şu JSON formatında yanıt ver (Türkçe, emoji kullanabilirsin):\n" +
                jsonSchema + "\n" +
                $"Öğrenci adı: {ctx.UserName}\n" +
                $"Hedef sınav: {ctx.TargetExam ?? "Belirtilmemiş"}\n" +
                $"Bu hafta çalışma süresi: {ctx.TotalStudyMinutesThisWeek} dakika\n" +
                "Dersler:\n" +
                string.Join("\n", lessonLines) + "\n" +
                "Son denemeler:\n" +
                string.Join("\n", examLines);

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

            var payload = new
            {
                contents = new[] { new { parts = new[] { new { text = prompt } } } },
                generationConfig = new { temperature = 0.7, maxOutputTokens = 1024 }
            };

            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync(url, content);

            if (!response.IsSuccessStatusCode)
                return FallbackCoachResponse(ctx.UserName);

            try
            {
                var responseString = await response.Content.ReadAsStringAsync();
                using var jsonDoc = JsonDocument.Parse(responseString);
                var raw = jsonDoc.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text").GetString();

                if (raw == null) return FallbackCoachResponse(ctx.UserName);

                raw = raw.Replace("```json", "").Replace("```", "").Trim();
                var start = raw.IndexOf('{');
                var end   = raw.LastIndexOf('}');
                if (start >= 0 && end > start)
                    raw = raw[start..(end + 1)];

                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                return JsonSerializer.Deserialize<DashboardCoachResponseDto>(raw, options)
                    ?? FallbackCoachResponse(ctx.UserName);
            }
            catch
            {
                return FallbackCoachResponse(ctx.UserName);
            }
        }

        private static DashboardCoachResponseDto FallbackCoachResponse(string name) => new()
        {
            Greeting        = $"Merhaba {name}! 👋",
            TodayFocus      = "Bugün en zayıf hissettiğin konuya odaklan.",
            WeakAreaWarning = "",
            MotivationNote  = "Her gün küçük adımlar büyük başarılar getirir! 🚀",
            ActionItems     = new List<string>
            {
                "25 dk Pomodoro oturumu başlat",
                "Notlarını gözden geçir",
                "Bir deneme sorusu çöz"
            }
        };

        public async Task<List<AiPlanResponseDto>> OptimizePlanAsync(int userId, ExamAnalysisDto analysis)
        {
            // In a real scenario, we would send the analysis to Gemini and get a list of JSON objects.
            // For this demo, we simulate a logic that identifies the weakest lesson.
            
            var weakest = analysis.LessonAverages?.OrderBy(a => a.AverageNet).FirstOrDefault();
            string lessonName = weakest?.LessonName ?? "Genel Tekrar";

            await Task.Delay(1500); // Simulate AI thinking

            return new List<AiPlanResponseDto>
            {
                new AiPlanResponseDto { 
                    SuggestedName = $"{lessonName} Telafi - 1", 
                    SuggestedDifficulty = "Orta", 
                    RecommendedHours = 2.0, 
                    Advice = "Zayıf olduğun bu konuyu bugün pekiştirmelisin." 
                },
                new AiPlanResponseDto { 
                    SuggestedName = $"{lessonName} Telafi - 2", 
                    SuggestedDifficulty = "Zor", 
                    RecommendedHours = 3.0, 
                    Advice = "Yarın daha derinlemesine soru çözümü yapmalısın." 
                }
            };
        }
    }
}
