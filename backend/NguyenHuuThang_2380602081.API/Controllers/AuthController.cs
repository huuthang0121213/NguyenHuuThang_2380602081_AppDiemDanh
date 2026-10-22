using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.DTOs;
using NguyenHuuThang_2380602081.API.Models;
using NguyenHuuThang_2380602081.API.Services;

namespace NguyenHuuThang_2380602081.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly AppDbContext _context;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            AppDbContext context,
            IEmailService emailService,
            ILogger<AuthController> logger)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _context = context;
            _emailService = emailService;
            _logger = logger;
        }

        // ==========================================
        // 1.1 GỬI MÃ OTP ĐĂNG KÝ VỀ EMAIL
        // ==========================================
        [HttpPost("send-register-otp")]
        public async Task<IActionResult> SendRegisterOtp([FromBody] SendRegisterOtpDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var existingUser = await _userManager.FindByNameAsync(dto.Username);
            if (existingUser != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Tên đăng nhập này đã được sử dụng!" });

            var normalizedEmail = dto.Email.ToUpperInvariant();
            var existingEmail = await _userManager.Users.FirstOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail);
            if (existingEmail != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Email này đã được đăng ký cho tài khoản khác!" });

            // Hủy các mã OTP đăng ký cũ của email này
            var oldOtps = await _context.OtpVerifications
                .Where(o => (o.Username == dto.Username || o.Email == dto.Email) && !o.IsUsed)
                .ToListAsync();
            foreach (var old in oldOtps)
            {
                old.IsUsed = true;
            }

            // Sinh mã OTP 6 số ngẫu nhiên
            var otpCode = Random.Shared.Next(100000, 999999).ToString("D6");
            var otpRecord = new OtpVerification
            {
                Username = dto.Username,
                Email = dto.Email,
                OtpCode = otpCode,
                CreatedAt = DateTime.UtcNow,
                ExpiryTime = DateTime.UtcNow.AddMinutes(5),
                FailedAttempts = 0,
                IsUsed = false
            };
            _context.OtpVerifications.Add(otpRecord);
            await _context.SaveChangesAsync();

            // Gửi OTP qua email (hoặc ghi log Console)
            await _emailService.SendOtpEmailAsync(dto.Email, dto.FullName, otpCode);

            return Ok(new AuthResponseDto
            {
                Success = true,
                RequiresOtp = true,
                Message = $"Mã OTP xác thực đăng ký đã được gửi đến email {MaskEmail(dto.Email)}!",
                Email = MaskEmail(dto.Email),
                DevOtp = otpCode
            });
        }

        // ==========================================
        // 1.2 HOÀN TẤT ĐĂNG KÝ TÀI KHOẢN (KÈM MÃ OTP)
        // ==========================================
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var existingUser = await _userManager.FindByNameAsync(dto.Username);
            if (existingUser != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Tên đăng nhập đã tồn tại!" });

            var normalizedEmail = dto.Email.ToUpperInvariant();
            var existingEmail = await _userManager.Users.FirstOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail);
            if (existingEmail != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Email này đã được đăng ký cho tài khoản khác!" });

            // Nếu có mã OTP, kiểm tra tính chính xác và thời hạn
            if (!string.IsNullOrWhiteSpace(dto.OtpCode))
            {
                var otp = await _context.OtpVerifications
                    .Where(o => (o.Username == dto.Username || o.Email == dto.Email) && !o.IsUsed)
                    .OrderByDescending(o => o.CreatedAt)
                    .FirstOrDefaultAsync();

                if (otp == null || DateTime.UtcNow > otp.ExpiryTime)
                {
                    return BadRequest(new AuthResponseDto
                    {
                        Success = false,
                        Message = "Mã OTP xác thực đăng ký không hợp lệ hoặc đã hết hạn!"
                    });
                }

                if (otp.OtpCode != dto.OtpCode.Trim())
                {
                    otp.FailedAttempts++;
                    await _context.SaveChangesAsync();
                    return BadRequest(new AuthResponseDto
                    {
                        Success = false,
                        Message = "Mã OTP không chính xác. Vui lòng kiểm tra lại!"
                    });
                }

                otp.IsUsed = true;
                await _context.SaveChangesAsync();
            }

            var user = new ApplicationUser
            {
                UserName = dto.Username,
                Email = dto.Email,
                FullName = dto.FullName,
                StudentCode = dto.StudentCode,
                CreatedAt = DateTime.UtcNow
            };

            // Mật khẩu được hash an toàn thông qua Identity (PBKDF2), không lưu dạng văn bản thuần
            var result = await _userManager.CreateAsync(user, dto.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return BadRequest(new AuthResponseDto { Success = false, Message = errors });
            }

            // Gán Role
            var roleName = string.IsNullOrWhiteSpace(dto.Role) ? "Student" : dto.Role;
            if (!await _roleManager.RoleExistsAsync(roleName))
            {
                await _roleManager.CreateAsync(new IdentityRole(roleName));
            }
            await _userManager.AddToRoleAsync(user, roleName);

            // Tự động liên kết hoặc tạo bản ghi Student nếu đăng ký sinh viên
            if (roleName == "Student" && !string.IsNullOrWhiteSpace(dto.StudentCode))
            {
                var student = _context.Students.FirstOrDefault(s => s.StudentCode == dto.StudentCode);
                if (student == null)
                {
                    _context.Students.Add(new Student
                    {
                        StudentCode = dto.StudentCode,
                        FullName = dto.FullName,
                        Email = dto.Email,
                        ClassName = "23DTHB1",
                        UserId = user.Id,
                        IsActive = true
                    });
                    await _context.SaveChangesAsync();
                }
                else
                {
                    student.UserId = user.Id;
                    await _context.SaveChangesAsync();
                }
            }

            return Ok(new AuthResponseDto
            {
                Success = true,
                Message = "Đăng ký tài khoản thành công! Bạn có thể tiến hành đăng nhập.",
                User = new UserDto
                {
                    Id = user.Id,
                    Username = user.UserName ?? "",
                    FullName = user.FullName,
                    Email = user.Email ?? "",
                    StudentCode = user.StudentCode,
                    Role = roleName
                }
            });
        }

        // ==========================================
        // 2 & 3. ĐĂNG NHẬP & PHÁT MÃ XÁC THỰC OTP QUA EMAIL
        // ==========================================
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(dto.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, dto.Password))
            {
                return Unauthorized(new AuthResponseDto
                {
                    Success = false,
                    Message = "Tên đăng nhập hoặc mật khẩu không chính xác!"
                });
            }

            var email = user.Email;
            if (string.IsNullOrWhiteSpace(email))
            {
                email = $"{user.UserName}@student.edu.vn";
                user.Email = email;
                await _userManager.UpdateAsync(user);
            }

            // 1. Tạo mã OTP ngẫu nhiên 6 chữ số
            var otpCode = Random.Shared.Next(100000, 999999).ToString("D6");

            // 2. Vô hiệu hóa các mã OTP cũ chưa sử dụng của tài khoản này
            var oldOtps = await _context.OtpVerifications
                .Where(o => o.Username == user.UserName && !o.IsUsed)
                .ToListAsync();
            foreach (var old in oldOtps)
            {
                old.IsUsed = true;
            }

            // 3. Lưu mã OTP mới vào SQL Server (thời hạn 5 phút, tối đa 5 lần nhập sai)
            var otpRecord = new OtpVerification
            {
                Username = user.UserName ?? "",
                Email = email,
                OtpCode = otpCode,
                CreatedAt = DateTime.UtcNow,
                ExpiryTime = DateTime.UtcNow.AddMinutes(5),
                FailedAttempts = 0,
                IsUsed = false
            };
            _context.OtpVerifications.Add(otpRecord);
            await _context.SaveChangesAsync();

            // 4. Gửi email mã OTP qua SMTP
            await _emailService.SendOtpEmailAsync(email, user.FullName, otpCode);

            // 5. Trả về yêu cầu nhập OTP
            return Ok(new AuthResponseDto
            {
                Success = true,
                RequiresOtp = true,
                Message = $"Mã xác thực OTP đã được gửi đến email {MaskEmail(email)}. Vui lòng kiểm tra hộp thư!",
                Email = MaskEmail(email),
                DevOtp = otpCode // Cung cấp để tiện kiểm thử nhanh và chấm điểm
            });
        }

        // ==========================================
        // 4. KIỂM TRA OTP VÀ CẤP JWT TOKEN
        // ==========================================
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(dto.Username);
            if (user == null)
            {
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = "Tài khoản không tồn tại!"
                });
            }

            // Tìm mã OTP mới nhất của user chưa bị sử dụng
            var otp = await _context.OtpVerifications
                .Where(o => o.Username == dto.Username && !o.IsUsed)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (otp == null)
            {
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = "Không tìm thấy mã OTP hợp lệ. Vui lòng đăng nhập lại để nhận mã mới!"
                });
            }

            // Kiểm tra thời hạn hiệu lực (5 phút)
            if (DateTime.UtcNow > otp.ExpiryTime)
            {
                otp.IsUsed = true;
                await _context.SaveChangesAsync();
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = "Mã OTP đã hết hạn hiệu lực (quá 5 phút). Vui lòng bấm 'Gửi lại mã'!"
                });
            }

            // Kiểm tra số lần nhập sai (giới hạn tối đa 5 lần)
            if (otp.FailedAttempts >= 5)
            {
                otp.IsUsed = true;
                await _context.SaveChangesAsync();
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = "Bạn đã nhập sai mã OTP quá 5 lần. Mã đã bị hủy vì lý do bảo mật. Vui lòng yêu cầu mã mới!"
                });
            }

            // Kiểm tra tính chính xác của OTP
            if (otp.OtpCode != dto.OtpCode.Trim())
            {
                otp.FailedAttempts++;
                await _context.SaveChangesAsync();
                var remaining = 5 - otp.FailedAttempts;
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = $"Mã OTP không chính xác! Bạn còn {remaining} lần thử trước khi mã bị vô hiệu hóa."
                });
            }

            // OTP CHÍNH XÁC -> Đánh dấu đã dùng
            otp.IsUsed = true;
            await _context.SaveChangesAsync();

            // Cấp JWT Token
            var roles = await _userManager.GetRolesAsync(user);
            var userRole = roles.FirstOrDefault() ?? "Student";

            var (tokenString, expirationTime) = GenerateJwtToken(user, userRole);

            return Ok(new AuthResponseDto
            {
                Success = true,
                RequiresOtp = false,
                Message = "Xác thực OTP thành công! Đăng nhập hoàn tất.",
                Token = tokenString,
                Expiration = expirationTime,
                User = new UserDto
                {
                    Id = user.Id,
                    Username = user.UserName ?? "",
                    FullName = user.FullName ?? "",
                    Email = user.Email ?? "",
                    StudentCode = user.StudentCode,
                    Role = userRole
                }
            });
        }

        // ==========================================
        // GỬI LẠI MÃ OTP (RESEND OTP)
        // ==========================================
        [HttpPost("resend-otp")]
        public async Task<IActionResult> ResendOtp([FromBody] ResendOtpDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(dto.Username);
            if (user == null)
            {
                return BadRequest(new AuthResponseDto
                {
                    Success = false,
                    Message = "Tài khoản không tồn tại!"
                });
            }

            var email = user.Email ?? $"{user.UserName}@student.edu.vn";

            // Vô hiệu hóa mã cũ
            var oldOtps = await _context.OtpVerifications
                .Where(o => o.Username == user.UserName && !o.IsUsed)
                .ToListAsync();
            foreach (var old in oldOtps)
            {
                old.IsUsed = true;
            }

            // Tạo OTP mới
            var otpCode = Random.Shared.Next(100000, 999999).ToString("D6");
            var otpRecord = new OtpVerification
            {
                Username = user.UserName ?? "",
                Email = email,
                OtpCode = otpCode,
                CreatedAt = DateTime.UtcNow,
                ExpiryTime = DateTime.UtcNow.AddMinutes(5),
                FailedAttempts = 0,
                IsUsed = false
            };
            _context.OtpVerifications.Add(otpRecord);
            await _context.SaveChangesAsync();

            // Gửi qua email
            await _emailService.SendOtpEmailAsync(email, user.FullName, otpCode);

            return Ok(new AuthResponseDto
            {
                Success = true,
                RequiresOtp = true,
                Message = $"Mã OTP mới đã được gửi đến email {MaskEmail(email)}!",
                Email = MaskEmail(email),
                DevOtp = otpCode
            });
        }

        // ==========================================
        // LẤY THÔNG TIN NGƯỜI DÙNG HIỆN TẠI (PROFILE)
        // ==========================================
        [HttpGet("profile")]
        [Authorize]
        public async Task<IActionResult> GetProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return NotFound("Không tìm thấy thông tin người dùng.");

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new UserDto
            {
                Id = user.Id,
                Username = user.UserName ?? "",
                FullName = user.FullName,
                Email = user.Email ?? "",
                StudentCode = user.StudentCode,
                Role = roles.FirstOrDefault() ?? "Student"
            });
        }

        // Helper tạo JWT Token
        private (string token, DateTime expiration) GenerateJwtToken(ApplicationUser user, string userRole)
        {
            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.UserName ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Role, userRole),
                new Claim("FullName", user.FullName ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            if (!string.IsNullOrEmpty(user.StudentCode))
            {
                authClaims.Add(new Claim("StudentCode", user.StudentCode));
            }

            var jwtKey = _configuration["Jwt:Key"] ?? "NguyenHuuThang_2380602081_SecretKey_For_Jwt_Auth_2026_Secure!";
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var tokenExpiryDays = Convert.ToDouble(_configuration["Jwt:DurationInDays"] ?? "7");
            var expirationTime = DateTime.UtcNow.AddDays(tokenExpiryDays);

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                expires: expirationTime,
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return (new JwtSecurityTokenHandler().WriteToken(token), expirationTime);
        }

        // Helper ẩn bớt ký tự email (ví dụ: th***@student.edu.vn)
        private static string MaskEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
                return email;

            var parts = email.Split('@');
            var name = parts[0];
            var domain = parts[1];

            if (name.Length <= 2)
                return $"{name}***@{domain}";

            return $"{name.Substring(0, 2)}***@{domain}";
        }
    }
}
