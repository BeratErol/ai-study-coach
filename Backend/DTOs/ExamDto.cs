using System;
using System.Collections.Generic;

namespace Backend.DTOs
{
    public class CreateExamDto
    {
        public string Title { get; set; } = string.Empty;
        public DateTime Date { get; set; } = DateTime.UtcNow;
        public string Type { get; set; } = string.Empty; // TYT, AYT, BRANS
        public List<CreateExamDetailDto> Details { get; set; } = new();
    }

    public class CreateExamDetailDto
    {
        public string LessonName { get; set; } = string.Empty;
        public int Correct { get; set; }
        public int Incorrect { get; set; }
    }

    public class ExamResponseDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public string Type { get; set; } = string.Empty;
        public decimal TotalNet { get; set; }
        public List<ExamDetailResponseDto> Details { get; set; } = new();
    }

    public class ExamDetailResponseDto
    {
        public int Id { get; set; }
        public string LessonName { get; set; } = string.Empty;
        public int Correct { get; set; }
        public int Incorrect { get; set; }
        public decimal Net { get; set; }
    }

    public class ExamAnalysisDto
    {
        public List<LessonAverageDto> LessonAverages { get; set; } = new();
        public List<ExamProgressDto> ProgressOverTime { get; set; } = new();
    }

    public class LessonAverageDto
    {
        public string LessonName { get; set; } = string.Empty;
        public decimal AverageNet { get; set; }
    }

    public class ExamProgressDto
    {
        public int ExamId { get; set; }
        public string ExamTitle { get; set; } = string.Empty;
        public string ExamType { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public decimal TotalNet { get; set; }
        public List<LessonNetDto> Lessons { get; set; } = new();
    }

    public class LessonNetDto
    {
        public string LessonName { get; set; } = string.Empty;
        public decimal Net { get; set; }
    }
}
