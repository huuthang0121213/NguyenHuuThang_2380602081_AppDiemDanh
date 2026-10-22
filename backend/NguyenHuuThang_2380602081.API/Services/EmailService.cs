using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace NguyenHuuThang_2380602081.API.Services
{
    /// <summary>
    /// EmailService sử dụng MailKit - hỗ trợ Gmail App Password và TLS hiện đại
    /// </summary>
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // ============================================================
        // GỬI EMAIL OTP XÁC THỰC ĐĂNG KÝ / ĐĂNG NHẬP
        // ============================================================
        public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode)
        {
            // Luôn log ra Console để kiểm thử và chấm điểm
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("╔══════════════════════════════════════════════════════════════════════════╗");
            Console.WriteLine($"║ [OTP EMAIL DISPATCH] - {DateTime.Now:dd/MM/yyyy HH:mm:ss}                           ║");
            Console.WriteLine($"║ Người nhận : {fullName.PadRight(55)} ║");
            Console.WriteLine($"║ Hộp thư   : {toEmail.PadRight(55)} ║");
            Console.WriteLine("║──────────────────────────────────────────────────────────────────────────║");
            Console.WriteLine($"║  MÃ XÁC THỰC OTP: >>>  {otpCode}  <<<                                  ║");
            Console.WriteLine("║  Hiệu lực: 5 phút | Giới hạn nhập sai: 5 lần                             ║");
            Console.WriteLine("╚══════════════════════════════════════════════════════════════════════════╝");
            Console.ResetColor();

            _logger.LogInformation("Đã tạo mã OTP {Otp} cho email {Email}", otpCode, toEmail);

            var (host, port, username, password, senderEmail, senderName) = GetSmtpConfig();

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                _logger.LogWarning("Chưa cấu hình SMTP. Mã OTP đã hiển thị ở Console Terminal.");
                return true; // Trả về true để flow tiếp tục bình thường
            }

            var htmlBody = BuildOtpEmailHtml(fullName, otpCode);

            return await SendWithMailKitAsync(
                host, port, username, password,
                senderEmail, senderName,
                toEmail,
                $"[{otpCode}] Mã xác thực OTP - Hệ thống Điểm danh Sinh viên",
                htmlBody
            );
        }

        // ============================================================
        // GỬI EMAIL XÁC NHẬN ĐIỂM DANH THÀNH CÔNG
        // ============================================================
        public async Task<bool> SendAttendanceConfirmationAsync(
            string toEmail,
            string fullName,
            string studentCode,
            string courseName,
            string sessionTitle,
            DateTime checkInTime,
            double? latitude,
            double? longitude)
        {
            var checkInLocal = checkInTime.ToLocalTime();
            var gpsInfo = (latitude.HasValue && longitude.HasValue)
                ? $"{latitude:F4}°N, {longitude:F4}°E"
                : "Không xác định";

            // Log Console
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("╔══════════════════════════════════════════════════════════════════════════╗");
            Console.WriteLine($"║ [ĐIỂM DANH - EMAIL XÁC NHẬN] {DateTime.Now:dd/MM/yyyy HH:mm:ss}                   ║");
            Console.WriteLine($"║ Sinh viên : {fullName.PadRight(56)} ║");
            Console.WriteLine($"║ MSSV      : {studentCode.PadRight(56)} ║");
            Console.WriteLine($"║ Hộp thư   : {toEmail.PadRight(56)} ║");
            Console.WriteLine($"║ Môn học   : {courseName.PadRight(56)} ║");
            Console.WriteLine($"║ Thời điểm : {checkInLocal:dd/MM/yyyy HH:mm:ss}                                   ║");
            Console.WriteLine($"║ GPS       : {gpsInfo.PadRight(56)} ║");
            Console.WriteLine("╚══════════════════════════════════════════════════════════════════════════╝");
            Console.ResetColor();

            _logger.LogInformation("Gửi email xác nhận điểm danh đến {Email} - {StudentCode}", toEmail, studentCode);

            var (host, port, username, password, senderEmail, senderName) = GetSmtpConfig();

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                _logger.LogWarning("Chưa cấu hình SMTP. Email xác nhận điểm danh đã hiển thị ở Console.");
                return true;
            }

            var htmlBody = BuildAttendanceEmailHtml(fullName, studentCode, courseName, sessionTitle, checkInLocal, gpsInfo);

            return await SendWithMailKitAsync(
                host, port, username, password,
                senderEmail, senderName,
                toEmail,
                $"[ĐIỂM DANH] {courseName} - {checkInLocal:dd/MM HH:mm} - {fullName}",
                htmlBody
            );
        }

        // ============================================================
        // HELPER: Gửi email bằng MailKit (hỗ trợ Gmail STARTTLS/TLS)
        // ============================================================
        private async Task<bool> SendWithMailKitAsync(
            string host, int port,
            string username, string password,
            string senderEmail, string senderName,
            string toEmail, string subject, string htmlBody)
        {
            try
            {
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(senderName, senderEmail));
                message.To.Add(MailboxAddress.Parse(toEmail));
                message.Subject = subject;

                var builder = new BodyBuilder { HtmlBody = htmlBody };
                message.Body = builder.ToMessageBody();

                using var client = new SmtpClient();

                // Kết nối với SecureSocketOptions tự động (tương thích Gmail port 587 STARTTLS)
                var secureOption = port == 465
                    ? SecureSocketOptions.SslOnConnect
                    : SecureSocketOptions.StartTls;

                await client.ConnectAsync(host, port, secureOption);
                await client.AuthenticateAsync(username, password);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                _logger.LogInformation("✅ Gửi email MailKit đến {Email} thành công.", toEmail);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"✅ [SMTP] Email đã gửi thành công đến: {toEmail}");
                Console.ResetColor();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Lỗi MailKit khi gửi email đến {Email}: {Message}", toEmail, ex.Message);
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"❌ [SMTP ERROR] Không thể gửi email đến {toEmail}");
                Console.WriteLine($"   Lỗi: {ex.Message}");
                Console.ResetColor();
                return false;
            }
        }

        // ============================================================
        // HELPER: Lấy cấu hình SMTP từ appsettings.json
        // ============================================================
        private (string host, int port, string username, string password, string senderEmail, string senderName) GetSmtpConfig()
        {
            var host = _configuration["Smtp:Host"] ?? "smtp.gmail.com";
            var port = int.TryParse(_configuration["Smtp:Port"], out var p) ? p : 587;
            var senderEmail = _configuration["Smtp:SenderEmail"] ?? "no-reply@attendance.edu.vn";
            var senderName = _configuration["Smtp:SenderName"] ?? "Hệ Thống Điểm Danh Sinh Viên";
            var username = _configuration["Smtp:Username"] ?? string.Empty;
            var rawPassword = _configuration["Smtp:Password"] ?? string.Empty;
            var password = rawPassword.Replace(" ", "").Trim();
            return (host, port, username, password, senderEmail, senderName);
        }

        // ============================================================
        // HTML TEMPLATE: Email OTP
        // ============================================================
        private static string BuildOtpEmailHtml(string fullName, string otpCode) => $@"<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Mã Xác Thực OTP</title>
