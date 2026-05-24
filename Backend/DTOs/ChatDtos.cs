using System.Collections.Generic;

namespace Backend.DTOs
{
    public class ChatMessageDto
    {
        public string Role { get; set; } = "user"; // "user" | "model"
        public string Content { get; set; } = string.Empty;
    }

    public class TodayTaskDto
    {
        public string Id { get; set; } = string.Empty;
        public string SubjectName { get; set; } = string.Empty;
        public string TaskType { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        /// <summary>Kullanıcı bu görevi tamamladı mı? (client tarafından gönderilir)</summary>
        public bool IsCompleted { get; set; }
    }

    public class ChatRequestDto
    {
        public List<ChatMessageDto> Messages { get; set; } = new();
        public string? UserName { get; set; }
        public string? TargetExam { get; set; }
        public string? SelectedArea { get; set; }
        public List<string> WeakLessons { get; set; } = new();
        public List<string> StrongLessons { get; set; } = new();
        public List<TodayTaskDto> TodayTasks { get; set; } = new();
    }

    public class ChatResponseDto
    {
        public string Message { get; set; } = string.Empty;
        public ScheduleUpdateIntentDto? ScheduleIntent { get; set; }
        public AddTaskIntentDto? AddTaskIntent { get; set; }
        public AssignTopicIntentDto? AssignTopicIntent { get; set; }
    }

    public class ScheduleUpdateIntentDto
    {
        public string LessonName { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public string Suggestion { get; set; } = string.Empty;
    }

    public class AddTaskIntentDto
    {
        public string SubjectName { get; set; } = string.Empty;
        public string TaskType { get; set; } = string.Empty;
        public int DurationMinutes { get; set; } = 60;
        public string Suggestion { get; set; } = string.Empty;
    }

    public class AssignTopicIntentDto
    {
        public string Suggestion { get; set; } = string.Empty;
    }
}
