using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.Models;
using NguyenHuuThang_2380602081.API.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Add Controllers & Endpoints
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Register Email Service
builder.Services.AddScoped<IEmailService, EmailService>();

// 2. Configure Swagger with JWT Bearer Support
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Student Attendance API - NguyenHuuThang_2380602081",
        Version = "v1",
        Description = "ASP.NET Core Web API phục vụ ứng dụng điểm danh sinh viên trên di động Flutter"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập JWT Token theo định dạng: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 3. Configure Database (SQL Server)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// 4. Configure ASP.NET Core Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
    options.User.RequireUniqueEmail = false;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// 5. Configure JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "NguyenHuuThang_2380602081_SecretKey_For_Jwt_Auth_2026_Secure!";
var key = Encoding.UTF8.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ClockSkew = TimeSpan.Zero
    };
});

// 6. Configure CORS (Cho phép Mobile Flutter và Web truy cập)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// 7. Seed Initial Roles and Admin User automatically
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<AppDbContext>();
        // Tự động áp dụng Migration và cập nhật bảng CSDL nếu chưa có
        context.Database.Migrate();

        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

        string[] roleNames = { "Admin", "Teacher", "Student" };
        foreach (var roleName in roleNames)
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
            }
        }

        // Tạo tài khoản Admin mặc định
        var adminUser = await userManager.FindByNameAsync("admin");
        if (adminUser == null)
        {
            var admin = new ApplicationUser
            {
                UserName = "admin",
                Email = "admin@attendance.edu.vn",
                FullName = "Administrator",
                CreatedAt = DateTime.UtcNow
            };
            var result = await userManager.CreateAsync(admin, "Admin@123456");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, "Admin");
            }
        }

        // Tạo tài khoản sinh viên mẫu Nguyễn Hữu Thắng
        var studentUser = await userManager.FindByNameAsync("2380602081");
        if (studentUser == null)
        {
            var student = new ApplicationUser
            {
                UserName = "2380602081",
                Email = "thang.2380602081@student.edu.vn",
                FullName = "Nguyễn Hữu Thắng",
                StudentCode = "2380602081",
                CreatedAt = DateTime.UtcNow
            };
            var result = await userManager.CreateAsync(student, "Thang@123456");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(student, "Student");

                // Thêm vào bảng Student nếu chưa có
                if (!context.Students.Any(s => s.StudentCode == "2380602081"))
                {
                    context.Students.Add(new Student
                    {
                        StudentCode = "2380602081",
                        FullName = "Nguyễn Hữu Thắng",
                        Email = "thang.2380602081@student.edu.vn",
                        PhoneNumber = "0987654321",
                        ClassName = "23DTHB1",
                        UserId = student.Id,
                        IsActive = true
                    });
                    await context.SaveChangesAsync();
                }
            }
        }
        else if (studentUser.Email != "huuthang0121213@gmail.com")
        {
            studentUser.Email = "huuthang0121213@gmail.com";
            await userManager.UpdateAsync(studentUser);
            var st = context.Students.FirstOrDefault(s => s.StudentCode == "2380602081");
            if (st != null)
            {
                st.Email = "huuthang0121213@gmail.com";
                await context.SaveChangesAsync();
            }
        }

        // Tạo môn học mẫu nếu chưa có
        if (!context.Courses.Any())
        {
            context.Courses.Add(new Course
            {
                CourseCode = "LTDD01",
                CourseName = "Lập trình thiết bị di động",
                Credits = 3
            });
            await context.SaveChangesAsync();
        }
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Lỗi xảy ra trong quá trình khởi tạo dữ liệu ban đầu.");
    }
}

// Configure HTTP request pipeline
if (app.Environment.IsDevelopment() || true)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "NguyenHuuThang_2380602081 API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
