using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.DTOs;
using NguyenHuuThang_2380602081.API.Models;

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

        public AuthController(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            AppDbContext context)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _context = context;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var existingUser = await _userManager.FindByNameAsync(dto.Username);
            if (existingUser != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Tên đăng nhập đã tồn tại!" });

            var existingEmail = await _userManager.FindByEmailAsync(dto.Email);
            if (existingEmail != null)
                return BadRequest(new AuthResponseDto { Success = false, Message = "Email đã được sử dụng!" });

            var user = new ApplicationUser
            {
                UserName = dto.Username,
                Email = dto.Email,
                FullName = dto.FullName,
                StudentCode = dto.StudentCode,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, dto.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return BadRequest(new AuthResponseDto { Success = false, Message = errors });
            }

            // Ensure role exists
            var roleName = string.IsNullOrWhiteSpace(dto.Role) ? "Student" : dto.Role;
            if (!await _roleManager.RoleExistsAsync(roleName))
            {
                await _roleManager.CreateAsync(new IdentityRole(roleName));
            }
            await _userManager.AddToRoleAsync(user, roleName);

            // If registering as a student and has student code, automatically link to or create Student record
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
                Message = "Đăng ký tài khoản thành công!",
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

            var roles = await _userManager.GetRolesAsync(user);
            var userRole = roles.FirstOrDefault() ?? "Student";

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

            var jwtKey = _configuration["Jwt:Key"] ?? "DefaultSuperSecretKey1234567890123456";
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

            return Ok(new AuthResponseDto
            {
                Success = true,
                Message = "Đăng nhập thành công!",
                Token = new JwtSecurityTokenHandler().WriteToken(token),
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
    }
}
