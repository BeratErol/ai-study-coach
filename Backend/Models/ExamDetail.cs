using System;

namespace Backend.Models
{
    public class ExamDetail
    {
        public int Id { get; set; }
        public int ExamId { get; set; }
        public string LessonName { get; set; } = string.Empty;
        public int Correct { get; set; }
        public int Incorrect { get; set; }
        public decimal Net { get; set; }

        // Navigation property
        public Exam Exam { get; set; } = null!;
    }
}
