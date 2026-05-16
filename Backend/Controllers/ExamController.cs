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
    public class ExamController : ControllerBase
    {
        private readonly IExamService _examService;

        public ExamController(IExamService examService)
        {
            _examService = examService;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        [HttpPost]
        public async Task<IActionResult> AddExam([FromBody] CreateExamDto dto)
        {
            var userId = GetUserId();
            var result = await _examService.AddExamAsync(userId, dto);
            return Ok(result);
        }

        [HttpGet]
        public async Task<IActionResult> GetExams()
        {
            var userId = GetUserId();
            var exams = await _examService.GetExamResultsAsync(userId);
            return Ok(exams);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteExam(int id)
        {
            var userId = GetUserId();
            var result = await _examService.DeleteExamAsync(userId, id);
            if (!result) return NotFound();
            return NoContent();
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateExam(int id, [FromBody] CreateExamDto dto)
        {
            var userId = GetUserId();
            var result = await _examService.UpdateExamAsync(userId, id, dto);
            if (result == null) return NotFound();
            return Ok(result);
        }

        [HttpGet("bytype/{type}")]
        public async Task<IActionResult> GetExamsByType(string type)
        {
            var userId = GetUserId();
            var exams = await _examService.GetExamsByTypeAsync(userId, type);
            return Ok(exams);
        }

        [HttpGet("analysis")]
        public async Task<IActionResult> GetExamAnalysis()
        {
            var userId = GetUserId();
            var analysis = await _examService.GetExamAnalysisAsync(userId);
            return Ok(analysis);
        }

        [HttpGet("recommendation")]
        public async Task<IActionResult> GetRecommendation()
        {
            var userId = GetUserId();
            var recommendation = await _examService.GetAiRecommendationAsync(userId);
            return Ok(new { recommendation });
        }
    }
}
