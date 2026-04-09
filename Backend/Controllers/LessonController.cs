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
    public class LessonController : ControllerBase
    {
        private readonly ILessonService _lessonService;

        public LessonController(ILessonService lessonService)
        {
            _lessonService = lessonService;
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

        [HttpGet]
        public async Task<IActionResult> GetLessons()
        {
            var userId = GetUserId();
            var lessons = await _lessonService.GetUserLessonsAsync(userId);
            return Ok(lessons);
        }
        
        [HttpGet("{id}")]
        public async Task<IActionResult> GetLesson(int id)
        {
            var userId = GetUserId();
            var lesson = await _lessonService.GetLessonByIdAsync(id, userId);
            if (lesson == null) return NotFound("Ders bulunamadı veya yetkiniz yok.");
            return Ok(lesson);
        }

        [HttpPost]
        public async Task<IActionResult> CreateLesson([FromBody] LessonCreateDto request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var userId = GetUserId();
            var lesson = await _lessonService.CreateLessonAsync(request, userId);
            return CreatedAtAction(nameof(GetLesson), new { id = lesson.Id }, lesson);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateLesson(int id, [FromBody] LessonUpdateDto request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var userId = GetUserId();
            var lesson = await _lessonService.UpdateLessonAsync(id, request, userId);
            
            if (lesson == null) return NotFound("Ders bulunamadı veya yetkiniz yok.");
            
            return Ok(lesson);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLesson(int id)
        {
            var userId = GetUserId();
            var success = await _lessonService.DeleteLessonAsync(id, userId);
            
            if (!success) return NotFound("Ders bulunamadı veya yetkiniz yok.");
            
            return NoContent();
        }
    }
}
