using System;
using System.Linq;
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

            var url = $"https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key={_apiKey}";

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

            var url = $"https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key={_apiKey}";

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

            var url = $"https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key={_apiKey}";

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

        public async Task<ChatResponseDto> ChatAsync(ChatRequestDto request)
        {
            var url = $"https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key={_apiKey}";

            var weakStr   = request.WeakLessons.Any()   ? string.Join(", ", request.WeakLessons)   : "-";
            var strongStr = request.StrongLessons.Any() ? string.Join(", ", request.StrongLessons) : "-";

            // System prompt — uygulama bilgisi dahil, token dengeli
            var todayTasks = request.TodayTasks != null && request.TodayTasks.Any()
                ? string.Join(", ", request.TodayTasks.Select((t, i) => $"[{i}] {t.SubjectName} ({t.TaskType}, {t.DurationMinutes}dk, id:{t.Id})"))
                : "Bugün görev yok";

            var systemPrompt =
                $"Sen 'AI Study Coach' uygulamasının Türkçe kişisel öğrenci koçusun. Adın Koç.\n" +
                $"Öğrenci: {request.UserName ?? "Öğrenci"} | Sınav: {request.TargetExam ?? "-"} | Alan: {request.SelectedArea ?? "-"}\n" +
                $"Zayıf dersler: {weakStr} | Güçlü dersler: {strongStr}\n" +
                $"Bugünkü program: {todayTasks}\n\n" +
                "UYGULAMA DETAYLARI:\n" +
                "Program nasıl oluşur: Onboarding'de seçilen hafta içi/sonu çalışma saati, zayıf/güçlü dersler ve çalışma tipine (yoğun/dengeli/hafif) göre AI otomatik haftalık program oluşturur. Zayıf dersler öncelikli, güçlü dersler destekleyici bloklar olarak yerleşir. Her blok konu, soru çözümü, deneme veya tekrar tipinde olabilir.\n" +
                "Program değişikliği: Profil sekmesi → 'Ders Profilim' bölümünden zayıf/güçlü ders seçimi değiştirilebilir; değişince program yeniden üretilir.\n" +
                "Konu ekleme: Ana sayfa → göreve tıkla → 'Konu Ata'. Manuel görev için ana sayfa sağ alt + butonu.\n" +
                "Pomodoro: Göreve tıkla → 'Dersi Başlat' → çalışma ekranı açılır. 'Mola' butonu 5 dk ara verir.\n" +
                "Ortam sesleri: Çalışma ekranındaki 'Ortam Sesleri & Çalışma Yayınları' kartından yağmur, şömine, orman sesi veya Study With Me YouTube yayınları açılır.\n" +
                "Denemeler: Alt menü 'Denemeler' → sınav sonuçlarını gir → net hesaplama, ders bazlı grafik ve trend analizi görürsün.\n" +
                "Gelişimim: XP sistemi var — tamamlanan görev +10 XP, çözülen soru +1 XP, aktif gün +5 XP. Seviyeler: Çırak→Acemi→Gelişen→Uzman. Streak günlük aktivite serisi.\n" +
                "Karanlık mod: Profil sekmesi (alt menü sağ) → 'Karanlık Mod' toggle.\n" +
                "AI Koç kartı: Ana sayfada günlük kişisel koçluk mesajı, bugün ne çalışmalı önerisi ve aksiyon maddeleri gösterir.\n" +
                "Hızlı not: Ana sayfada sol alttaki not ikonu → hızlı not ekle, düzenle, sil.\n" +
                "Haftalık plan görüntüle: Ana sayfa 'Haftalık Planımı İncele' butonu → tüm haftanın görevleri.\n\n" +
                "INTENT KURALLARI — Sadece şu durumlarda JSON döndür, başka hiçbir şey yazma:\n" +
                "A) Kullanıcı programa görev/ders eklemek istiyorsa:\n" +
                "{\"intent\":\"add_task\",\"subjectName\":\"<ders adı>\",\"taskType\":\"konu_anlatimi|soru_cozumu|deneme|tekrar\",\"durationMinutes\":60,\"suggestion\":\"<kullanıcıya gösterilecek öneri metni>\"}\n" +
                "B) Kullanıcı mevcut bir göreve konu atamak istiyorsa:\n" +
                "{\"intent\":\"assign_topic\",\"suggestion\":\"<kullanıcıya gösterilecek öneri metni>\"}\n" +
                "C) Ders programı değişikliği (zayıf/güçlü ders oranı) istiyorsa:\n" +
                "{\"intent\":\"schedule_update\",\"lessonName\":\"<ders>\",\"action\":\"increase|decrease|swap\",\"reason\":\"<neden>\",\"suggestion\":\"<teklif>\"}\n" +
                "D) Diğer tüm durumlarda normal Türkçe metin yaz, JSON kullanma. Kısa (2-3 cümle) ve samimi ol.\n" +
                "E) Siyaset, haberler gibi konu dışı sorularda nazikçe yönlendir.";

            var allContents = new List<object>
            {
                new { role = "user",  parts = new[] { new { text = systemPrompt } } },
                new { role = "model", parts = new[] { new { text = "Anladım, sana yardımcı olmaya hazırım!" } } }
            };

            // Son 6 mesajı gönder — token limitini aşmamak için geçmişi kısıt
            var msgs = request.Messages
                .SkipWhile(m => m.Role != "user")
                .TakeLast(6)
                .ToList();
            foreach (var m in msgs)
            {
                allContents.Add(new
                {
                    role  = m.Role == "user" ? "user" : "model",
                    parts = new[] { new { text = m.Content } }
                });
            }

            var payload = new { contents = allContents };
            var jsonPayload = JsonSerializer.Serialize(payload);
            var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            HttpResponseMessage response;
            string responseString;
            try
            {
                response = await _httpClient.PostAsync(url, content);
                responseString = await response.Content.ReadAsStringAsync();
            }
            catch (Exception httpEx)
            {
                Console.WriteLine($"[ChatAsync] HTTP error: {httpEx.Message}");
                return new ChatResponseDto { Message = "Şu an bağlantı sorunu yaşıyorum, biraz sonra tekrar dene." };
            }

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"[ChatAsync] Gemini error {response.StatusCode}: {responseString}");
                // 429 = rate limit — kullanıcıya özel mesaj
                if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                    return new ChatResponseDto { Message = "Çok fazla mesaj gönderildi, lütfen 30 saniye bekleyip tekrar dene. 🕐" };
                return new ChatResponseDto { Message = "Şu an yanıt veremiyorum, biraz sonra tekrar dene." };
            }

            try
            {
                using var jsonDoc = JsonDocument.Parse(responseString);

                var rawText = jsonDoc.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text").GetString()?.Trim() ?? "";

                // Intent JSON tespiti
                var trimmed = rawText.TrimStart();
                if (trimmed.StartsWith("{\"intent\""))
                {
                    try
                    {
                        var opts = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                        using var intentDoc = JsonDocument.Parse(trimmed);
                        var intent = intentDoc.RootElement.GetProperty("intent").GetString();

                        if (intent == "schedule_update")
                        {
                            var dto = JsonSerializer.Deserialize<ScheduleUpdateIntentDto>(trimmed, opts);
                            return new ChatResponseDto
                            {
                                Message        = dto?.Suggestion ?? "Ders programını güncelleyeyim mi?",
                                ScheduleIntent = dto
                            };
                        }
                        if (intent == "add_task")
                        {
                            var dto = JsonSerializer.Deserialize<AddTaskIntentDto>(trimmed, opts);
                            return new ChatResponseDto
                            {
                                Message       = dto?.Suggestion ?? "Programa yeni görev ekleyeyim mi?",
                                AddTaskIntent = dto
                            };
                        }
                        if (intent == "assign_topic")
                        {
                            var dto = JsonSerializer.Deserialize<AssignTopicIntentDto>(trimmed, opts);
                            return new ChatResponseDto
                            {
                                Message           = dto?.Suggestion ?? "Hangi göreve konu eklemek istersin?",
                                AssignTopicIntent = dto
                            };
                        }
                    }
                    catch { /* parse başarısız → normal mesaj */ }
                }

                return new ChatResponseDto { Message = rawText };
            }
            catch (Exception parseEx)
            {
                Console.WriteLine($"[ChatAsync] Parse error: {parseEx.Message}\nResponse: {responseString}");
                return new ChatResponseDto { Message = "Yanıt işlenirken bir sorun oluştu, tekrar dene." };
            }
        }

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