</head>
<body style='margin: 0; padding: 0; background-color: #F1F5F9; font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, Helvetica, Arial, sans-serif;'>
    <table role='presentation' width='100%' cellspacing='0' cellpadding='0' style='background-color: #F1F5F9; padding: 30px 15px;'>
        <tr>
            <td align='center'>
                <table role='presentation' width='100%' style='max-width: 540px; background-color: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.06);'>
                    <!-- Header -->
                    <tr>
                        <td style='background: linear-gradient(135deg, #1E3A8A 0%, #2563EB 100%); padding: 36px 30px; text-align: center;'>
                            <div style='background-color: rgba(255,255,255,0.15); width: 64px; height: 64px; margin: 0 auto 16px; border-radius: 50%; line-height: 64px;'>
                                <span style='font-size: 32px;'>🎓</span>
                            </div>
                            <h1 style='color: #FFFFFF; margin: 0; font-size: 22px; font-weight: 700; letter-spacing: 0.5px;'>HỆ THỐNG ĐIỂM DANH SINH VIÊN</h1>
                            <p style='color: #DBEAFE; margin: 6px 0 0; font-size: 13px;'>Bảo mật danh tính & Xác thực OTP qua Email</p>
                        </td>
                    </tr>
                    <!-- Content -->
                    <tr>
                        <td style='padding: 32px 30px;'>
                            <p style='font-size: 15px; color: #334155; margin: 0 0 16px;'>Xin chào <strong style='color: #1E3A8A;'>{fullName}</strong>,</p>
                            <p style='font-size: 14px; color: #64748B; line-height: 1.6; margin: 0 0 24px;'>
                                Bạn vừa thực hiện thao tác đăng ký hoặc đăng nhập vào hệ thống điểm danh. Vui lòng sử dụng mã xác thực (OTP) dưới đây để hoàn tất:
                            </p>
                            
                            <!-- OTP Box -->
                            <div style='background: linear-gradient(135deg, #EFF6FF 0%, #DBEAFE 100%); border: 2px dashed #3B82F6; border-radius: 14px; padding: 22px; text-align: center; margin: 0 0 24px;'>
                                <div style='font-size: 12px; font-weight: 600; text-transform: uppercase; color: #1E40AF; letter-spacing: 1.5px; margin-bottom: 8px;'>MÃ XÁC THỰC CỦA BẠN</div>
                                <div style='font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #1E3A8A; font-family: Courier New, monospace;'>{otpCode}</div>
                                <div style='font-size: 12px; color: #64748B; margin-top: 8px;'>⏱ Hiệu lực trong <strong>5 phút</strong> · Tối đa 5 lần thử</div>
                            </div>

                            <!-- Security Notes -->
                            <div style='background-color: #FFFBEB; border-left: 4px solid #F59E0B; padding: 12px 14px; border-radius: 6px; margin: 0 0 24px;'>
                                <p style='margin: 0; font-size: 13px; color: #92400E; line-height: 1.5;'>
                                    ⚠️ <strong>Lưu ý bảo mật:</strong> Không chia sẻ mã OTP này cho bất kỳ ai, kể cả cán bộ quản trị. Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.
                                </p>
                            </div>

                            <p style='font-size: 13px; color: #94A3B8; margin: 0; line-height: 1.5;'>
                                Trân trọng,<br/>
                                <strong>Ban Quản Trị Hệ Thống Điểm Danh Sinh Viên</strong>
                            </p>
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td style='background-color: #F8FAFC; padding: 20px 30px; text-align: center; border-top: 1px solid #E2E8F0;'>
                            <p style='margin: 0; font-size: 12px; color: #94A3B8;'>
                                Sinh viên thực hiện: <strong>Nguyễn Hữu Thắng</strong> · MSSV: <strong>2380602081</strong><br/>
                                Môn học: Lập trình thiết bị di động
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>";

        // ============================================================
        // HTML TEMPLATE: Email xác nhận điểm danh
        // ============================================================
        private static string BuildAttendanceEmailHtml(
            string fullName, string studentCode, string courseName,
            string sessionTitle, DateTime checkInLocal, string gpsInfo) => $@"<!DOCTYPE html>
