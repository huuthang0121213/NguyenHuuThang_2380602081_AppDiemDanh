namespace NguyenHuuThang_2380602081.API.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode);
    }
}
