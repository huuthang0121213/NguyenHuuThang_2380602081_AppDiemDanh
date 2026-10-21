using System.ComponentModel.DataAnnotations;

namespace NguyenHuuThang_2380602081.API.DTOs
{
    public class CreateSessionDto
    {
        [Required]
        public int CourseId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string SessionCode { get; set; } = string.Empty;

        public int DurationMinutes { get; set; } = 30;

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public int AllowedRadiusMeters { get; set; } = 50;
    }

    public class CheckInDto
    {
        [Required]
        public int SessionId { get; set; }

        [Required]
        public string SessionCode { get; set; } = string.Empty;

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public string Method { get; set; } = "QRCode"; // QRCode, GPS, Manual
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
        public string? Note { get; set; }
    }
}
