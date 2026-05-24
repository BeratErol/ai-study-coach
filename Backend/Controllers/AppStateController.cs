using System.Security.Claims;
using System.Text.Json;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    /// <summary>
    /// Cihazdan bağımsız generic key-value senkronu.
    /// Notlar, akademik hedef, manuel görevler, tamamlanan görevler vb.
    /// mobil ve web arasında bu endpoint üzerinden senkron olur.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AppStateController : ControllerBase
    {
        private readonly AppDbContext _db;

        public AppStateController(AppDbContext db)
        {
            _db = db;
        }

        private int? GetUserId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? User.FindFirst("sub")?.Value;
            return int.TryParse(claim, out var id) ? id : null;
        }

        // GET /api/AppState → { "key": <json değeri>, ... }
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var rows = await _db.AppStates
                .Where(s => s.UserId == userId.Value)
                .ToListAsync();

            var result = new Dictionary<string, JsonElement>();
            foreach (var row in rows)
            {
                try
                {
                    result[row.Key] = JsonDocument.Parse(row.ValueJson).RootElement.Clone();
                }
                catch
                {
                    // Bozuk kayıt — atla
                }
            }
            return Ok(result);
        }

        // GET /api/AppState/{key} → tek anahtarın json değeri
        [HttpGet("{key}")]
        public async Task<IActionResult> GetOne(string key)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var row = await _db.AppStates
                .FirstOrDefaultAsync(s => s.UserId == userId.Value && s.Key == key);
            if (row == null) return NotFound();

            return Content(row.ValueJson, "application/json");
        }

        // PUT /api/AppState/{key} → upsert (body: ham JSON)
        [HttpPut("{key}")]
        public async Task<IActionResult> Upsert(string key, [FromBody] JsonElement body)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var valueJson = body.GetRawText();
            var row = await _db.AppStates
                .FirstOrDefaultAsync(s => s.UserId == userId.Value && s.Key == key);

            if (row == null)
            {
                _db.AppStates.Add(new AppState
                {
                    UserId = userId.Value,
                    Key = key,
                    ValueJson = valueJson,
                    UpdatedAt = DateTime.UtcNow,
                });
            }
            else
            {
                row.ValueJson = valueJson;
                row.UpdatedAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return Ok(new { success = true });
        }

        // DELETE /api/AppState/{key}
        [HttpDelete("{key}")]
        public async Task<IActionResult> Delete(string key)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var row = await _db.AppStates
                .FirstOrDefaultAsync(s => s.UserId == userId.Value && s.Key == key);
            if (row != null)
            {
                _db.AppStates.Remove(row);
                await _db.SaveChangesAsync();
            }
            return Ok(new { success = true });
        }
    }
}
