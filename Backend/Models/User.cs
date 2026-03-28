using System;
using System.Collections.Generic;

namespace Backend.Models
{
    public class User
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string? TargetExam { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ICollection<Lesson> Lessons { get; set; } = new List<Lesson>();
        public ICollection<StudySession> StudySessions { get; set; } = new List<StudySession>();
        public ICollection<ExamResult> ExamResults { get; set; } = new List<ExamResult>();
    }
}
