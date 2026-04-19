using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class StudySessionController : ControllerBase
    {
        private readonly IStudySessionService _sessionService;

        public StudySessionController(IStudySessionService sessionService)
        {
            _sessionService = sessionService;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        [HttpPost]
        public async Task<IActionResult> CreateSession([FromBody] CreateStudySessionDto dto)
        {
            try
            {
                var userId = GetUserId();
                var result = await _sessionService.CreateSessionAsync(userId, dto);
                return CreatedAtAction(nameof(GetSessions), new { }, result);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetSessions([FromQuery] int? topicId = null, [FromQuery] DateTime? date = null)
        {
            var userId = GetUserId();
            var sessions = await _sessionService.GetSessionsAsync(userId, topicId, date);
            return Ok(sessions);
        }

        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary()
        {
            var userId = GetUserId();
            var summary = await _sessionService.GetSummaryAsync(userId);
            return Ok(summary);
        }

        [HttpDelete("clear")]
        public async Task<IActionResult> ClearAllSessions()
        {
            var userId = GetUserId();
            await _sessionService.DeleteAllSessionsAsync(userId);
            return Ok(new { message = "Çalışma geçmişiniz başarıyla temizlendi." });
        }
    }
}
