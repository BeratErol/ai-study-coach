using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.DTOs;

namespace Backend.Services
{
    public interface IExamService
    {
        Task<ExamResponseDto> AddExamAsync(int userId, CreateExamDto dto);
        Task<IEnumerable<ExamResponseDto>> GetExamResultsAsync(int userId);
        Task<bool> DeleteExamAsync(int userId, int examId);
        Task<ExamResponseDto?> UpdateExamAsync(int userId, int examId, CreateExamDto dto);
        Task<IEnumerable<ExamResponseDto>> GetExamsByTypeAsync(int userId, string type);
        Task<ExamAnalysisDto> GetExamAnalysisAsync(int userId);
        Task<string> GetAiRecommendationAsync(int userId);
    }
}
