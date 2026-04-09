using Backend.DTOs;

namespace Backend.Services
{
    public interface ILessonService
    {
        Task<IEnumerable<LessonDto>> GetUserLessonsAsync(int userId);
        Task<LessonDto?> GetLessonByIdAsync(int lessonId, int userId);
        Task<LessonDto> CreateLessonAsync(LessonCreateDto dto, int userId);
        Task<LessonDto?> UpdateLessonAsync(int lessonId, LessonUpdateDto dto, int userId);
        Task<bool> DeleteLessonAsync(int lessonId, int userId);
    }
}
