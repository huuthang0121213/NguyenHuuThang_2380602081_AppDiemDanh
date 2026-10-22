using System.ComponentModel.DataAnnotations;

namespace NguyenHuuThang_2380602081.API.Models
{
    /// <summary>
    /// Lưu trữ các QR Token đã được sử dụng để chống quét lại (Replay Attack)
    /// Dynamic QR: mỗi token chỉ dùng 1 lần duy nhất
    /// </summary>
    public class QrToken
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// Token TOTP duy nhất nhúng trong QR Code (bao gồm sessionId + timestamp + hash)
        /// </summary>
        [Required]
        [MaxLength(512)]
        public string Token { get; set; } = string.Empty;

        /// <summary>
        /// Phiên điểm danh mà token này thuộc về
        /// </summary>
        public int SessionId { get; set; }

        /// <summary>
        /// Student đã dùng token này (null nếu chưa dùng)
        /// </summary>
        public int? UsedByStudentId { get; set; }

        /// <summary>
        /// Thời điểm token được tạo ra (timestamp nhúng trong QR)
        /// </summary>
        public DateTime IssuedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Thời điểm token hết hạn (IssuedAt + 15 giây)
        /// </summary>
        public DateTime ExpiresAt { get; set; }

        /// <summary>
        /// Thời điểm token được sử dụng để điểm danh
        /// </summary>
        public DateTime? UsedAt { get; set; }

        /// <summary>
        /// Đánh dấu token đã được dùng (chống Replay Attack)
        /// </summary>
        public bool IsUsed { get; set; } = false;

        /// <summary>
        /// Device ID của thiết bị đã dùng token
        /// </summary>
        [MaxLength(256)]
        public string? DeviceId { get; set; }
    }
}
