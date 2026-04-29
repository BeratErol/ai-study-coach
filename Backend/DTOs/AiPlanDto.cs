namespace Backend.DTOs
{
    public class AiPlanRequestDto
    {
        public string Prompt { get; set; } = string.Empty;
    }

    public class AiPlanResponseDto
    {
        public string SuggestedName { get; set; } = string.Empty;
        public string SuggestedDifficulty { get; set; } = string.Empty; // Kolay, Orta, Zor
        public double RecommendedHours { get; set; }
        public string Advice { get; set; } = string.Empty;
    }
}
