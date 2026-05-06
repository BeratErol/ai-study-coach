using System.Security.Claims;
using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserProfileController : ControllerBase
    {
        private readonly IUserProfileService _service;

        public UserProfileController(IUserProfileService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var profile = await _service.GetProfileAsync(userId.Value);
            if (profile == null) return NotFound(new { error = "Profil bulunamadı." });
            return Ok(profile);
        }

        [HttpPost]
        public async Task<IActionResult> Upsert([FromBody] UserProfileRequestDto dto)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var result = await _service.UpsertProfileAsync(userId.Value, dto);
            return Ok(result);
        }

        private int? GetUserId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? User.FindFirst("sub")?.Value;
            return int.TryParse(claim, out var id) ? id : null;
        }
    }
}
