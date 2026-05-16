namespace Backend.Models
{
    public class QuestionLog
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Date { get; set; } = null!;        // "yyyy-MM-dd"
        public string SubjectKey { get; set; } = null!;  // e.g. "tyt_matematik"
        public string SubjectName { get; set; } = null!; // e.g. "Matematik"
        public int Count { get; set; }

        public User User { get; set; } = null!;
    }
}
