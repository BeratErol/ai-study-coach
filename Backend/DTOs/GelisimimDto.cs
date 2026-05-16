namespace Backend.DTOs
{
    public class GelisimimStatsDto
    {
        public int CompletedTasks { get; set; }
        public int TotalMinutes { get; set; }
        public int TotalQuestions { get; set; }
        public int RestDays { get; set; }
    }

    public class SubjectEntryDto
    {
        public string Key { get; set; } = null!;
        public string Name { get; set; } = null!;
        public string Icon { get; set; } = null!;
        public int TodayCount { get; set; }
    }

    public class SaveQuestionsRequestDto
    {
        public List<SaveQuestionEntryDto> Entries { get; set; } = new();
    }

    public class SaveQuestionEntryDto
    {
        public string SubjectKey { get; set; } = null!;
        public string SubjectName { get; set; } = null!;
        public int Count { get; set; }
    }

    public class SaveQuestionsResponseDto
    {
        public bool Success { get; set; }
        public int TotalToday { get; set; }
    }

    public class CalendarResponseDto
    {
        public List<string> ActiveDays { get; set; } = new();
    }

    public class DailyReportDto
    {
        public string Date { get; set; } = null!;
        public List<DailyQuestionDto> Questions { get; set; } = new();
        public DailyTasksDto Tasks { get; set; } = null!;
        public bool IsEmpty { get; set; }
    }

    public class DailyQuestionDto
    {
        public string SubjectName { get; set; } = null!;
        public int Count { get; set; }
    }

    public class DailyTasksDto
    {
        public int Completed { get; set; }
        public int Missed { get; set; }
        public int TotalMinutes { get; set; }
    }

    public class XpInfoDto
    {
        public int TotalXP { get; set; }
        public int CurrentLevelXP { get; set; }
        public int NextLevelXP { get; set; }
        public string LevelName { get; set; } = null!;
        public string LevelEmoji { get; set; } = null!;
        public int StreakDays { get; set; }
        public int TotalQuestions { get; set; }
    }

    public class LessonDistributionDto
    {
        public string LessonName { get; set; } = null!;
        public int TotalQuestions { get; set; }
    }
}
