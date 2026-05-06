using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class UserRegisterDto
    {
        [MaxLength(255)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? TargetExam { get; set; }
    }
}
