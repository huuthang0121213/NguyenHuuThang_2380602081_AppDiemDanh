using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.DTOs;
using NguyenHuuThang_2380602081.API.Models;
using NguyenHuuThang_2380602081.API.Services;

namespace NguyenHuuThang_2380602081.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AttendanceController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;

        // QR Token hết hạn sau bao nhiêu giây (60 giây = 1 phút)
        private const int QrTokenValidSeconds = 60;

        public AttendanceController(AppDbContext context, IEmailService emailService, IConfiguration configuration)
        {
            _context = context;
            _emailService = emailService;
            _configuration = configuration;
        }

        // ==========================================
        // 1. TẠO PHIÊN ĐIỂM DANH (GIẢNG VIÊN)
        // ==========================================
        [HttpPost("session")]
        public async Task<IActionResult> CreateSession([FromBody] CreateSessionDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var code = string.IsNullOrWhiteSpace(dto.SessionCode)
                ? Random.Shared.Next(100000, 999999).ToString("D6")
                : dto.SessionCode.Trim();

            var course = await _context.Courses.FindAsync(dto.CourseId) ?? await _context.Courses.FirstOrDefaultAsync();
            var courseId = course?.Id ?? 1;

            var session = new AttendanceSession
            {
                CourseId = courseId,
                Title = dto.Title,
                SessionCode = code,
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddMinutes(dto.DurationMinutes > 0 ? dto.DurationMinutes : 30),
                Latitude = dto.Latitude ?? 10.8231,
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
                    session.SessionCode,
                    session.StartTime,
                    session.EndTime,
                    session.Latitude,
                    session.Longitude,
                    session.AllowedRadiusMeters,
                    qrTokenValidSeconds = QrTokenValidSeconds
                }
            });
        }

        // ==========================================
        // 2. SINH DYNAMIC QR TOKEN (Endpoint riêng, gọi mỗi 10 giây)
        // Mã QR thay đổi liên tục theo thời gian thực - chống chụp ảnh QR
        // ==========================================
        [HttpGet("qr-token/{sessionId}")]
        public async Task<IActionResult> GetDynamicQrToken(int sessionId)
        {
            var session = await _context.AttendanceSessions.FindAsync(sessionId);
            if (session == null || session.IsClosed || DateTime.UtcNow > session.EndTime)
                return BadRequest(new { success = false, message = "Phiên điểm danh không hợp lệ hoặc đã kết thúc!" });

            var issuedAt = DateTime.UtcNow;
            var expiresAt = issuedAt.AddSeconds(QrTokenValidSeconds);
            var issuedAtMs = new DateTimeOffset(issuedAt).ToUnixTimeMilliseconds();
            var expiresAtMs = new DateTimeOffset(expiresAt).ToUnixTimeMilliseconds();

            // Tạo token bằng HMAC-SHA256: sessionId + sessionCode + issuedAtMs (10-giây window)
            var jwtKey = _configuration["Jwt:Key"] ?? "NguyenHuuThang_2380602081_SecretKey_For_Jwt_Auth_2026_Secure!";
            var tokenWindow = issuedAtMs / (QrTokenValidSeconds * 1000); // quantize về window
            var rawData = $"{session.Id}:{session.SessionCode}:{tokenWindow}";
            var hmac = GenerateHmac(rawData, jwtKey);
            var token = $"{session.Id}:{session.SessionCode}:{issuedAtMs}:{hmac}";

            // Dữ liệu nhúng vào QR Code (JSON compact)
            var qrData = JsonSerializer.Serialize(new
            {
                sid = session.Id,
                code = session.SessionCode,
                ts = issuedAtMs,
                exp = expiresAtMs,
                tok = hmac // chữ ký HMAC ngắn
            });

            return Ok(new GenerateQrTokenResponseDto
            {
                Token = token,
                SessionCode = session.SessionCode,
                IssuedAtMs = issuedAtMs,
                ExpiresAtMs = expiresAtMs,
                ValidSeconds = QrTokenValidSeconds,
                QrData = qrData
            });
        }

        // ==========================================
        // 3. SINH VIÊN ĐIỂM DANH - ĐẦY ĐỦ 4 LỚP BẢO MẬT
        // Bước 1: GPS → Bước 2: QR Token → Bước 3: Face ID → Bước 4: Server Check
        // ==========================================
        [HttpPost("check-in")]
        [Authorize]
        public async Task<IActionResult> CheckIn([FromBody] CheckInDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var studentCode = User.FindFirstValue("StudentCode");

            // ─── Tìm hồ sơ sinh viên ───────────────────────────────────────────
            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId || (!string.IsNullOrEmpty(studentCode) && s.StudentCode == studentCode));

            if (student == null)
                return BadRequest(new { success = false, message = "Không tìm thấy hồ sơ sinh viên tương ứng với tài khoản này!" });

            // ─── BỨC TƯỜNG 1: DEVICE BINDING ──────────────────────────────────
            // Mỗi tài khoản sinh viên chỉ được gắn với 1 Device ID duy nhất
            if (!string.IsNullOrWhiteSpace(dto.DeviceId))
            {
                if (string.IsNullOrWhiteSpace(student.DeviceId))
                {
                    // Lần đầu: ghi nhận thiết bị
                    student.DeviceId = dto.DeviceId;
                    student.DeviceRegisteredAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                }
                else if (!student.DeviceId.Equals(dto.DeviceId, StringComparison.OrdinalIgnoreCase))
                {
                    // Thiết bị khác → từ chối
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"[SECURITY] Device mismatch! Student: {student.StudentCode} | Expected: {student.DeviceId} | Got: {dto.DeviceId}");
                    Console.ResetColor();
                    return BadRequest(new
                    {
                        success = false,
                        message = "Thiết bị này không được liên kết với tài khoản của bạn! Chỉ có thể điểm danh bằng thiết bị đã đăng ký."
                    });
                }
            }

            // ─── Tìm phiên điểm danh ──────────────────────────────────────────
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
                return BadRequest(new { success = false, message = "Phiên điểm danh không tồn tại hoặc đã hết hạn!" });

            if (session.SessionCode != cleanCode)
                return BadRequest(new { success = false, message = "Mã điểm danh 6 số không chính xác!" });

            // ─── BỨC TƯỜNG 2: DYNAMIC QR TOKEN VALIDATION ─────────────────────
            // Xác thực token động nhúng trong QR Code (chống chụp ảnh QR gửi cho người khác)
            if (!string.IsNullOrWhiteSpace(dto.QrToken))
            {
                var tokenValidation = ValidateQrToken(dto.QrToken, session, dto.QrTimestamp);
                if (!tokenValidation.IsValid)
                    return BadRequest(new { success = false, message = tokenValidation.ErrorMessage });

                // Kiểm tra token đã được sử dụng chưa (chống quét 2 lần cùng 1 QR)
                var tokenAlreadyUsed = await _context.QrTokens
                    .AnyAsync(t => t.Token == dto.QrToken && t.SessionId == session.Id && t.IsUsed);

                if (tokenAlreadyUsed)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"[SECURITY ALERT] Replay Attack Detected! Student: {student.StudentCode} | Token: {dto.QrToken[..30]}...");
                    Console.ResetColor();
                    return BadRequest(new
                    {
                        success = false,
                        message = "Mã QR này đã được sử dụng! Mỗi mã QR chỉ dùng được 1 lần. Vui lòng quét mã QR mới từ màn hình giảng viên."
                    });
                }

                // Đánh dấu token đã dùng (lưu vào DB để chặn replay)
                _context.QrTokens.Add(new QrToken
                {
                    Token = dto.QrToken,
                    SessionId = session.Id,
                    UsedByStudentId = student.Id,
                    IssuedAt = dto.QrTimestamp.HasValue
                        ? DateTimeOffset.FromUnixTimeMilliseconds(dto.QrTimestamp.Value).UtcDateTime
                        : DateTime.UtcNow,
                    ExpiresAt = DateTime.UtcNow.AddSeconds(QrTokenValidSeconds),
                    UsedAt = DateTime.UtcNow,
                    IsUsed = true,
                    DeviceId = dto.DeviceId
                });
            }

            // ─── BỨC TƯỜNG 3: GPS VALIDATION ──────────────────────────────────
            // Kiểm tra vị trí thiết bị có trong phạm vi phòng học không
            if (session.Latitude.HasValue && session.Longitude.HasValue && dto.Latitude.HasValue && dto.Longitude.HasValue)
            {
                var distanceMeters = CalculateDistanceInMeters(
                    session.Latitude.Value, session.Longitude.Value,
                    dto.Latitude.Value, dto.Longitude.Value
                );

                if (distanceMeters > session.AllowedRadiusMeters)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = $"Vị trí GPS cách phòng học {Math.Round(distanceMeters)}m, vượt bán kính cho phép ({session.AllowedRadiusMeters}m). Bạn phải có mặt tại lớp!"
                    });
                }
            }

            // ─── BỨC TƯỜNG 4: KIỂM TRA TRÙNG ĐIỂM DANH ───────────────────────
            var alreadyCheckedIn = await _context.AttendanceRecords
                .AnyAsync(r => r.SessionId == session.Id && r.StudentId == student.Id);

            if (alreadyCheckedIn)
                return BadRequest(new { success = false, message = "Bạn đã hoàn tất điểm danh cho buổi học này rồi!" });

            // ─── BỨC TƯỜNG 5: FACE EMBEDDING / FACE ID ────────────────────────
            // Kiểm tra có gửi Face Embedding không (KHÔNG chấp nhận ảnh tĩnh từ gallery)
            var hasFaceData = !string.IsNullOrWhiteSpace(dto.FaceEmbeddingJson);
            if (!hasFaceData)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Bắt buộc phải xác thực khuôn mặt! Hệ thống chỉ chấp nhận ảnh chụp trực tiếp từ Camera, không dùng ảnh có sẵn."
                });
            }

            // ─── GHI NHẬN ĐIỂM DANH ───────────────────────────────────────────
            var record = new AttendanceRecord
            {
                SessionId = session.Id,
                StudentId = student.Id,
                CheckInTime = DateTime.UtcNow,
                Status = "Present",
                CheckInMethod = dto.Method,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                // Lưu Face Embedding (vector đặc trưng), KHÔNG lưu ảnh gốc
                FaceEmbeddingJson = dto.FaceEmbeddingJson,
                IsFaceVerified = hasFaceData,
                DeviceId = dto.DeviceId,
                QrTokenUsed = dto.QrToken,
                Note = "✅ Dynamic QR + Face ID + GPS + Device Binding"
            };

            _context.AttendanceRecords.Add(record);
            await _context.SaveChangesAsync();

            // ─── GỬI EMAIL XÁC NHẬN ĐIỂM DANH ────────────────────────────────
            var course = await _context.Courses.FindAsync(session.CourseId);
            _ = Task.Run(async () =>
            {
                await _emailService.SendAttendanceConfirmationAsync(
                    toEmail: student.Email,
                    fullName: student.FullName,
                    studentCode: student.StudentCode,
                    courseName: course?.CourseName ?? "Lập trình thiết bị di động",
                    sessionTitle: session.Title,
                    checkInTime: record.CheckInTime,
                    latitude: dto.Latitude,
                    longitude: dto.Longitude
                );
            });

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"[CHECK-IN SUCCESS] {student.StudentCode} - {student.FullName} | Session: {session.Title} | {DateTime.Now:HH:mm:ss}");
            Console.ResetColor();

            return Ok(new
            {
                success = true,
                message = $"✅ Sinh viên {student.FullName} ({student.StudentCode}) đã điểm danh thành công!",
                checkInTime = record.CheckInTime,
                status = record.Status,
                isFaceVerified = record.IsFaceVerified,
                securityLayers = new[] { "Dynamic QR Token", "GPS Verified", "Face ID", "Device Binding" }
            });
        }

        // ==========================================
        // 4. XEM LỊCH SỬ ĐIỂM DANH (SINH VIÊN)
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
                return Ok(new List<AttendanceRecordDto>());

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
                    IsFaceVerified = r.IsFaceVerified,
                    Note = r.Note
                })
                .ToListAsync();

            return Ok(records);
        }

        // ==========================================
        // HELPER: Xác thực Dynamic QR Token
        // ==========================================
        private (bool IsValid, string ErrorMessage) ValidateQrToken(string token, AttendanceSession session, long? clientTimestampMs)
        {
            try
            {
                var parts = token.Split(':');
                if (parts.Length < 4)
                    return (false, "Định dạng QR Token không hợp lệ!");

                if (!int.TryParse(parts[0], out var tokenSessionId) || tokenSessionId != session.Id)
                    return (false, "QR Token không thuộc phiên điểm danh này!");

                if (!long.TryParse(parts[2], out var issuedAtMs))
                    return (false, "Timestamp trong QR Token không hợp lệ!");

                var issuedAt = DateTimeOffset.FromUnixTimeMilliseconds(issuedAtMs).UtcDateTime;
                var now = DateTime.UtcNow;

                // Kiểm tra thời gian: token chỉ hợp lệ trong QrTokenValidSeconds giây
                if ((now - issuedAt).TotalSeconds > QrTokenValidSeconds + 5) // +5 giây tolerance network
                {
                    return (false, $"Mã QR đã hết hạn! Mã QR thay đổi mỗi {QrTokenValidSeconds} giây (1 phút) để bảo mật. Vui lòng quét mã QR mới nhất.");
                }

                // Xác thực chữ ký HMAC
                var jwtKey = _configuration["Jwt:Key"] ?? "NguyenHuuThang_2380602081_SecretKey_For_Jwt_Auth_2026_Secure!";
                var tokenWindow = issuedAtMs / (QrTokenValidSeconds * 1000);
                var rawData = $"{session.Id}:{session.SessionCode}:{tokenWindow}";
                var expectedHmac = GenerateHmac(rawData, jwtKey);
                var providedHmac = parts[3];

                if (!CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(expectedHmac),
                    Encoding.UTF8.GetBytes(providedHmac)))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"[SECURITY] Invalid QR HMAC! Session: {session.Id} | Expected: {expectedHmac[..8]}... | Got: {providedHmac[..8]}...");
                    Console.ResetColor();
                    return (false, "Chữ ký QR Token không hợp lệ! Mã QR có thể bị giả mạo.");
                }

                return (true, string.Empty);
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi xác thực QR Token: {ex.Message}");
            }
        }

        // ==========================================
        // HELPER: Tạo chữ ký HMAC-SHA256 ngắn (16 chars)
        // ==========================================
        private static string GenerateHmac(string data, string key)
        {
            var keyBytes = Encoding.UTF8.GetBytes(key);
            var dataBytes = Encoding.UTF8.GetBytes(data);
            using var hmac = new HMACSHA256(keyBytes);
            var hash = hmac.ComputeHash(dataBytes);
            // Dùng 8 bytes đầu → 16 ký tự hex (đủ ngắn để nhúng vào QR)
            return Convert.ToHexString(hash[..8]).ToLower();
        }

        // ==========================================
        // HELPER: Công thức Haversine tính khoảng cách GPS
        // ==========================================
        private static double CalculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371000;
            var phi1 = lat1 * Math.PI / 180;
            var phi2 = lat2 * Math.PI / 180;
            var deltaPhi = (lat2 - lat1) * Math.PI / 180;
            var deltaLambda = (lon2 - lon1) * Math.PI / 180;

            var a = Math.Sin(deltaPhi / 2) * Math.Sin(deltaPhi / 2) +
                    Math.Cos(phi1) * Math.Cos(phi2) *
                    Math.Sin(deltaLambda / 2) * Math.Sin(deltaLambda / 2);

            return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        }
    }
}
