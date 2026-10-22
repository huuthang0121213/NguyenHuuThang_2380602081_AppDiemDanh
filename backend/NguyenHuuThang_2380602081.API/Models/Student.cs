using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NguyenHuuThang_2380602081.API.Models
{
    public class Student
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string StudentCode { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(256)]
        public string Email { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? PhoneNumber { get; set; }

        [Required]
        [MaxLength(100)]
        public string ClassName { get; set; } = string.Empty;

        public string? UserId { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // ================================================================
        // DEVICE BINDING: Mỗi sinh viên chỉ được gắn với 1 Device ID duy nhất
        // Ngăn chặn nhiều thiết bị dùng chung tài khoản để điểm danh hộ
        // ================================================================
        [MaxLength(256)]
        public string? DeviceId { get; set; }

        public DateTime? DeviceRegisteredAt { get; set; }

        // ================================================================
        // FACE EMBEDDING: Không lưu ảnh gốc, chỉ lưu chuỗi vector đặc trưng
        // Định dạng: JSON array float[] độ dài 128 (FaceNet-style embedding)
        // ================================================================
        public string? FaceEmbeddingJson { get; set; }

        public DateTime? FaceRegisteredAt { get; set; }

        // Navigation
        public ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
    }
}
