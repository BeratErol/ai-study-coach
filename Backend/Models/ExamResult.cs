using System;

namespace Backend.Models
{
    public class ExamResult
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string ExamName { get; set; } = string.Empty;
        public decimal NetScore { get; set; }
        public string? DetailsJson { get; set; } // Can be mapped to JSONB in PostgreSQL
        public DateTime Date { get; set; } = DateTime.UtcNow;

        // Navigation property
        public User User { get; set; } = null!;
    }
}
