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
            var password = _configuration["Smtp:Password"];

            // Luôn ghi log ra Console để dễ kiểm thử và chấm bài
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("================================================================================");
            Console.WriteLine($"[EMAIL OTP NOTIFICATION] - {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            Console.WriteLine($"Gửi đến: {fullName} <{toEmail}>");
            Console.WriteLine($"MÃ XÁC THỰC OTP: >>> {otpCode} <<<");
            Console.WriteLine("Thời hạn hiệu lực: 5 phút | Giới hạn nhập sai: 5 lần");
            Console.WriteLine("================================================================================");
            Console.ResetColor();

            _logger.LogInformation("Đã tạo mã OTP {Otp} cho email {Email}", otpCode, toEmail);

            // Nếu chưa cấu hình username/password SMTP thì dừng lại ở log console (tiện cho chạy local/test offline)
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                _logger.LogWarning("Chưa cấu hình tài khoản SMTP thực tế trong appsettings.json. Mã OTP đã được in ra console.");
                return true;
            }

            try
            {
                using var client = new SmtpClient(host, port)
                {
                    EnableSsl = enableSsl,
                    Credentials = new NetworkCredential(username, password)
                };

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = $"[Điểm Danh Sinh Viên] Mã OTP xác minh đăng nhập: {otpCode}",
                    Body = $@"
                        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;'>
                            <h2 style='color: #1E3A8A; text-align: center;'>HỆ THỐNG ĐIỂM DANH SINH VIÊN</h2>
                            <p>Xin chào <strong>{fullName}</strong>,</p>
                            <p>Bạn (hoặc ai đó) vừa yêu cầu đăng nhập vào hệ thống điểm danh. Đây là mã xác thực OTP của bạn:</p>
                            <div style='background-color: #f0f4ff; text-align: center; padding: 16px; border-radius: 8px; margin: 20px 0;'>
                                <span style='font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #1E3A8A;'>{otpCode}</span>
                            </div>
                            <p style='color: #666; font-size: 13px;'>- Mã xác thực có hiệu lực trong vòng <strong>5 phút</strong>.<br/>
                            - Không chia sẻ mã này cho bất kỳ ai để đảm bảo an toàn tài khoản.</p>
                            <hr style='border: none; border-top: 1px solid #eee; margin: 20px 0;'/>
                            <p style='color: #999; font-size: 12px; text-align: center;'>Dự án Lập trình thiết bị di động - Nguyễn Hữu Thắng (2380602081)</p>
                        </div>",
                    IsBodyHtml = true
                };

                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
                _logger.LogInformation("Gửi email OTP đến {Email} qua SMTP thành công.", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gửi email OTP qua SMTP đến {Email}. Mã OTP vẫn có thể xem trên Console terminal.", toEmail);
                return false;
            }
        }
    }
}
