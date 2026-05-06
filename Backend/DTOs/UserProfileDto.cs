namespace Backend.DTOs
{
    public class UserProfileRequestDto
    {
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
        public List<int> OffDays { get; set; } = new();
        public List<string> StrongSubjects { get; set; } = new();
        public List<string> WeakSubjects { get; set; } = new();
    }

    public class UserProfileResponseDto
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
        public List<int> OffDays { get; set; } = new();
        public List<string> StrongSubjects { get; set; } = new();
        public List<string> WeakSubjects { get; set; } = new();
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
