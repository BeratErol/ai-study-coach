namespace Backend.Models
{
    public class Topic
    {
        public int Id { get; set; }
        public int LessonId { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsCompleted { get; set; } = false;

        // Navigation property
        public Lesson Lesson { get; set; } = null!;
    }
}
