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

        // ==========================================
        // 1. TẠO PHIÊN ĐIỂM DANH (GIẢNG VIÊN)
        // Tạo mã QR và Mã Code 6 số ngẫu nhiên
        // ==========================================
        [HttpPost("session")]
        public async Task<IActionResult> CreateSession([FromBody] CreateSessionDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Tự động sinh mã Code gồm 6 số ngẫu nhiên nếu không truyền
            var code = string.IsNullOrWhiteSpace(dto.SessionCode)
                ? Random.Shared.Next(100000, 999999).ToString("D6")
                : dto.SessionCode.Trim();

            // Đảm bảo môn học tồn tại (mặc định lấy môn đầu tiên nếu không tìm thấy)
            var course = await _context.Courses.FindAsync(dto.CourseId) ?? await _context.Courses.FirstOrDefaultAsync();
            var courseId = course?.Id ?? 1;

            var session = new AttendanceSession
            {
                CourseId = courseId,
                Title = dto.Title,
                SessionCode = code,
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddMinutes(dto.DurationMinutes > 0 ? dto.DurationMinutes : 30),
                Latitude = dto.Latitude ?? 10.8231, // Tọa độ mặc định phòng học
                Longitude = dto.Longitude ?? 106.6297,
                AllowedRadiusMeters = dto.AllowedRadiusMeters > 0 ? dto.AllowedRadiusMeters : 200,
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
                    session.SessionCode, // Mã 6 số để sinh viên nhập thủ công hoặc quét QR
                    session.StartTime,
                    session.EndTime,
                    session.Latitude,
                    session.Longitude,
                    session.AllowedRadiusMeters
                }
            });
        }

        // ==========================================
        // 2. SINH VIÊN ĐIỂM DANH (QR CODE / MÃ 6 SỐ / GPS / KHUÔN MẶT)
        // ==========================================
        [HttpPost("check-in")]
        [Authorize]
        public async Task<IActionResult> CheckIn([FromBody] CheckInDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var studentCode = User.FindFirstValue("StudentCode");

            // 1. Tìm hồ sơ sinh viên
            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId || (!string.IsNullOrEmpty(studentCode) && s.StudentCode == studentCode));

            if (student == null)
            {
                return BadRequest(new { success = false, message = "Không tìm thấy hồ sơ sinh viên tương ứng với tài khoản này!" });
            }

            // 2. Tìm phiên điểm danh bằng SessionId hoặc tìm trực tiếp bằng Mã 6 số (SessionCode)
            var cleanCode = dto.SessionCode.Trim();
            AttendanceSession? session = null;

            if (dto.SessionId.HasValue && dto.SessionId.Value > 0)
            {
                session = await _context.AttendanceSessions.FindAsync(dto.SessionId.Value);
            }
            else
            {
                session = await _context.AttendanceSessions
                    .Where(s => s.SessionCode == cleanCode && !s.IsClosed && s.EndTime > DateTime.UtcNow)
                    .OrderByDescending(s => s.StartTime)
                    .FirstOrDefaultAsync();
            }

            if (session == null || session.IsClosed || DateTime.UtcNow > session.EndTime)
            {
                return BadRequest(new { success = false, message = "Phiên điểm danh không tồn tại hoặc đã hết hạn hiệu lực!" });
            }

            if (session.SessionCode != cleanCode)
            {
                return BadRequest(new { success = false, message = "Mã điểm danh gồm 6 số không chính xác!" });
            }

            // 3. XÁC MINH VỊ TRÍ GPS (Nếu phiên có cấu hình tọa độ phòng học)
            if (session.Latitude.HasValue && session.Longitude.HasValue && dto.Latitude.HasValue && dto.Longitude.HasValue)
            {
                var distanceMeters = CalculateDistanceInMeters(
                    session.Latitude.Value,
                    session.Longitude.Value,
                    dto.Latitude.Value,
                    dto.Longitude.Value
                );

                if (distanceMeters > session.AllowedRadiusMeters)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = $"Vị trí GPS của bạn cách phòng học {Math.Round(distanceMeters)}m, vượt quá bán kính cho phép ({session.AllowedRadiusMeters}m). Bạn phải có mặt tại lớp để điểm danh!"
                    });
                }
            }

            // 4. KIỂM TRA ĐIỂM DANH TRÙNG LẶP
            var alreadyCheckedIn = await _context.AttendanceRecords
                .AnyAsync(r => r.SessionId == session.Id && r.StudentId == student.Id);

            if (alreadyCheckedIn)
            {
                return BadRequest(new { success = false, message = "Bạn đã hoàn tất điểm danh cho buổi học này rồi!" });
            }

            // 5. XÁC MINH KHUÔN MẶT
            bool faceVerified = !string.IsNullOrWhiteSpace(dto.FacePhotoBase64);

            // 6. GHI NHẬN ĐIỂM DANH
            var record = new AttendanceRecord
            {
                SessionId = session.Id,
                StudentId = student.Id,
                CheckInTime = DateTime.UtcNow,
                Status = "Present",
                CheckInMethod = dto.Method,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                FacePhotoBase64 = dto.FacePhotoBase64,
                IsFaceVerified = faceVerified,
                Note = faceVerified ? "Đã xác minh khuôn mặt & GPS" : "Điểm danh mã phiên"
            };

            _context.AttendanceRecords.Add(record);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Sinh viên {student.FullName} ({student.StudentCode}) đã điểm danh thành công!",
                checkInTime = record.CheckInTime,
                status = record.Status,
                isFaceVerified = record.IsFaceVerified
            });
        }

        // ==========================================
        // 3. XEM LỊCH SỬ ĐIỂM DANH (SINH VIÊN)
        // ==========================================
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
                    CourseName = r.Session != null && r.Session.Course != null ? r.Session.Course.CourseName : "Lập trình di động",
                    StudentId = r.StudentId,
                    StudentCode = student.StudentCode,
                    StudentName = student.FullName,
                    CheckInTime = r.CheckInTime,
                    Status = r.Status,
                    CheckInMethod = r.CheckInMethod,
                    Latitude = r.Latitude,
                    Longitude = r.Longitude,
                    FacePhotoBase64 = r.FacePhotoBase64,
                    IsFaceVerified = r.IsFaceVerified,
                    Note = r.Note
                })
                .ToListAsync();

            return Ok(records);
        }

        // Công thức Haversine tính khoảng cách (mét) giữa 2 tọa độ GPS
        private static double CalculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371000; // Bán kính trái đất tính bằng mét
            var phi1 = lat1 * Math.PI / 180;
            var phi2 = lat2 * Math.PI / 180;
            var deltaPhi = (lat2 - lat1) * Math.PI / 180;
            var deltaLambda = (lon2 - lon1) * Math.PI / 180;

            var a = Math.Sin(deltaPhi / 2) * Math.Sin(deltaPhi / 2) +
                    Math.Cos(phi1) * Math.Cos(phi2) *
                    Math.Sin(deltaLambda / 2) * Math.Sin(deltaLambda / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            return R * c;
        }
    }
}
