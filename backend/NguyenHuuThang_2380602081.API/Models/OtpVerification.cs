namespace NguyenHuuThang_2380602081.API.Models
{
    public class OtpVerification
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiryTime { get; set; }
        public int FailedAttempts { get; set; } = 0;
        public bool IsUsed { get; set; } = false;
    }
}
