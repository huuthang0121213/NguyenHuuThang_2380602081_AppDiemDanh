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

        // Tọa độ GPS của sinh viên khi bấm điểm danh
        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        // Ảnh chụp khuôn mặt của sinh viên (chuỗi Base64)
        public string? FacePhotoBase64 { get; set; }

        public string Method { get; set; } = "QRCode"; // QRCode, 6DigitCode, GPS, Face
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
        public string? FacePhotoBase64 { get; set; }
        public bool IsFaceVerified { get; set; }
        public string? Note { get; set; }
    }
}
