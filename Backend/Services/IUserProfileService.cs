using Backend.DTOs;

namespace Backend.Services
{
    public interface IUserProfileService
    {
        Task<UserProfileResponseDto> UpsertProfileAsync(int userId, UserProfileRequestDto dto);
        Task<UserProfileResponseDto?> GetProfileAsync(int userId);
    }
}
