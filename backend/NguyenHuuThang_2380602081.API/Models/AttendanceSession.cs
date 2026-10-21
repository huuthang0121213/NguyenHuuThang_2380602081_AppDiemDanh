using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NguyenHuuThang_2380602081.API.Models
{
    public class AttendanceSession
    {
        [Key]
        public int Id { get; set; }

        public int CourseId { get; set; }

        [ForeignKey("CourseId")]
        public Course? Course { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string SessionCode { get; set; } = string.Empty;

        public DateTime StartTime { get; set; } = DateTime.UtcNow;

        public DateTime EndTime { get; set; } = DateTime.UtcNow.AddMinutes(30);

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public int AllowedRadiusMeters { get; set; } = 50;

        public bool IsClosed { get; set; } = false;

        // Navigation
        public ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
    }
}
