namespace Backend.Models
{
    public class UserProfile
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Gender { get; set; } = string.Empty;
        public string EducationLevel { get; set; } = string.Empty;
        public string TargetExam { get; set; } = string.Empty;
        public DateTime? ExamDate { get; set; }
        public string StudyType { get; set; } = string.Empty;
        public bool HasWeekdaySchool { get; set; }
        public string WeekdayStartTime { get; set; } = string.Empty;
        public string WeekdayEndTime { get; set; } = string.Empty;
        public int WeekdayStudyHours { get; set; }
        public bool HasWeekendCourse { get; set; }
        public string WeekendStartTime { get; set; } = string.Empty;
        public int WeekendStudyHours { get; set; }
        public string WeekdayLatestTime { get; set; } = string.Empty;
        public string WeekendLatestTime { get; set; } = string.Empty;
        public string OffDaysJson { get; set; } = "[]";
        public string StrongSubjectsJson { get; set; } = "[]";
        public string WeakSubjectsJson { get; set; } = "[]";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; } = null!;
    }
}
