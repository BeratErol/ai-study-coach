namespace Backend.DTOs
{
    public class TopicDto
    {
        public int Id { get; set; }
        public int LessonId { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsCompleted { get; set; }
    }
}
