using System.Security.Claims;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class GelisimimController : ControllerBase
    {
        private readonly AppDbContext _db;

        public GelisimimController(AppDbContext db)
        {
            _db = db;
        }

        private int GetUserId() =>
            int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // GET /api/Gelisimim/stats?filter=today|all
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats([FromQuery] string filter = "all")
        {
            var userId = GetUserId();
            var today = DateTime.UtcNow.Date;
            var todayStr = today.ToString("yyyy-MM-dd");

            IQueryable<StudySession> sessionQ = _db.StudySessions.Where(s => s.UserId == userId);
            IQueryable<QuestionLog> questionQ = _db.QuestionLogs.Where(q => q.UserId == userId);

            if (filter == "today")
            {
                sessionQ = sessionQ.Where(s => s.Date.Date == today);
                questionQ = questionQ.Where(q => q.Date == todayStr);
            }

            var completedTasks = await sessionQ.CountAsync();
            var totalMinutes = await sessionQ.SumAsync(s => (int?)s.DurationMinutes) ?? 0;
            var totalQuestions = await questionQ.SumAsync(q => (int?)q.Count) ?? 0;

            // Dinlenme sayacı backend'de otomatik hesaplanmaz.
            // Kullanıcının client tarafında "bugün dinleneceğim" diye açıkça
            // işaretlediği günler (rest_days AppState) sayılır — client merge eder.
            int restDays = 0;

            return Ok(new GelisimimStatsDto
            {
                CompletedTasks = completedTasks,
                TotalMinutes = totalMinutes,
                TotalQuestions = totalQuestions,
                RestDays = restDays,
            });
        }

        // GET /api/Gelisimim/question-subjects
        [HttpGet("question-subjects")]
        public async Task<IActionResult> GetQuestionSubjects()
        {
            var userId = GetUserId();
            var profile = await _db.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
            var targetExam = profile?.TargetExam ?? "TYT";

            // AYT/YDT öğrencileri TYT sınavına da girerler, her iki sınavın dersleri gösterilir
            var subjects = (targetExam == "AYT" || targetExam == "YDT")
                ? GetSubjectsForExam("TYT").Concat(GetSubjectsForExam(targetExam)).ToList()
                : GetSubjectsForExam(targetExam);
            var todayStr = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");

            var todayLogs = await _db.QuestionLogs
                .Where(q => q.UserId == userId && q.Date == todayStr)
                .ToListAsync();

            var result = subjects.Select(s => new SubjectEntryDto
            {
                Key = s.Key,
                Name = s.Name,
                Icon = s.Icon,
                TodayCount = todayLogs.FirstOrDefault(l => l.SubjectKey == s.Key)?.Count ?? 0,
            }).ToList();

            return Ok(result);
        }

        // POST /api/Gelisimim/save-questions
        [HttpPost("save-questions")]
        public async Task<IActionResult> SaveQuestions([FromBody] SaveQuestionsRequestDto dto)
        {
            var userId = GetUserId();
            var todayStr = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");

            foreach (var entry in dto.Entries.Where(e => e.Count > 0))
            {
                var existing = await _db.QuestionLogs.FirstOrDefaultAsync(
                    q => q.UserId == userId &&
                         q.Date == todayStr &&
                         q.SubjectKey == entry.SubjectKey);

                if (existing != null)
                {
                    existing.Count = entry.Count;
                }
                else
                {
                    _db.QuestionLogs.Add(new QuestionLog
                    {
                        UserId = userId,
                        Date = todayStr,
                        SubjectKey = entry.SubjectKey,
                        SubjectName = entry.SubjectName,
                        Count = entry.Count,
                    });
                }
            }

            await _db.SaveChangesAsync();

            var totalToday = await _db.QuestionLogs
                .Where(q => q.UserId == userId && q.Date == todayStr)
                .SumAsync(q => q.Count);

            return Ok(new SaveQuestionsResponseDto { Success = true, TotalToday = totalToday });
        }

        // GET /api/Gelisimim/calendar?year=YYYY&month=MM
        [HttpGet("calendar")]
        public async Task<IActionResult> GetCalendar([FromQuery] int year, [FromQuery] int month)
        {
            var userId = GetUserId();
            // Npgsql timestamptz sütunlarıyla uyumluluk için UTC Kind zorunlu
            var startDate = DateTime.SpecifyKind(new DateTime(year, month, 1), DateTimeKind.Utc);
            var endDate = startDate.AddMonths(1);
            // "yyyy-MM" prefix — ISO dates sort lexicographically so StartsWith works for month filter
            var monthPrefix = $"{year}-{month:D2}";

            var sessionDays = await _db.StudySessions
                .Where(s => s.UserId == userId && s.Date >= startDate && s.Date < endDate)
                .Select(s => s.Date.Date.ToString("yyyy-MM-dd"))
                .Distinct().ToListAsync();

            var questionDays = await _db.QuestionLogs
                .Where(q => q.UserId == userId && q.Date.StartsWith(monthPrefix))
                .Select(q => q.Date)
                .Distinct().ToListAsync();

            var allActive = new HashSet<string>(sessionDays);
            foreach (var d in questionDays) allActive.Add(d);

            return Ok(new CalendarResponseDto
            {
                ActiveDays = allActive.OrderBy(d => d).ToList()
            });
        }

        // GET /api/Gelisimim/daily-report?date=YYYY-MM-DD
        [HttpGet("daily-report")]
        public async Task<IActionResult> GetDailyReport([FromQuery] string date)
        {
            var userId = GetUserId();

            if (!DateTime.TryParse(date, out var parsedDate))
                return BadRequest("Geçersiz tarih formatı. Beklenen: yyyy-MM-dd");

            // Npgsql timestamptz sütunlarıyla uyumluluk için UTC Kind zorunlu
            var dayStart = DateTime.SpecifyKind(parsedDate.Date, DateTimeKind.Utc);
            var dayEnd = DateTime.SpecifyKind(dayStart.AddDays(1), DateTimeKind.Utc);

            var questions = await _db.QuestionLogs
                .Where(q => q.UserId == userId && q.Date == date)
                .Select(q => new DailyQuestionDto { SubjectName = q.SubjectName, Count = q.Count })
                .ToListAsync();

            // Sadece ihtiyaç duyulan alan seçilerek entity materialization sorunları önlenir
            var sessionMinutes = await _db.StudySessions
                .Where(s => s.UserId == userId && s.Date >= dayStart && s.Date < dayEnd)
                .Select(s => s.DurationMinutes)
                .ToListAsync();

            var tasks = new DailyTasksDto
            {
                Completed = sessionMinutes.Count,
                Missed = 0,
                TotalMinutes = sessionMinutes.Sum(),
            };

            return Ok(new DailyReportDto
            {
                Date = date,
                Questions = questions,
                Tasks = tasks,
                IsEmpty = !questions.Any() && sessionMinutes.Count == 0,
            });
        }

        // GET /api/Gelisimim/xp-info
        [HttpGet("xp-info")]
        public async Task<IActionResult> GetXpInfo()
        {
            var userId = GetUserId();

            var totalQuestions = await _db.QuestionLogs
                .Where(q => q.UserId == userId)
                .SumAsync(q => (int?)q.Count) ?? 0;

            var totalSessions = await _db.StudySessions
                .Where(s => s.UserId == userId)
                .CountAsync();

            var sessionDays = await _db.StudySessions
                .Where(s => s.UserId == userId)
                .Select(s => s.Date.Date.ToString("yyyy-MM-dd"))
                .Distinct().ToListAsync();

            var questionDays = await _db.QuestionLogs
                .Where(q => q.UserId == userId)
                .Select(q => q.Date)
                .Distinct().ToListAsync();

            var activeDays = new HashSet<string>(sessionDays);
            foreach (var d in questionDays) activeDays.Add(d);

            var totalXP = totalQuestions + totalSessions * 10 + activeDays.Count * 5;

            // Streak: consecutive days with activity ending today
            var today = DateTime.UtcNow.Date;
            var streakDays = 0;
            var checkDate = today;
            while (activeDays.Contains(checkDate.ToString("yyyy-MM-dd")))
            {
                streakDays++;
                checkDate = checkDate.AddDays(-1);
            }

            // Level
            string levelName;
            string levelEmoji;
            int currentLevelXP;
            int nextLevelXP;
            if (totalXP <= 2000)
            { levelName = "Çırak Öğrenci";   levelEmoji = "🌱"; currentLevelXP = 0;     nextLevelXP = 2000; }
            else if (totalXP <= 5000)
            { levelName = "Acemi Öğrenci";   levelEmoji = "📖"; currentLevelXP = 2001;  nextLevelXP = 5000; }
            else if (totalXP <= 10000)
            { levelName = "Gelişen Öğrenci"; levelEmoji = "📚"; currentLevelXP = 5001;  nextLevelXP = 10000; }
            else
            { levelName = "Uzman Öğrenci";   levelEmoji = "🎓"; currentLevelXP = 10001; nextLevelXP = 20000; }

            return Ok(new XpInfoDto
            {
                TotalXP = totalXP,
                CurrentLevelXP = currentLevelXP,
                NextLevelXP = nextLevelXP,
                LevelName = levelName,
                LevelEmoji = levelEmoji,
                StreakDays = streakDays,
                TotalQuestions = totalQuestions,
            });
        }

        // GET /api/Gelisimim/lesson-distribution?filter=today|all
        [HttpGet("lesson-distribution")]
        public async Task<IActionResult> GetLessonDistribution([FromQuery] string filter = "all")
        {
            var userId = GetUserId();
            var todayStr = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");

            IQueryable<QuestionLog> query = _db.QuestionLogs.Where(q => q.UserId == userId);
            if (filter == "today")
                query = query.Where(q => q.Date == todayStr);

            var distribution = await query
                .GroupBy(q => q.SubjectName)
                .Select(g => new LessonDistributionDto
                {
                    LessonName = g.Key,
                    TotalQuestions = g.Sum(q => q.Count),
                })
                .OrderByDescending(d => d.TotalQuestions)
                .ToListAsync();

            return Ok(distribution);
        }

        private static List<(string Key, string Name, string Icon)> GetSubjectsForExam(string targetExam)
        {
            return targetExam switch
            {
                "AYT" => new List<(string, string, string)>
                {
                    ("ayt_matematik",  "AYT Matematik",              "📐"),
                    ("ayt_fizik",      "Fizik",                      "⚡"),
                    ("ayt_kimya",      "Kimya",                      "🧪"),
                    ("ayt_biyoloji",   "Biyoloji",                   "🌿"),
                    ("ayt_edebiyat",   "Türk Dili ve Edebiyatı",     "📚"),
                    ("ayt_tarih1",     "Tarih-1",                    "🏛️"),
                    ("ayt_tarih2",     "Tarih-2",                    "🏛️"),
                    ("ayt_cografya",   "Coğrafya",                   "🗺️"),
                    ("ayt_felsefe",    "Felsefe",                    "💭"),
                },
                "YDT" => new List<(string, string, string)>
                {
                    ("ydt_kelime",     "Kelime Bilgisi",                      "📖"),
                    ("ydt_dilbilgisi", "Dilbilgisi",                          "📝"),
                    ("ydt_cloze",      "Cloze Test",                          "🔤"),
                    ("ydt_cumle",      "Cümle Tamamlama",                     "✏️"),
                    ("ydt_ceviri",     "Çeviri",                              "🌐"),
                    ("ydt_okuma",      "Okuma Parçaları",                     "📄"),
                    ("ydt_diyalog",    "Diyalog Tamamlama",                   "💬"),
                    ("ydt_anlam",      "Anlamca En Yakın Cümle",              "🔍"),
                    ("ydt_paragraf",   "Paragraf Tamamlama",                  "📃"),
                    ("ydt_butunluk",   "Anlam Bütünlüğünü Bozan Cümle",      "❌"),
                },
                "LGS" => new List<(string, string, string)>
                {
                    ("lgs_turkce",     "Türkçe",              "📚"),
                    ("lgs_matematik",  "Matematik",           "📐"),
                    ("lgs_fen",        "Fen Bilimleri",       "🔬"),
                    ("lgs_inkilap",    "T.C. İnkılap Tarihi", "🏛️"),
                    ("lgs_din",        "Din Kültürü",         "📖"),
                    ("lgs_ingilizce",  "İngilizce",           "🌐"),
                },
                "KPSS" => new List<(string, string, string)>
                {
                    ("kpss_turkce",      "Türkçe",           "📚"),
                    ("kpss_matematik",   "Matematik",        "📐"),
                    ("kpss_tarih",       "Tarih",            "🏛️"),
                    ("kpss_cografya",    "Coğrafya",         "🗺️"),
                    ("kpss_vatandaslik", "Vatandaşlık",      "⚖️"),
                    ("kpss_guncel",      "Güncel Olaylar",   "📰"),
                    ("kpss_egitim",      "Eğitim Bilimleri", "🎓"),
                },
                // TYT (default)
                _ => new List<(string, string, string)>
                {
                    ("tyt_turkce",    "Türkçe",       "📚"),
                    ("tyt_matematik", "Matematik",    "📐"),
                    ("tyt_fizik",     "Fizik",        "⚡"),
                    ("tyt_kimya",     "Kimya",        "🧪"),
                    ("tyt_biyoloji",  "Biyoloji",     "🌿"),
                    ("tyt_tarih",     "Tarih",        "🏛️"),
                    ("tyt_cografya",  "Coğrafya",     "🗺️"),
                    ("tyt_felsefe",   "Felsefe",      "💭"),
                    ("tyt_din",       "Din Kültürü",  "📖"),
                },
            };
        }
    }
}
