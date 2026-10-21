using System.ComponentModel.DataAnnotations;

namespace NguyenHuuThang_2380602081.API.Models
{
    public class Course
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string CourseCode { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string CourseName { get; set; } = string.Empty;

        public int Credits { get; set; } = 3;

        public string? TeacherId { get; set; }

        // Navigation
        public ICollection<AttendanceSession> AttendanceSessions { get; set; } = new List<AttendanceSession>();
    }
}