<html lang='vi'>
<head><meta charset='UTF-8'><title>Xác nhận Điểm danh</title></head>
<body style='margin:0;padding:0;background-color:#F0FDF4;font-family:-apple-system,BlinkMacSystemFont,""Segoe UI"",Roboto,sans-serif;'>
<table width='100%' cellspacing='0' cellpadding='0' style='background-color:#F0FDF4;padding:30px 15px;'>
<tr><td align='center'>
<table width='100%' style='max-width:560px;background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);'>
<tr><td style='background:linear-gradient(135deg,#065F46 0%,#10B981 100%);padding:36px 30px;text-align:center;'>
<span style='font-size:48px;'>✅</span>
<h1 style='color:#FFF;margin:12px 0 0;font-size:24px;font-weight:700;'>ĐIỂM DANH THÀNH CÔNG</h1>
<p style='color:#A7F3D0;margin:6px 0 0;font-size:13px;'>Hệ thống đã ghi nhận sự có mặt của bạn</p>
</td></tr>
<tr><td style='padding:32px 30px;'>
<p style='font-size:15px;color:#334155;margin:0 0 16px;'>Xin chào <strong style='color:#065F46;'>{fullName}</strong>,</p>
<p style='font-size:14px;color:#64748B;line-height:1.6;margin:0 0 24px;'>Hệ thống đã xác nhận điểm danh qua <strong>QR Code động + Nhận diện khuôn mặt + GPS</strong>. Chi tiết:</p>
<table width='100%' cellspacing='0' cellpadding='0' style='border-radius:12px;overflow:hidden;border:1px solid #D1FAE5;margin:0 0 24px;'>
<tr style='background:#ECFDF5;'><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;width:36%;'>MSSV</td><td style='padding:11px 16px;font-size:14px;color:#1E293B;font-weight:600;'>{studentCode}</td></tr>
<tr><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;'>Họ và tên</td><td style='padding:11px 16px;font-size:14px;color:#1E293B;'>{fullName}</td></tr>
<tr style='background:#ECFDF5;'><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;'>Môn học</td><td style='padding:11px 16px;font-size:14px;color:#1E293B;font-weight:600;'>{courseName}</td></tr>
<tr><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;'>Phiên học</td><td style='padding:11px 16px;font-size:14px;color:#1E293B;'>{sessionTitle}</td></tr>
<tr style='background:#ECFDF5;'><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;'>Thời điểm</td><td style='padding:11px 16px;font-size:14px;color:#1E293B;font-weight:600;'>{checkInLocal:dd/MM/yyyy HH:mm:ss}</td></tr>
<tr><td style='padding:11px 16px;font-size:12px;color:#065F46;font-weight:700;text-transform:uppercase;'>Vị trí GPS</td><td style='padding:11px 16px;font-size:13px;color:#475569;'>{gpsInfo}</td></tr>
</table>
<div style='background:linear-gradient(135deg,#EFF6FF 0%,#ECFDF5 100%);border-radius:12px;padding:16px;margin:0 0 20px;'>
<p style='margin:0 0 10px;font-size:12px;color:#374151;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;'>🔒 Lớp bảo mật đã xác thực:</p>
<p style='margin:4px 0;font-size:13px;color:#059669;'>✅ &nbsp; QR Code động (hết hạn 60 giây, chống chụp ảnh QR chia sẻ)</p>
<p style='margin:4px 0;font-size:13px;color:#059669;'>✅ &nbsp; Nhận diện khuôn mặt trực tiếp (chỉ Camera, không dùng ảnh có sẵn)</p>
<p style='margin:4px 0;font-size:13px;color:#059669;'>✅ &nbsp; Xác minh vị trí GPS trong phạm vi phòng học</p>
<p style='margin:4px 0;font-size:13px;color:#059669;'>✅ &nbsp; Liên kết thiết bị (1 tài khoản / 1 thiết bị)</p>
</div>
<div style='background:#FFFBEB;border-left:4px solid #F59E0B;padding:12px 14px;border-radius:6px;'>
<p style='margin:0;font-size:13px;color:#92400E;'>⚠️ Nếu bạn <strong>không thực hiện</strong> điểm danh này, hãy liên hệ ngay với giảng viên.</p>
</div>
</td></tr>
<tr><td style='background:#F8FAFC;padding:16px 30px;text-align:center;border-top:1px solid #E2E8F0;'>
<p style='margin:0;font-size:11px;color:#94A3B8;'>CheckIn Pro · Nguyễn Hữu Thắng · MSSV: 2380602081 · HUTECH 2026</p>
</td></tr>
</table></td></tr></table>
</body></html>";
    }
}
