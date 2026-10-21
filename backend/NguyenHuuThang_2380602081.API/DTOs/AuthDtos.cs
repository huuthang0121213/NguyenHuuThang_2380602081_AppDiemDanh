using System.ComponentModel.DataAnnotations;

namespace NguyenHuuThang_2380602081.API.DTOs
{
    public class RegisterDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        public string? StudentCode { get; set; }

        public string Role { get; set; } = "Student"; // Admin, Teacher, Student

        public string? OtpCode { get; set; }
    }

    public class SendRegisterOtpDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;
    }

    public class LoginDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class AuthResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? Token { get; set; }
        public DateTime? Expiration { get; set; }
        public UserDto? User { get; set; }
        public bool RequiresOtp { get; set; } = false;
        public string? Email { get; set; }
        public string? DevOtp { get; set; }
    }

    public class VerifyOtpDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(6, MinimumLength = 6, ErrorMessage = "Mã OTP phải có đúng 6 chữ số.")]
        public string OtpCode { get; set; } = string.Empty;
    }

    public class ResendOtpDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;
    }

    public class UserDto
    {
        public string Id { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? StudentCode { get; set; }
        public string Role { get; set; } = string.Empty;
    }
}
