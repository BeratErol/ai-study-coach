using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class TopicCreateDto
    {
        [Required]
        public int LessonId { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;
    }
}
