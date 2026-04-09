using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class LessonCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        
        public string ColorCode { get; set; } = "#3498db";
    }
}
