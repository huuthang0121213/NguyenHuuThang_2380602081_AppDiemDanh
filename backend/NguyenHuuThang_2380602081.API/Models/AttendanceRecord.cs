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

        [MaxLength(50)]
        public string CheckInMethod { get; set; } = "QRCode"; // QRCode, Manual, GPS

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public string? FacePhotoBase64 { get; set; }

        public bool IsFaceVerified { get; set; } = false;

        [MaxLength(500)]
        public string? Note { get; set; }
    }
}
