using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenHuuThang_2380602081.API.Data;
using NguyenHuuThang_2380602081.API.DTOs;
using NguyenHuuThang_2380602081.API.Models;

namespace NguyenHuuThang_2380602081.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StudentsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StudentsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/students?search=...
        [HttpGet]
        public async Task<ActionResult<IEnumerable<StudentDto>>> GetStudents([FromQuery] string? search)
        {
            var query = _context.Students.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                query = query.Where(s => s.FullName.ToLower().Contains(term) ||
                                         s.StudentCode.ToLower().Contains(term) ||
                                         s.ClassName.ToLower().Contains(term));
            }

            var students = await query
                .OrderBy(s => s.StudentCode)
                .Select(s => new StudentDto
                {
                    Id = s.Id,
                    StudentCode = s.StudentCode,
                    FullName = s.FullName,
                    Email = s.Email,
                    PhoneNumber = s.PhoneNumber,
                    ClassName = s.ClassName,
                    IsActive = s.IsActive,
                    CreatedAt = s.CreatedAt
                })
                .ToListAsync();

            return Ok(students);
        }

        // GET: api/students/5
        [HttpGet("{id}")]
        public async Task<ActionResult<StudentDto>> GetStudent(int id)
        {
            var student = await _context.Students.FindAsync(id);

            if (student == null)
            {
                return NotFound(new { message = $"Không tìm thấy sinh viên có ID {id}." });
            }

            return Ok(new StudentDto
            {
                Id = student.Id,
                StudentCode = student.StudentCode,
                FullName = student.FullName,
                Email = student.Email,
                PhoneNumber = student.PhoneNumber,
                ClassName = student.ClassName,
                IsActive = student.IsActive,
                CreatedAt = student.CreatedAt
            });
        }

        // POST: api/students
        [HttpPost]
        public async Task<ActionResult<StudentDto>> CreateStudent([FromBody] CreateStudentDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Check if student code already exists
            if (await _context.Students.AnyAsync(s => s.StudentCode == dto.StudentCode))
            {
                return BadRequest(new { message = "Mã số sinh viên này đã tồn tại trong hệ thống!" });
            }

            var student = new Student
            {
                StudentCode = dto.StudentCode.Trim(),
                FullName = dto.FullName.Trim(),
                Email = dto.Email.Trim(),
                PhoneNumber = dto.PhoneNumber?.Trim(),
                ClassName = dto.ClassName.Trim(),
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Students.Add(student);
            await _context.SaveChangesAsync();

            var result = new StudentDto
            {
                Id = student.Id,
                StudentCode = student.StudentCode,
                FullName = student.FullName,
                Email = student.Email,
                PhoneNumber = student.PhoneNumber,
                ClassName = student.ClassName,
                IsActive = student.IsActive,
                CreatedAt = student.CreatedAt
            };

            return CreatedAtAction(nameof(GetStudent), new { id = student.Id }, result);
        }

        // PUT: api/students/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateStudent(int id, [FromBody] UpdateStudentDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var student = await _context.Students.FindAsync(id);
            if (student == null)
            {
                return NotFound(new { message = $"Không tìm thấy sinh viên có ID {id}." });
            }

            student.FullName = dto.FullName.Trim();
            student.Email = dto.Email.Trim();
            student.PhoneNumber = dto.PhoneNumber?.Trim();
            student.ClassName = dto.ClassName.Trim();
            student.IsActive = dto.IsActive;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật thông tin sinh viên thành công!" });
        }

        // DELETE: api/students/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var student = await _context.Students.FindAsync(id);
            if (student == null)
            {
                return NotFound(new { message = $"Không tìm thấy sinh viên có ID {id}." });
            }

            _context.Students.Remove(student);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa sinh viên thành công!" });
        }
    }
}
