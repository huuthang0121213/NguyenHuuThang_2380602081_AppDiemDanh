namespace NguyenHuuThang_2380602081.API.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode);
        Task<bool> SendAttendanceConfirmationAsync(string toEmail, string fullName, string studentCode, string courseName, string sessionTitle, DateTime checkInTime, double? latitude, double? longitude);
    }
}
