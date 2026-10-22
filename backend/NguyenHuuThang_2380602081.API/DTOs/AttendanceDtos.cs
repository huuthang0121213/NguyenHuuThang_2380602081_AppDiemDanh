using System.ComponentModel.DataAnnotations;

namespace NguyenHuuThang_2380602081.API.DTOs
{
    public class CreateSessionDto
    {
        public int CourseId { get; set; } = 1;

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = "Buổi học Lập trình di động";

        // Mã phiên 6 số (nếu để trống hệ thống sẽ tự sinh ngẫu nhiên)
        public string? SessionCode { get; set; }

        public int DurationMinutes { get; set; } = 30;

        // Tọa độ GPS phòng học (mặc định tại trường ĐH)
        public double? Latitude { get; set; } = 10.8231;

        public double? Longitude { get; set; } = 106.6297;

        // Bán kính cho phép điểm danh (mét)
        public int AllowedRadiusMeters { get; set; } = 200;
    }

    public class CheckInDto
    {
        // Có thể truyền SessionId hoặc không cần truyền nếu đã có SessionCode 6 số
        public int? SessionId { get; set; }

        [Required]
        public string SessionCode { get; set; } = string.Empty;

        // ================================================================
        // DYNAMIC QR TOKEN: Token TOTP nhúng trong QR Code (thay đổi 10 giây)
        // Server sẽ xác thực: token còn hạn + chưa từng được dùng
        // ================================================================
        public string? QrToken { get; set; }

        // Timestamp tạo QR Token trên client (UTC Unix timestamp ms)
        public long? QrTimestamp { get; set; }

        // ================================================================
        // GPS
        // ================================================================
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        // ================================================================
        // FACE EMBEDDING: Không gửi ảnh gốc, chỉ gửi vector đặc trưng
        // Mảng float[] độ dài 128 chiều (JSON serialized)
        // ================================================================
        public string? FaceEmbeddingJson { get; set; }

        // ================================================================
        // DEVICE BINDING: Device ID duy nhất của thiết bị sinh viên
        // ================================================================
        public string? DeviceId { get; set; }

        public string Method { get; set; } = "DynamicQR+Face+GPS";
    }

    public class AttendanceRecordDto
    {
        public int Id { get; set; }
        public int SessionId { get; set; }
        public string SessionTitle { get; set; } = string.Empty;
        public string CourseName { get; set; } = string.Empty;
        public int StudentId { get; set; }
        public string StudentCode { get; set; } = string.Empty;
        public string StudentName { get; set; } = string.Empty;
        public DateTime CheckInTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public string CheckInMethod { get; set; } = string.Empty;
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public bool IsFaceVerified { get; set; }
        public string? Note { get; set; }
        // Không trả về FaceEmbedding hay ảnh gốc về client
    }

    /// <summary>
    /// DTO để sinh Dynamic QR Token (endpoint riêng cho Giảng viên)
    /// </summary>
    public class GenerateQrTokenResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public string SessionCode { get; set; } = string.Empty;
        public long IssuedAtMs { get; set; }
        public long ExpiresAtMs { get; set; }
        public int ValidSeconds { get; set; }
        public string QrData { get; set; } = string.Empty; // JSON nhúng vào QR code
    }
}
