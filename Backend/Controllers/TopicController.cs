using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Backend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class TopicController : ControllerBase
    {
        private readonly ITopicService _topicService;

        public TopicController(ITopicService topicService)
        {
            _topicService = topicService;
        }

        private int GetUserId()
        {
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(userIdClaim, out int userId))
            {
                return userId;
            }
            throw new UnauthorizedAccessException("Geçersiz kullanıcı kimliği.");
        }

        [HttpGet("lesson/{lessonId}")]
        public async Task<IActionResult> GetTopicsByLesson(int lessonId)
        {
            var userId = GetUserId();
            var topics = await _topicService.GetTopicsByLessonIdAsync(lessonId, userId);
            return Ok(topics);
        }

        [HttpPost]
        public async Task<IActionResult> CreateTopic([FromBody] TopicCreateDto request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var userId = GetUserId();
            var topic = await _topicService.CreateTopicAsync(request, userId);

            if (topic == null) return BadRequest("Ders bulunamadı veya bu derse konu ekleme yetkiniz yok.");

            return Ok(topic);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTopic(int id, [FromBody] TopicUpdateDto request)
        {
            var userId = GetUserId();
            var topic = await _topicService.UpdateTopicAsync(id, request, userId);

            if (topic == null) return NotFound("Konu bulunamadı veya yetkiniz yok.");

            return Ok(topic);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTopic(int id)
        {
            var userId = GetUserId();
            var success = await _topicService.DeleteTopicAsync(id, userId);

            if (!success) return NotFound("Konu bulunamadı veya yetkiniz yok.");

            return NoContent();
        }
    }
}
