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
            return CreatedAtAction(nameof(GetExams), new { }, result);
        }

        [HttpGet]
        public async Task<IActionResult> GetExams()
        {
            var userId = GetUserId();
            var exams = await _examService.GetExamResultsAsync(userId);
            return Ok(exams);
        }

        [HttpGet("analysis")]
        public async Task<IActionResult> GetExamAnalysis()
        {
            var userId = GetUserId();
            var analysis = await _examService.GetExamAnalysisAsync(userId);
            return Ok(analysis);
        }
    }
}
