using System.Threading.Tasks;
using Backend.DTOs;

namespace Backend.Services
{
    public interface IAiService
    {
        Task<AiPlanResponseDto> GenerateStudyPlanAsync(AiPlanRequestDto request);
    }
}
