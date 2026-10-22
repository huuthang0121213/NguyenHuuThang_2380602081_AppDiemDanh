using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using NguyenHuuThang_2380602081.API.Models;

namespace NguyenHuuThang_2380602081.API.Data
{
    public class AppDbContext : IdentityDbContext<ApplicationUser>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Student> Students { get; set; }
        public DbSet<Course> Courses { get; set; }
        public DbSet<AttendanceSession> AttendanceSessions { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<OtpVerification> OtpVerifications { get; set; }
        public DbSet<QrToken> QrTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Configure unique index for StudentCode
            builder.Entity<Student>()
                .HasIndex(s => s.StudentCode)
                .IsUnique();

            // Configure unique index for CourseCode
            builder.Entity<Course>()
                .HasIndex(c => c.CourseCode)
                .IsUnique();

            // Configure cascade deletes or restrict
            builder.Entity<AttendanceRecord>()
                .HasOne(ar => ar.Student)
                .WithMany(s => s.AttendanceRecords)
                .HasForeignKey(ar => ar.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<AttendanceRecord>()
                .HasOne(ar => ar.Session)
                .WithMany(s => s.AttendanceRecords)
                .HasForeignKey(ar => ar.SessionId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
