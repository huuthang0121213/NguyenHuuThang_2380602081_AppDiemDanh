using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.DTOs;
using NguyenHuuThang_2380602081.API.Models;

namespace NguyenHuuThang_2380602081.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AttendanceController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AttendanceController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/attendance/session (Tạo phiên điểm danh - Giảng viên)
        [HttpPost("session")]
        public async Task<IActionResult> CreateSession([FromBody] CreateSessionDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var session = new AttendanceSession
            {
                CourseId = dto.CourseId,
                Title = dto.Title,
                SessionCode = dto.SessionCode,
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddMinutes(dto.DurationMinutes),
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                AllowedRadiusMeters = dto.AllowedRadiusMeters,
                IsClosed = false
            };

            _context.AttendanceSessions.Add(session);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Đã tạo phiên điểm danh thành công!",
                session = new
                {
                    session.Id,
                    session.Title,
                    session.SessionCode,
                    session.StartTime,
                    session.EndTime
                }
            });
        }

        // POST: api/attendance/check-in (Sinh viên quét mã điểm danh)
        [HttpPost("check-in")]
        [Authorize]
        public async Task<IActionResult> CheckIn([FromBody] CheckInDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var studentCode = User.FindFirstValue("StudentCode");

            // Find student by UserId or StudentCode
            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId || (!string.IsNullOrEmpty(studentCode) && s.StudentCode == studentCode));

            if (student == null)
            {
                return BadRequest(new { success = false, message = "Không tìm thấy hồ sơ sinh viên tương ứng với tài khoản đăng nhập!" });
            }

            var session = await _context.AttendanceSessions.FindAsync(dto.SessionId);
            if (session == null || session.IsClosed || DateTime.UtcNow > session.EndTime)
            {
                return BadRequest(new { success = false, message = "Phiên điểm danh không tồn tại hoặc đã hết hạn!" });
            }

            if (session.SessionCode != dto.SessionCode)
            {
                return BadRequest(new { success = false, message = "Mã phiên điểm danh (QR) không hợp lệ!" });
            }

            // Check if student already checked in
            var alreadyCheckedIn = await _context.AttendanceRecords
                .AnyAsync(r => r.SessionId == dto.SessionId && r.StudentId == student.Id);

            if (alreadyCheckedIn)
            {
                return BadRequest(new { success = false, message = "Bạn đã điểm danh cho buổi học này rồi!" });
            }

            var record = new AttendanceRecord
            {
                SessionId = session.Id,
                StudentId = student.Id,
                CheckInTime = DateTime.UtcNow,
                Status = "Present",
                CheckInMethod = dto.Method,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude
            };

            _context.AttendanceRecords.Add(record);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Sinh viên {student.FullName} ({student.StudentCode}) điểm danh thành công!",
                checkInTime = record.CheckInTime,
                status = record.Status
            });
        }

        // GET: api/attendance/history (Xem lịch sử điểm danh của sinh viên hiện tại)
        [HttpGet("history")]
        [Authorize]
        public async Task<IActionResult> GetMyAttendanceHistory()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var studentCode = User.FindFirstValue("StudentCode");

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId || (!string.IsNullOrEmpty(studentCode) && s.StudentCode == studentCode));

            if (student == null)
            {
                return Ok(new List<AttendanceRecordDto>());
            }

            var records = await _context.AttendanceRecords
                .Include(r => r.Session)
                .ThenInclude(s => s!.Course)
                .Where(r => r.StudentId == student.Id)
                .OrderByDescending(r => r.CheckInTime)
                .Select(r => new AttendanceRecordDto
                {
                    Id = r.Id,
                    SessionId = r.SessionId,
                    SessionTitle = r.Session != null ? r.Session.Title : "",
                    CourseName = r.Session != null && r.Session.Course != null ? r.Session.Course.CourseName : "Chưa xác định",
                    StudentId = r.StudentId,
                    StudentCode = student.StudentCode,
                    StudentName = student.FullName,
                    CheckInTime = r.CheckInTime,
                    Status = r.Status,
                    CheckInMethod = r.CheckInMethod,
                    Note = r.Note
                })
                .ToListAsync();

            return Ok(records);
        }
    }
}
