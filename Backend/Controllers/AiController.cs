using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Services;
using System;
using System.Linq;
using System.Security.Claims;

namespace Backend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : ControllerBase
    {
        private readonly IAiService _aiService;
        private readonly IExamService _examService;
        private readonly ILessonService _lessonService;
        private readonly IStudySessionService _sessionService;

        public AiController(
            IAiService aiService,
            IExamService examService,
            ILessonService lessonService,
            IStudySessionService sessionService)
        {
            _aiService      = aiService;
            _examService    = examService;
            _lessonService  = lessonService;
            _sessionService = sessionService;
        }

        private int GetUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(claim, out int id)) return id;
            throw new UnauthorizedAccessException("Geçersiz kullanıcı kimliği.");
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] ChatRequestDto request)
        {
            if (request.Messages == null || !request.Messages.Any())
                return BadRequest(new { message = "Mesaj listesi boş olamaz." });

            try
            {
                var result = await _aiService.ChatAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Chatbot yanıt veremedi.", detail = ex.Message });
            }
        }

        [HttpPost("plan")]
        public async Task<IActionResult> GeneratePlan([FromBody] AiPlanRequestDto request)
        {
            if (string.IsNullOrWhiteSpace(request.Prompt))
                return BadRequest(new { message = "Lütfen hedefinizi belirten bir yazı girin." });

            try
            {
                var plan = await _aiService.GenerateStudyPlanAsync(request);
                return Ok(plan);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "AI Plan oluşturulurken hata meydana geldi.", details = ex.Message });
            }
        }

        [HttpPost("optimize")]
        public async Task<IActionResult> OptimizePlan()
        {
            try
            {
                var userId = GetUserId();
                var analysis = await _examService.GetExamAnalysisAsync(userId);
                var optimizedPlans = await _aiService.OptimizePlanAsync(userId, analysis);
                return Ok(optimizedPlans);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Plan optimize edilirken hata oluştu.", details = ex.Message });
            }
        }

        [HttpGet("dashboard-coach")]
        public async Task<IActionResult> GetDashboardCoach()
        {
            try
            {
                var userId   = GetUserId();
                var userName = User.FindFirstValue(ClaimTypes.Name) ?? "Öğrenci";

                var lessons = await _lessonService.GetUserLessonsAsync(userId);
                var lessonSummaries = lessons.Select(l => new LessonSummaryDto
                {
                    Name            = l.Name,
                    TotalTopics     = l.Topics?.Count ?? 0,
                    CompletedTopics = l.Topics?.Count(t => t.IsCompleted) ?? 0
                }).ToList();

                var exams = await _examService.GetExamResultsAsync(userId);
                var examSummaries = exams.Take(5).Select(e => new ExamSummaryDto
                {
                    Title    = e.Title,
                    Type     = e.Type,
                    NetScore = e.TotalNet,
                    Date     = e.Date
                }).ToList();

                var sessions  = await _sessionService.GetUserSessionsAsync(userId);
                var weekStart = DateTime.UtcNow.AddDays(-(int)DateTime.UtcNow.DayOfWeek);
                var weeklyMinutes = sessions
                    .Where(s => s.Date >= weekStart)
                    .Sum(s => s.DurationMinutes);

                var coachRequest = new DashboardCoachRequestDto
                {
                    UserName                  = userName,
                    Lessons                   = lessonSummaries,
                    RecentExams               = examSummaries,
                    TotalStudyMinutesThisWeek = weeklyMinutes
                };

                var result = await _aiService.GenerateDashboardCoachAsync(coachRequest);
                return Ok(result);
            }
            catch (Exception)
            {
                return Ok(new DashboardCoachResponseDto
                {
                    Greeting = "Merhaba! 👋",
                    TodayFocus = "Bugün planına sadık kal.",
                    WeakAreaWarning = "",
                    MotivationNote = "Her gün küçük adımlar büyük başarılar getirir! 🚀",
                    ActionItems = new List<string>
                    {
                        "Planındaki ilk dersi başlat",
                        "25 dk odaklanarak çalış",
                    }
                });
            }
        }
    }
}
