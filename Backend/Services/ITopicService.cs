using Backend.DTOs;

namespace Backend.Services
{
    public interface ITopicService
    {
        Task<IEnumerable<TopicDto>> GetTopicsByLessonIdAsync(int lessonId, int userId);
        Task<TopicDto?> CreateTopicAsync(TopicCreateDto dto, int userId);
        Task<TopicDto?> UpdateTopicAsync(int topicId, TopicUpdateDto dto, int userId);
        Task<bool> DeleteTopicAsync(int topicId, int userId);
    }
}
