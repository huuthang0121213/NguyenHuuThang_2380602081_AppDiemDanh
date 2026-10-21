# Thiết Kế Cơ Sở Dữ Liệu (Database Schema)

**Hệ quản trị CSDL:** Microsoft SQL Server  
**Tên Database:** `NguyenHuuThang_2380602081_DB`  
**Dự án:** Quản lý điểm danh sinh viên  
**Sinh viên:** Nguyễn Hữu Thắng - MSSV: 2380602081  

---

## 1. Sơ đồ các bảng trong CSDL (Tables)

### 1.1. Bảng `AspNetUsers` (Kế thừa từ IdentityUser)
Lưu trữ thông tin tài khoản đăng nhập của hệ thống.
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `nvarchar(450)` | Primary Key | Mã định danh duy nhất (GUID) |
| `UserName` | `nvarchar(256)` | Unique, Not Null | Tên đăng nhập |
| `Email` | `nvarchar(256)` | Unique | Địa chỉ email |
| `FullName` | `nvarchar(150)` | Not Null | Họ và tên đầy đủ |
| `StudentCode` | `nvarchar(50)` | Nullable | Mã số sinh viên (nếu là tài khoản sinh viên) |
| `PasswordHash` | `nvarchar(max)` | Not Null | Mật khẩu đã được mã hóa băm (PBKDF2) |
| `PhoneNumber` | `nvarchar(50)` | Nullable | Số điện thoại |
| `CreatedAt` | `datetime2` | Default GETDATE() | Thời gian tạo tài khoản |

### 1.2. Bảng `AspNetRoles` (Kế thừa từ IdentityRole)
Lưu danh sách các vai trò (quyền hạn) trong hệ thống:
- `Admin`: Quản trị toàn quyền
- `Teacher`: Giảng viên tạo lớp học, tạo buổi điểm danh
- `Student`: Sinh viên xem lịch học, quét mã điểm danh

### 1.3. Bảng `Students` (Bảng Sinh viên)
Lưu trữ hồ sơ học tập và thông tin quản lý sinh viên.
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `int` | Primary Key, Identity(1,1) | Mã tự tăng |
| `StudentCode` | `nvarchar(50)` | Unique, Not Null | Mã số sinh viên (ví dụ: 2380602081) |
| `FullName` | `nvarchar(150)` | Not Null | Họ và tên |
| `Email` | `nvarchar(256)` | Not Null | Email sinh viên |
| `PhoneNumber` | `nvarchar(50)` | Nullable | Số điện thoại |
| `ClassName` | `nvarchar(100)` | Not Null | Tên lớp sinh hoạt (ví dụ: 23DTHB1) |
| `UserId` | `nvarchar(450)` | FK -> AspNetUsers(Id), Nullable | Liên kết tài khoản đăng nhập |
| `IsActive` | `bit` | Default 1 | Trạng thái đang học |
| `CreatedAt` | `datetime2` | Default GETDATE() | Ngày tạo bản ghi |

### 1.4. Bảng `Courses` (Môn học / Học phần)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `int` | Primary Key, Identity(1,1) | Mã môn học |
| `CourseCode` | `nvarchar(50)` | Unique, Not Null | Mã môn (ví dụ: LTDD-01) |
| `CourseName` | `nvarchar(200)` | Not Null | Tên môn (Lập trình thiết bị di động) |
| `Credits` | `int` | Default 3 | Số tín chỉ |
| `TeacherId` | `nvarchar(450)` | FK -> AspNetUsers(Id) | Giảng viên phụ trách |

### 1.5. Bảng `AttendanceSessions` (Phiên điểm danh)
Lưu thông tin mỗi buổi học cần điểm danh.
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `int` | Primary Key, Identity(1,1) | Mã phiên |
| `CourseId` | `int` | FK -> Courses(Id) | Thuộc môn học nào |
| `Title` | `nvarchar(200)` | Not Null | Tiêu đề buổi học |
| `SessionCode` | `nvarchar(100)` | Not Null | Mã phiên (để tạo QR code) |
| `StartTime` | `datetime2` | Not Null | Giờ bắt đầu điểm danh |
| `EndTime` | `datetime2` | Not Null | Giờ kết thúc điểm danh |
| `Latitude` | `float` | Nullable | Tọa độ vĩ độ phòng học |
| `Longitude` | `float` | Nullable | Tọa độ kinh độ phòng học |
| `AllowedRadiusMeters` | `int` | Default 50 | Bán kính cho phép (mét) |
| `IsClosed` | `bit` | Default 0 | Trạng thái đóng phiên |

### 1.6. Bảng `AttendanceRecords` (Chi tiết điểm danh sinh viên)
Ghi nhận kết quả điểm danh của từng sinh viên trong mỗi phiên.
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `int` | Primary Key, Identity(1,1) | Mã bản ghi |
| `SessionId` | `int` | FK -> AttendanceSessions(Id) | Buổi học nào |
| `StudentId` | `int` | FK -> Students(Id) | Sinh viên nào |
| `CheckInTime` | `datetime2` | Default GETDATE() | Thời gian điểm danh |
| `Status` | `nvarchar(50)` | Not Null (Present/Late/Absent)| Trạng thái (Có mặt / Trễ / Vắng) |
| `CheckInMethod` | `nvarchar(50)` | (QRCode / Manual / GPS) | Phương thức điểm danh |
| `Latitude` | `float` | Nullable | Tọa độ lúc sinh viên bấm điểm danh |
| `Longitude` | `float` | Nullable | Tọa độ kinh độ lúc bấm điểm danh |
| `Note` | `nvarchar(500)` | Nullable | Ghi chú thêm |

---

## 2. Mối quan hệ giữa các bảng (Entity Relationships)
- `AspNetUsers` 1 -- 0..1 `Students`: Mỗi sinh viên có thể liên kết với một tài khoản người dùng.
- `AspNetUsers` (Teacher) 1 -- N `Courses`: Một giảng viên phụ trách nhiều môn học.
- `Courses` 1 -- N `AttendanceSessions`: Một môn học có nhiều buổi học/phiên điểm danh.
- `AttendanceSessions` 1 -- N `AttendanceRecords`: Mỗi phiên điểm danh có nhiều bản ghi của các sinh viên.
- `Students` 1 -- N `AttendanceRecords`: Một sinh viên có nhiều bản ghi điểm danh qua các buổi.
