using Backend.DTOs;

namespace Backend.Services
{
    public interface IAuthService
    {
        Task<string> RegisterAsync(UserRegisterDto request);
        Task<string> LoginAsync(UserLoginDto request);
    }
}
