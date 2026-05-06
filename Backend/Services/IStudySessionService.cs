using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Models;

namespace Backend.Services
{
    public interface IStudySessionService
    {
        Task<StudySessionDto> CreateSessionAsync(int userId, CreateStudySessionDto dto);
        Task<IEnumerable<StudySessionDto>> GetSessionsAsync(int userId, int? topicId = null, DateTime? date = null);
        Task<StudySessionSummaryDto> GetSummaryAsync(int userId);
        Task DeleteAllSessionsAsync(int userId);
        Task<List<StudySession>> GetUserSessionsAsync(int userId);
        Task<WeeklyStudySummaryDto> GetWeeklySummaryAsync(int userId);
        Task<List<DailyActivityDto>> GetMonthlyHeatmapAsync(int userId);
    }
}
