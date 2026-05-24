namespace Backend.Models
{
    /// <summary>
    /// Cihazdan bağımsız, kullanıcıya özel generic key-value deposu.
    /// Notlar, akademik hedef, manuel görevler, tamamlanan görevler gibi
    /// mobil ve web arasında senkron olması gereken her veri burada tutulur.
    /// </summary>
    public class AppState
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Key { get; set; } = string.Empty;
        public string ValueJson { get; set; } = "null";
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; } = null!;
    }
}
