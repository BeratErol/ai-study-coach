using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.DTOs;

namespace Backend.Services
{
    public interface IExamService
    {
        Task<ExamResponseDto> AddExamAsync(int userId, CreateExamDto dto);
        Task<IEnumerable<ExamResponseDto>> GetExamResultsAsync(int userId);
        Task<ExamAnalysisDto> GetExamAnalysisAsync(int userId);
    }
}
