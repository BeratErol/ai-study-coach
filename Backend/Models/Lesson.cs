using System.Collections.Generic;

namespace Backend.Models
{
    public class Lesson
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ColorCode { get; set; } = "#3498db";

        // Navigation properties
        public User User { get; set; } = null!;
        public ICollection<Topic> Topics { get; set; } = new List<Topic>();
    }
}
