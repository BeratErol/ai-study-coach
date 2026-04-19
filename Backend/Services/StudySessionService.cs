using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    public class StudySessionService : IStudySessionService
    {
        private readonly AppDbContext _context;

        public StudySessionService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<StudySessionDto> CreateSessionAsync(int userId, CreateStudySessionDto dto)
        {
            // Optional: verify topic belongs to user's lessons
            var topicExists = await _context.Topics
                .Include(t => t.Lesson)
                .AnyAsync(t => t.Id == dto.TopicId && t.Lesson.UserId == userId);

            if (!topicExists)
            {
                throw new ArgumentException("Topic not found or access denied.");
            }

            var session = new StudySession
            {
                UserId = userId,
                TopicId = dto.TopicId,
                DurationMinutes = dto.DurationMinutes,
                Type = dto.Type,
                Date = dto.Date ?? DateTime.UtcNow
            };

            _context.StudySessions.Add(session);
            await _context.SaveChangesAsync();

            return new StudySessionDto
            {
                Id = session.Id,
                UserId = session.UserId,
                TopicId = session.TopicId,
                DurationMinutes = session.DurationMinutes,
                Type = session.Type,
                Date = session.Date
            };
        }

        public async Task<IEnumerable<StudySessionDto>> GetSessionsAsync(int userId, int? topicId = null, DateTime? date = null)
        {
            var query = _context.StudySessions.Where(s => s.UserId == userId).AsQueryable();

            if (topicId.HasValue)
            {
                query = query.Where(s => s.TopicId == topicId.Value);
            }

            if (date.HasValue)
            {
                query = query.Where(s => s.Date.Date == date.Value.Date);
            }

            var sessions = await query.ToListAsync();

            return sessions.Select(s => new StudySessionDto
            {
                Id = s.Id,
                UserId = s.UserId,
                TopicId = s.TopicId,
                DurationMinutes = s.DurationMinutes,
                Type = s.Type,
                Date = s.Date
            });
        }

        public async Task<StudySessionSummaryDto> GetSummaryAsync(int userId)
        {
            var totalDuration = await _context.StudySessions
                .Where(s => s.UserId == userId)
                .SumAsync(s => s.DurationMinutes);

            return new StudySessionSummaryDto
            {
                TotalDurationMinutes = totalDuration
            };
        }

        public async Task DeleteAllSessionsAsync(int userId)
        {
            var sessions = await _context.StudySessions.Where(s => s.UserId == userId).ToListAsync();
            if (sessions.Any())
            {
                _context.StudySessions.RemoveRange(sessions);
                await _context.SaveChangesAsync();
            }
        }
    }
}
