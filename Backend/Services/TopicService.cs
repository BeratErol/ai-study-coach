using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    public class TopicService : ITopicService
    {
        private readonly AppDbContext _context;

        public TopicService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<TopicDto>> GetTopicsByLessonIdAsync(int lessonId, int userId)
        {
            // First pass authorization check
            var lessonExists = await _context.Lessons.AnyAsync(l => l.Id == lessonId && l.UserId == userId);
            if (!lessonExists)
            {
                return new List<TopicDto>(); // Or could throw UnauthorizedAccessException
            }

            return await _context.Topics
                .Where(t => t.LessonId == lessonId)
                .Select(t => new TopicDto
                {
                    Id = t.Id,
                    LessonId = t.LessonId,
                    Name = t.Name,
                    IsCompleted = t.IsCompleted
                })
                .ToListAsync();
        }

        public async Task<TopicDto?> CreateTopicAsync(TopicCreateDto dto, int userId)
        {
            // Ensure lesson belongs to user
            var lessonExists = await _context.Lessons.AnyAsync(l => l.Id == dto.LessonId && l.UserId == userId);
            if (!lessonExists)
            {
                return null;
            }

            var topic = new Topic
            {
                LessonId = dto.LessonId,
                Name = dto.Name,
                IsCompleted = false
            };

            _context.Topics.Add(topic);
            await _context.SaveChangesAsync();

            return new TopicDto
            {
                Id = topic.Id,
                LessonId = topic.LessonId,
                Name = topic.Name,
                IsCompleted = topic.IsCompleted
            };
        }

        public async Task<TopicDto?> UpdateTopicAsync(int topicId, TopicUpdateDto dto, int userId)
        {
            // Ensure the topic belongs to a lesson that belongs to the user
            var topic = await _context.Topics
                .Include(t => t.Lesson)
                .FirstOrDefaultAsync(t => t.Id == topicId);

            if (topic == null || topic.Lesson.UserId != userId)
            {
                return null;
            }

            if (dto.Name != null)
            {
                topic.Name = dto.Name;
            }
            if (dto.IsCompleted.HasValue)
            {
                topic.IsCompleted = dto.IsCompleted.Value;
            }

            await _context.SaveChangesAsync();

            return new TopicDto
            {
                Id = topic.Id,
                LessonId = topic.LessonId,
                Name = topic.Name,
                IsCompleted = topic.IsCompleted
            };
        }

        public async Task<bool> DeleteTopicAsync(int topicId, int userId)
        {
            var topic = await _context.Topics
                .Include(t => t.Lesson)
                .FirstOrDefaultAsync(t => t.Id == topicId);

            if (topic == null || topic.Lesson.UserId != userId)
            {
                return false;
            }

            _context.Topics.Remove(topic);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
