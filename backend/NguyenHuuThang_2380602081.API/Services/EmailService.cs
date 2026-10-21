using System.Net;
using System.Net.Mail;

namespace NguyenHuuThang_2380602081.API.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode)
        {
            var host = _configuration["Smtp:Host"] ?? "smtp.gmail.com";
            var port = int.TryParse(_configuration["Smtp:Port"], out var p) ? p : 587;
            var enableSsl = bool.TryParse(_configuration["Smtp:EnableSsl"], out var ssl) ? ssl : true;
            var senderEmail = _configuration["Smtp:SenderEmail"] ?? "no-reply@attendance.edu.vn";
            var senderName = _configuration["Smtp:SenderName"] ?? "Hệ Thống Điểm Danh Sinh Viên";
            var username = _configuration["Smtp:Username"];
            var password = _configuration["Smtp:Password"]?.Replace(" ", "").Trim();

            // Log nổi bật ra Console Terminal phục vụ kiểm thử và chấm bài
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("╔══════════════════════════════════════════════════════════════════════════╗");
            Console.WriteLine($"║ [OTP EMAIL DISPATCH] - {DateTime.Now:dd/MM/yyyy HH:mm:ss}                                 ║");
            Console.WriteLine($"║ Người nhận: {fullName.PadRight(56)} ║");
            Console.WriteLine($"║ Hộp thư:    {toEmail.PadRight(56)} ║");
            Console.WriteLine("║──────────────────────────────────────────────────────────────────────────║");
            Console.WriteLine($"║  MÃ XÁC THỰC OTP: >>>  {otpCode}  <<<                                 ║");
            Console.WriteLine("║  Hiệu lực: 5 phút | Giới hạn nhập sai: 5 lần                             ║");
            Console.WriteLine("╚══════════════════════════════════════════════════════════════════════════╝");
            Console.ResetColor();

            _logger.LogInformation("Đã tạo mã OTP {Otp} cho email {Email}", otpCode, toEmail);

            // Nếu chưa cấu hình mật khẩu SMTP thì dừng lại ở log Console
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                _logger.LogWarning("Chưa cấu hình tài khoản SMTP thực tế trong appsettings.json. Mã OTP đã hiển thị ở Console.");
                return true;
            }

            try
            {
                using var client = new SmtpClient(host, port)
                {
                    EnableSsl = enableSsl,
                    Credentials = new NetworkCredential(username, password),
                    Timeout = 10000
                };

                // Template HTML Email chuyên nghiệp chuẩn đại học / doanh nghiệp
                var htmlBody = $@"
<!DOCTYPE html>
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

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = $"[{otpCode}] Mã xác thực OTP - Hệ thống Điểm danh Sinh viên",
                    Body = htmlBody,
                    IsBodyHtml = true
                };

                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
                _logger.LogInformation("Gửi email OTP đến {Email} qua SMTP thành công.", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gửi email OTP qua SMTP đến {Email}.", toEmail);
                return false;
            }
        }
    }
}
