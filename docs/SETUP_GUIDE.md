# Hướng Dẫn Cài Đặt Và Chạy Ứng Dụng (Setup Guide)

**Dự án:** Hệ thống Điểm danh Sinh viên  
**Sinh viên:** Nguyễn Hữu Thắng - MSSV: 2380602081  

---

## 1. Yêu cầu môi trường (Prerequisites)
- **Hệ điều hành:** Windows 10/11
- **.NET SDK:** Phiên bản 8.0 trở lên (Kiểm tra: `dotnet --version`)
- **Visual Studio 2022:** Có cài gói *ASP.NET and web development*
- **Microsoft SQL Server:** Phiên bản SQL Server Express hoặc MSSQLSERVER (Đang chạy local)
- **Flutter SDK:** Phiên bản 3.x trở lên (Kiểm tra: `flutter --version`)
- **Android Studio / VS Code:** Có cài Flutter & Dart extension, Android SDK và máy ảo Android Emulator

---

## 2. Thiết lập Backend (ASP.NET Core Web API)

### Bước 2.1: Mở Solution trong Visual Studio
1. Điều hướng đến thư mục: `backend/`
2. Nhấp đúp chuột mở file: `NguyenHuuThang_2380602081.sln`
3. Visual Studio sẽ tự động tải các gói NuGet (Restore packages).

### Bước 2.2: Cấu hình chuỗi kết nối SQL Server
Mở file `NguyenHuuThang_2380602081.API/appsettings.json`:
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=DESKTOP-ELMNPUO;Database=NguyenHuuThang_2380602081_DB;Trusted_Connection=True;TrustServerCertificate=True"
}
```
> **Lưu ý:** Nếu tên máy của bạn khác `DESKTOP-ELMNPUO`, bạn có thể thay bằng `Server=localhost` hoặc `Server=.` hoặc tên instance SQL Server của bạn (ví dụ `Server=.\\SQLEXPRESS`).

### Bước 2.3: Tạo CSDL bằng Migration
Mở **Terminal** tại thư mục `backend/NguyenHuuThang_2380602081.API/` và gõ:
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```
Lệnh trên sẽ tự động kết nối SQL Server và tạo Database `NguyenHuuThang_2380602081_DB` với đầy đủ các bảng Identity, Students, Courses, AttendanceSessions, AttendanceRecords.

### Bước 2.4: Chạy Backend
- Trong Visual Studio: Chọn profile chạy **http** (cổng 5000) hoặc **https** (cổng 7001), nhấn `F5` hoặc nút `Start`.
- Hoặc chạy bằng CLI:
  ```bash
  cd backend/NguyenHuuThang_2380602081.API
  dotnet run --launch-profile http
  ```
- Kiểm tra trên trình duyệt: Truy cập `http://localhost:5000/swagger` để xem giao diện Swagger UI kiểm thử tất cả các API.

---

## 3. Thiết lập Mobile App (Flutter)

### Bước 3.1: Mở dự án Mobile
- Mở Android Studio hoặc VS Code -> Chọn **Open Folder** -> Trỏ đến thư mục `mobile/`.

### Bước 3.2: Cài đặt thư viện Dart
Chạy lệnh trong Terminal tại thư mục `mobile/`:
```bash
flutter pub get
```

### Bước 3.3: Cấu hình file môi trường `.env`
Tạo file `.env` tại thư mục gốc của `mobile/` (dựa trên mẫu `.env.example`):
```env
# Dành cho máy ảo Android Emulator kết nối vào máy tính host:
API_BASE_URL=http://10.0.2.2:5000/api

# Dành cho điện thoại thật cắm cáp / cùng mạng Wi-Fi:
# API_BASE_URL=http://192.168.1.15:5000/api

# Dành cho Flutter Web hoặc Windows Desktop:
# API_BASE_URL=http://localhost:5000/api
```

### Bước 3.4: Chạy ứng dụng trên máy ảo hoặc điện thoại
1. Bật máy ảo Android Emulator (Pixel, Samsung...) trong Android Studio.
2. Tại thư mục `mobile/`, gõ:
   ```bash
   flutter run
   ```

---

## 4. Những lưu ý quan trọng khi kết nối API từ Mobile

### 4.1. Tại sao dùng `http://10.0.2.2` thay vì `http://localhost`?
- Trên Android Emulator, `localhost` trỏ về chính bên trong máy ảo, không phải máy tính đang chạy backend.
- Địa chỉ IP `10.0.2.2` là alias đặc biệt do Google thiết kế để máy ảo Android truy cập trực tiếp vào `localhost` của máy host tính.

### 4.2. Cho phép kết nối HTTP ClearText trên Android
Trong `android/app/src/main/AndroidManifest.xml`, thuộc tính sau đã được thêm vào thẻ `<application>`:
```xml
android:usesCleartextTraffic="true"
```
Và quyền truy cập mạng Internet:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
Điều này giúp ứng dụng không bị chặn khi gọi API nội bộ bằng giao thức `http://` trong quá trình học tập và kiểm thử.
