namespace Backend.DTOs
{
    public class AiPlanRequestDto
    {
        public string Prompt { get; set; } = string.Empty;
    }

    public class AiPlanResponseDto
    {
        public string SuggestedName { get; set; } = string.Empty;
        public string SuggestedDifficulty { get; set; } = string.Empty; // Kolay, Orta, Zor
        public double RecommendedHours { get; set; }
        public string Advice { get; set; } = string.Empty;
    }

    // Dashboard AI coach card
    public class DashboardCoachRequestDto
    {
        public string UserName { get; set; } = string.Empty;
        public string? TargetExam { get; set; }
        public List<LessonSummaryDto> Lessons { get; set; } = new();
        public List<ExamSummaryDto> RecentExams { get; set; } = new();
        public int TotalStudyMinutesThisWeek { get; set; }
    }

    public class LessonSummaryDto
    {
        public string Name { get; set; } = string.Empty;
        public int TotalTopics { get; set; }
        public int CompletedTopics { get; set; }
    }

    public class ExamSummaryDto
    {
        public string Title { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public decimal NetScore { get; set; }
        public DateTime Date { get; set; }
    }

    public class DashboardCoachResponseDto
    {
        public string Greeting { get; set; } = string.Empty;
        public string TodayFocus { get; set; } = string.Empty;
        public string WeakAreaWarning { get; set; } = string.Empty;
        public string MotivationNote { get; set; } = string.Empty;
        public List<string> ActionItems { get; set; } = new();
    }
}
