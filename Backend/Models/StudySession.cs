using System;

namespace Backend.Models
{
    public class StudySession
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int TopicId { get; set; }
        public int DurationMinutes { get; set; }
        public string Type { get; set; } = "pomodoro";
        public DateTime Date { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public User User { get; set; } = null!;
        public Topic Topic { get; set; } = null!;
    }
}
