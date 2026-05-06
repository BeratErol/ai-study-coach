using System;
using Backend.Models;

namespace Backend.DTOs
{
    public class CreateStudySessionDto
    {
        public int TopicId { get; set; }
        public int DurationMinutes { get; set; }
        public string Type { get; set; } = "pomodoro";
        public DateTime? Date { get; set; }
    }

    public class StudySessionDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int TopicId { get; set; }
        public int DurationMinutes { get; set; }
        public string Type { get; set; } = string.Empty;
        public DateTime Date { get; set; }
    }

    public class StudySessionSummaryDto
    {
        public int TotalDurationMinutes { get; set; }
    }

    public class WeeklyStudySummaryDto
    {
        public int TotalMinutes { get; set; }
        public int TotalSessions { get; set; }
        public int PomodoroCount { get; set; }
    }

    public class DailyActivityDto
    {
        public string Date { get; set; } = string.Empty;
        public int TotalMinutes { get; set; }
        public int SessionCount { get; set; }
    }
}
