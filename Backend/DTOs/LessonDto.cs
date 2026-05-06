namespace Backend.DTOs
{
    public class LessonDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ColorCode { get; set; } = string.Empty;
        public DateTime? PlannedDate { get; set; }
        public List<TopicDto> Topics { get; set; } = new();
    }
}
