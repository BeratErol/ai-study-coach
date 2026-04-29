using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Services;
using System;

namespace Backend.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : ControllerBase
    {
        private readonly IAiService _aiService;

        public AiController(IAiService aiService)
        {
            _aiService = aiService;
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
    }
}
