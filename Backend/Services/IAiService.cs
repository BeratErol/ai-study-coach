using System.Threading.Tasks;
using Backend.DTOs;

namespace Backend.Services
{
    public interface IAiService
    {
        Task<AiPlanResponseDto> GenerateStudyPlanAsync(AiPlanRequestDto request);
        Task<string> GenerateTextRecommendationAsync(string prompt);
        Task<List<AiPlanResponseDto>> OptimizePlanAsync(int userId, ExamAnalysisDto analysis);
        Task<DashboardCoachResponseDto> GenerateDashboardCoachAsync(DashboardCoachRequestDto context);
        Task<ChatResponseDto> ChatAsync(ChatRequestDto request);
    }
}
