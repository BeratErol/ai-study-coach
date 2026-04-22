using System;
using System.Collections.Generic;

namespace Backend.Models
{
    public class Exam
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime Date { get; set; } = DateTime.UtcNow;
        public string Type { get; set; } = string.Empty; // TYT, AYT, BRANS

        // Navigation properties
        public User User { get; set; } = null!;
        public ICollection<ExamDetail> ExamDetails { get; set; } = new List<ExamDetail>();
    }
}
