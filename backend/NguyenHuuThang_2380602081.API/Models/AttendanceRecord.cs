using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NguyenHuuThang_2380602081.API.Models
{
    public class AttendanceRecord
    {
        [Key]
        public int Id { get; set; }

        public int SessionId { get; set; }

        [ForeignKey("SessionId")]
        public AttendanceSession? Session { get; set; }

        public int StudentId { get; set; }

        [ForeignKey("StudentId")]
        public Student? Student { get; set; }

        public DateTime CheckInTime { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Present"; // Present, Late, Absent

        [MaxLength(100)]
        public string CheckInMethod { get; set; } = "QRCode+Face+GPS"; // QRCode, Manual, GPS

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        // ================================================================
        // BẢO VỆ DỮ LIỆU: KHÔNG lưu ảnh gốc, chỉ lưu vector đặc trưng khuôn mặt
        // Face Embedding là JSON array float[] 128 chiều (FaceNet-style)
        // Dữ liệu không thể khôi phục lại ảnh gốc từ vector này
        // ================================================================
        public string? FaceEmbeddingJson { get; set; }

        public bool IsFaceVerified { get; set; } = false;

        // ================================================================
        // DEVICE BINDING: Ghi lại thiết bị đã điểm danh
        // ================================================================
        [MaxLength(256)]
        public string? DeviceId { get; set; }

        // ================================================================
        // QR TOKEN: Lưu token đã dùng để chống replay attack
        // ================================================================
        [MaxLength(512)]
        public string? QrTokenUsed { get; set; }

        [MaxLength(500)]
        public string? Note { get; set; }
    }
}
