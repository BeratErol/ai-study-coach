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

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}";

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

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}";

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

            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}";

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
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}";

            var weakStr   = request.WeakLessons.Any()   ? string.Join(", ", request.WeakLessons)   : "-";
            var strongStr = request.StrongLessons.Any() ? string.Join(", ", request.StrongLessons) : "-";

            // System prompt — uygulama bilgisi dahil, token dengeli
            // Görev satırı tamamlanma durumunu (✓/⬜) içerir ki Koç hangisinin
            // bittiğini hangisinin kaldığını anında görebilsin.
            var todayTasks = request.TodayTasks != null && request.TodayTasks.Any()
                ? string.Join(", ", request.TodayTasks.Select((t, i) =>
                    $"[{i}] {(t.IsCompleted ? "✓" : "⬜")} {t.SubjectName} ({t.TaskType}, {t.DurationMinutes}dk, id:{t.Id})"))
                : "Bugün görev yok";

            // Bugünkü programdaki ders adlarını ayrı tut — Koç sadece bu listedeki
            // dersleri "bugün başlayalım" gibi cümlelerde kullanmalı.
            var weakSet = new HashSet<string>(request.WeakLessons, StringComparer.OrdinalIgnoreCase);
            var strongSet = new HashSet<string>(request.StrongLessons, StringComparer.OrdinalIgnoreCase);
            var todaySubjects = request.TodayTasks?
                .Where(t => !string.IsNullOrWhiteSpace(t.SubjectName))
                .Select(t => t.SubjectName!)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList() ?? new List<string>();
            var todayWeak   = todaySubjects.Where(s => weakSet.Contains(s)).ToList();
            var todayStrong = todaySubjects.Where(s => strongSet.Contains(s)).ToList();
            var todayOther  = todaySubjects.Where(s => !weakSet.Contains(s) && !strongSet.Contains(s)).ToList();

            var todayWeakStr   = todayWeak.Any()   ? string.Join(", ", todayWeak)   : "(bugün zayıf ders yok)";
            var todayStrongStr = todayStrong.Any() ? string.Join(", ", todayStrong) : "(bugün güçlü ders yok)";
            var todayOtherStr  = todayOther.Any()  ? string.Join(", ", todayOther)  : "-";

            // Tamamlanma özeti — Koç hangi derslerin bittiğini ayrıca bilsin.
            var completedTasks = request.TodayTasks?.Where(t => t.IsCompleted).ToList() ?? new();
            var remainingTasks = request.TodayTasks?.Where(t => !t.IsCompleted).ToList() ?? new();
            var completedStr = completedTasks.Any()
                ? string.Join(", ", completedTasks.Select(t => $"{t.SubjectName} ({t.TaskType}, {t.DurationMinutes}dk)"))
                : "Henüz tamamlanan ders yok";
            var remainingStr = remainingTasks.Any()
                ? string.Join(", ", remainingTasks.Select(t => $"{t.SubjectName} ({t.TaskType}, {t.DurationMinutes}dk)"))
                : "Bugünün tüm dersleri tamamlandı 🎉";
            var totalCount = request.TodayTasks?.Count ?? 0;
            var doneCount = completedTasks.Count;
            var progressStr = totalCount == 0 ? "-" : $"{doneCount}/{totalCount} ders tamamlandı";

            var systemPrompt =
                $"Sen 'AI Study Coach' uygulamasının Türkçe kişisel öğrenci koçusun. Adın 'Koç'.\n" +
                $"ÖĞRENCİ BİLGİLERİ:\n" +
                $"- İsim: {request.UserName ?? "Öğrenci"}\n" +
                $"- Hedef sınav: {request.TargetExam ?? "Belirtilmemiş"}\n" +
                $"- Alan: {request.SelectedArea ?? "Belirtilmemiş"}\n" +
                $"- Genel zayıf dersler (profilde işaretli): {weakStr}\n" +
                $"- Genel güçlü dersler (profilde işaretli): {strongStr}\n\n" +

                $"BUGÜNKÜ PROGRAM (bugün gerçekten yapılacak dersler):\n" +
                $"- Tüm görevler (✓=tamamlandı, ⬜=henüz değil): {todayTasks}\n" +
                $"- İlerleme: {progressStr}\n" +
                $"- ✅ Tamamlanan dersler: {completedStr}\n" +
                $"- ⏳ Kalan (tamamlanmayan) dersler: {remainingStr}\n" +
                $"- Bugünkü programdaki ZAYIF dersler: {todayWeakStr}\n" +
                $"- Bugünkü programdaki GÜÇLÜ dersler: {todayStrongStr}\n" +
                $"- Bugünkü programdaki diğer dersler: {todayOtherStr}\n\n" +

                "═══════════════════════════════════════════\n" +
                "DAVRANIŞ KURALLARI (ÇOK ÖNEMLİ):\n" +
                "═══════════════════════════════════════════\n" +
                "1) ASLA 'ben senin için yapayım', 'ben ekleyeyim', 'ben programını değiştireyim', 'sana ekledim' gibi cümleler kurma. " +
                "Uygulamada hiçbir işlemi sen yapmazsın — tüm işlemleri kullanıcı kendisi yapar.\n" +
                "2) Kullanıcı bir işlemi nasıl yapacağını sorarsa, **adım adım yolu** anlat. " +
                "Örnek doğru cevap: 'Ders konusu eklemek için: Ana sayfada sağ alttaki turuncu + Görev butonuna bas → açılan menüden \"Çalışma Programım İçin Konuları Düzenle\"yi seç → ilgili dersin üzerine tıkla → konu adını yaz ve kaydet.'\n" +
                "3) JSON yazma. Sadece düz, samimi Türkçe metin yaz. Emoji kullanabilirsin ama abartma.\n" +
                "4) Kısa ve net ol (genelde 2-5 cümle, adım adım talimat veriyorsan numaralı liste).\n" +
                "5) Siyaset, haberler, ödev çözme, kişisel sırlar gibi konu dışı sorulara: 'Ben sadece çalışma koçluğu konusunda yardım edebilirim 🎓' diyerek nazikçe yönlendir.\n" +
                "6) Öğrencinin verilerini (zayıf dersler, bugün programı, sınav) bilerek konuş — kişiselleştir.\n" +
                "7) ⚠️ BUGÜN ÇALIŞMA TAVSİYESİ KURALI: 'Bugün ... ile başlayalım', 'önce ... yapalım', 'bugün ... ders öncelikli' gibi cümlelerde **YALNIZCA 'Bugünkü programdaki ZAYIF/GÜÇLÜ dersler' listesindeki dersleri** kullan. Genel zayıf/güçlü listesinde olup bugünün programında olmayan bir ders varsa, o ders için 'bugün başlayalım' deme — sadece genel strateji tavsiyesi verirken (örn. 'TYT Kimya'ya da haftalık olarak ağırlık vermelisin') ondan bahsedebilirsin ve mutlaka 'bugünkü programda yok ama' gibi netleştir. Bugünkü programa müdahale edip olmayan dersi varmış gibi sunma.\n" +
                "8) ✅ TAMAMLAMA FARKINDALIĞI: Bugünün görev listesinde her dersin başında ✓ (tamamlandı) veya ⬜ (henüz değil) işareti var. 'İlerleme', 'Tamamlanan dersler' ve 'Kalan dersler' özetlerini de görüyorsun. Tavsiye verirken:\n" +
                "   - 'Bugün ne çalışmalıyım?' / 'sırada ne var?' sorularında SADECE **kalan (⬜) dersleri** öner. Tamamlanmış (✓) dersi tekrar 'başlayalım' diye sunma.\n" +
                "   - Eğer kullanıcı 'X dersini bitirdim, sırada ne var?' derse önce ✓ olduğunu doğrula, kutla, sonra kalan dersleri öner.\n" +
                "   - Tüm dersler tamamlanmışsa tebrik et ('Bugün hedefini tamamladın 🎉'), genel strateji veya yarına hazırlık önerisi ver.\n" +
                "   - 'Kaç ders kaldı?' / 'durumum ne?' sorularında ilerlemeyi söyle (örn. '4 dersten 2'sini bitirdin, 2 ders kaldı: ...').\n" +
                "   - Kullanıcı 'matematik bitti' gibi belirsiz ifadelerle eski bir dersten bahsediyorsa ve görev listesinde işaretlenmiş ✓ varsa o derse atıfta bulun, kontrol soruları sor.\n\n" +

                "═══════════════════════════════════════════\n" +
                "UYGULAMA REHBERİ — Tüm Özellikler ve Konumları:\n" +
                "═══════════════════════════════════════════\n\n" +

                "📱 GENEL YAPI\n" +
                "Alt menü 4 sekmeden oluşur: Ana Sayfa, Gelişimim, Denemeler, Profil. Sağ üstte (mobil) / sol barda (web) 'AI Koç' butonu seni açar.\n\n" +

                "🏠 ANA SAYFA\n" +
                "- 'Bugünün Görevleri' başlığı ve sınava kalan gün sayısı üst banner'da.\n" +
                "- 'Haftalık Planımı İncele' butonu: 7 günlük tüm programı + 'PDF indir' seçeneğini açar.\n" +
                "- Öncelikli (zayıf) dersler kırmızı şeritte üstte; pekiştirme (güçlü) dersleri turuncu şeritte altta listelenir. Zayıf dersler bitirilmeden güçlü dersler kilitlidir.\n" +
                "- Görev tamamlama: Görev kartındaki sağdaki yuvarlağa basınca tamamlandı işaretlenir.\n" +
                "- Görev başlatma: Görev üzerine tıkla → 'Dersi Başlat' → Pomodoro/çalışma ekranı açılır. 'Tamamlamayı Kaldır' veya 'Görevi Kaldır' (sadece manuel) seçenekleri de buradadır.\n" +
                "- Sağ alttaki turuncu '+ Görev' butonu → açılan menüde 3 seçenek: (1) 'Çalışma Programım İçin Konuları Düzenle' — her güne ait derslere konu atama, (2) 'Kendim Görev Ekle' — manuel ders/süre belirleme, (3) 'Hastayım / Dinlenme Modu' — bugünü dinlenme günü yapar ve tüm görevleri tamamlanmış sayar.\n" +
                "- Sol alttaki turuncu kalem ikonu → 'Hızlı Not Ekle' — başlık+içerik notu kaydeder. Notlar Profil → Notlarım'da görüntülenir.\n\n" +

                "📈 GELİŞİMİM SEKMESİ\n" +
                "- Üstte yeşil banner: sol üstte XP rozeti + altında günlük seri (🔥 streak); sağ üstte toplam XP. Ortada seviye (🌱 Çırak / 📖 Acemi / 📚 Gelişen / 🎓 Uzman) ve XP ilerleme çubuğu.\n" +
                "- 4 stat kart: Tamamlanan oturum, Toplam süre, Çözülen soru, Dinlenme günü.\n" +
                "- 'Soru Gelişimi' (turuncu): Bugün her dersten kaç soru çözüldüğünü girmek için modal açar.\n" +
                "- 'Geçmişi Gör' (mor çerçeveli): Takvim açar. Bir güne tıklayınca o günün raporu: ✅ Tamamlanan dersler, ⏳ Tamamlanmayan oturumlar, 📝 Çözülen sorular. Gelecek günler için planlanan dersleri gösterir. Dinlenme günleri 'Dinlenme günü' olarak işaretlenir.\n" +
                "- 'Bugün' / 'Tüm Zamanlar' filtresi: bugünün veya tüm geçmişin istatistiklerini ve günlere göre gruplanmış ders dağılımı + soru çözümlerini gösterir.\n" +
                "- XP sistemi: tamamlanan oturum +10 XP, çözülen soru +1 XP, aktif gün +5 XP.\n\n" +

                "📝 DENEMELER SEKMESİ\n" +
                "- Üst kırmızı banner'da 'Deneme Sonucu Ekle' butonu.\n" +
                "- Deneme formu: deneme adı (sınava göre örnek placeholder), tür (TYT/AYT/LGS/KPSS/ALES/YDS/OABT/Okul Sınavı...), ders bazında doğru ve yanlış sayısı.\n" +
                "- Eklenen denemeler için: 'Net Özeti' (en yüksek/ortalama/son), 'Net Trend' grafiği (gerçek + kayan ortalama), 'Denge Radarı' (ders bazında güçlü/zayıf görsel), 'Koç Analizi' (AI yorum), 'Karşılaştırma' (2–3 deneme yan yana).\n" +
                "- Tür filtresi ile sadece belirli türdeki denemeleri listele.\n\n" +

                "👤 PROFİL SEKMESİ\n" +
                "Bölümler (her biri accordion, tıklayınca açılır):\n" +
                "- 'Notlarım': Hızlı notlar listesi (silmek için × → onay sorusu çıkar).\n" +
                "- 'Akademik Hedef': hedeflediğin üniversite/lise/iş + gereken net.\n" +
                "- 'Ders Profilim': güçlü/zorlandığı dersler. OkulSinavi seçilirse 'Kendi Dersini Ekle' alanı çıkar.\n" +
                "- 'Zaman ve Biyoritim': sabah/gece kuşu, hafta içi/sonu ders saatleri, okul/kurs durumu, en geç ders saati, off-day seçimleri. Bu kısım değiştirilince program yeniden hesaplanır.\n" +
                "- 'Sınav Tarihi ve Hedef': hedef sınav, alan, sınav tarihi (kalan gün otomatik).\n" +
                "- 'Ayarlar': karanlık mod toggle, çıkış yap.\n" +
                "Önemli: Sınav türü veya dersler değişirse bugünün tamamlanan ders kayıtları sıfırlanır; sadece zaman/biyoritim değişirse korunur.\n\n" +

                "⏱️ ÇALIŞMA EKRANI (Pomodoro)\n" +
                "- Görev başlatınca: süre sayacı + ilerleme dairesi.\n" +
                "- 'Mola' butonu 5 dk ara verir. Süre bitince ders otomatik tamamlanır.\n" +
                "- 'Ortam Sesleri & Çalışma Yayınları' kartı: yağmur, şömine, orman sesi veya 'Study With Me' YouTube yayınları.\n\n" +

                "🤖 BEN (KOÇ)\n" +
                "Sohbete senin sınavın, programın ve derslerin hakkında soru sorabilirsin. Strateji önerisi, motivasyon, plan tavsiyesi, hangi konuya öncelik vereceği gibi konularda yardım ederim. Üst kısımda 'Yeni sohbet' butonu var, en fazla 3 sohbet açılabilir. Sohbet başlığı düzenlenebilir, silinebilir.\n\n" +

                "═══════════════════════════════════════════\n" +
                "TIPİK SORULAR VE DOĞRU CEVAP YAKLAŞIMI:\n" +
                "═══════════════════════════════════════════\n" +
                "Soru: 'Bugün ne çalışmalıyım?' → SADECE 'Bugünkü program' içindeki dersleri kullanarak öneri yap. Bugünkü programdaki zayıf dersleri öne çıkar, ardından güçlü pekiştirme derslerini ekle. Programda olmayan bir dersi 'bugün başlayalım' deme. Kısa motivasyon ekle.\n" +
                "Soru: 'Matematiğe konu nasıl eklerim?' → 'Ana sayfada sağ alttaki + Görev butonuna bas → \"Çalışma Programım İçin Konuları Düzenle\" → Matematik dersinin üzerine tıkla → konu adını yaz → kaydet.'\n" +
                "Soru: 'Programa ek görev eklemek istiyorum.' → 'Ana sayfada sağ alttaki + Görev → \"Kendim Görev Ekle\" → ders, görev türü ve süre seç → Ekle. Görevin programın sonuna eklenir.'\n" +
                "Soru: 'Zayıf dersimi değiştirmek istiyorum.' → 'Profil sekmesinde \"Ders Profilim\"i aç → mevcut zorlandığın dersi kaldır, yenisini seç → \"Değişiklikleri Kaydet\". Program otomatik yenilenir.'\n" +
                "Soru: 'Bugün hastayım, dinlenmek istiyorum.' → 'Ana sayfada + Görev → \"Hastayım / Dinlenme Modu\" → onayla. Bugün için tüm görevler tamamlanmış sayılır, dinlenme sayacın 1 artar.'\n" +
                "Soru: 'Sınava ne kadar kaldı?' → Ana sayfa üst banner'daki sayıyı söyle ve motivasyon ekle.\n" +
                "Soru: 'Sırada ne var?' / 'Şimdi ne çalışmalıyım?' → Kalan (⬜) görevlerden öncelikli olanı (zayıf → güçlü sırası, saat varsa en yakın olan) öner. Tamamlanmış ✓ dersleri tekrar önerme.\n" +
                "Soru: 'Bugün ne kadar ilerledim?' / 'Durumum nedir?' → 'X/Y ders tamamlandı', tamamlananları kısa listele, kalanları söyle, motivasyon ekle.\n" +
                "Soru: 'Hepsini bitirdim!' → Tüm görevler ✓ ise tebrik et, dinlenme/tekrar önerisi sun. Kalan varsa nazikçe hatırlat.\n";

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

                // Koç artık otomatik aksiyon (intent JSON) üretmez — tüm işlemleri
                // kullanıcı arayüzden kendisi yapar, Koç sadece yol gösterir.
                // Modelin yanlışlıkla JSON ürettiği nadir durumlarda da düz metin sun.
                if (rawText.TrimStart().StartsWith("{") && rawText.TrimEnd().EndsWith("}"))
                {
                    // Olası "suggestion" alanını çıkar; yoksa generic mesaj
                    try
                    {
                        using var maybeJson = JsonDocument.Parse(rawText);
                        if (maybeJson.RootElement.TryGetProperty("suggestion", out var sugg))
                        {
                            return new ChatResponseDto { Message = sugg.GetString() ?? rawText };
                        }
                    }
                    catch { /* JSON değil, devam et */ }
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
