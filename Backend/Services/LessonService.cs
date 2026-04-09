using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    public class LessonService : ILessonService
    {
        private readonly AppDbContext _context;

        public LessonService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<LessonDto>> GetUserLessonsAsync(int userId)
        {
            return await _context.Lessons
                .Where(l => l.UserId == userId)
                .Select(l => new LessonDto
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    Name = l.Name,
                    ColorCode = l.ColorCode
                })
                .ToListAsync();
        }

        public async Task<LessonDto?> GetLessonByIdAsync(int lessonId, int userId)
        {
            var lesson = await _context.Lessons
                .FirstOrDefaultAsync(l => l.Id == lessonId && l.UserId == userId);

            if (lesson == null) return null;

            return new LessonDto
            {
                Id = lesson.Id,
                UserId = lesson.UserId,
                Name = lesson.Name,
                ColorCode = lesson.ColorCode
            };
        }

        public async Task<LessonDto> CreateLessonAsync(LessonCreateDto dto, int userId)
        {
            var lesson = new Lesson
            {
                UserId = userId,
                Name = dto.Name,
                ColorCode = dto.ColorCode
            };

            _context.Lessons.Add(lesson);
            await _context.SaveChangesAsync();

            return new LessonDto
            {
                Id = lesson.Id,
                UserId = lesson.UserId,
                Name = lesson.Name,
                ColorCode = lesson.ColorCode
            };
        }

        public async Task<LessonDto?> UpdateLessonAsync(int lessonId, LessonUpdateDto dto, int userId)
        {
            var lesson = await _context.Lessons
                .FirstOrDefaultAsync(l => l.Id == lessonId && l.UserId == userId);

            if (lesson == null) return null;

            lesson.Name = dto.Name;
            lesson.ColorCode = dto.ColorCode;

            await _context.SaveChangesAsync();

            return new LessonDto
            {
                Id = lesson.Id,
                UserId = lesson.UserId,
                Name = lesson.Name,
                ColorCode = lesson.ColorCode
            };
        }

        public async Task<bool> DeleteLessonAsync(int lessonId, int userId)
        {
            var lesson = await _context.Lessons
                .FirstOrDefaultAsync(l => l.Id == lessonId && l.UserId == userId);

            if (lesson == null) return false;

            _context.Lessons.Remove(lesson);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
