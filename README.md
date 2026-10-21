# Hệ Thống Điểm Danh Sinh Viên (Student Attendance System)

**Sinh viên thực hiện:** Nguyễn Hữu Thắng  
**Mã số sinh viên (MSSV):** 2380602081  
**Môn học:** Lập trình thiết bị di động  

---

## 1. Giới thiệu dự án
Dự án được xây dựng theo mô hình Client - Server tách biệt:
- **Backend:** Xây dựng bằng **ASP.NET Core Web API** (.NET 8), Entity Framework Core, kết nối cơ sở dữ liệu **Microsoft SQL Server**, sử dụng ASP.NET Core Identity và JSON Web Token (JWT) để xác thực và phân quyền người dùng.
- **Mobile App:** Xây dựng bằng framework **Flutter** (Dart), kết nối và trao đổi dữ liệu với Backend thông qua các chuẩn RESTful API, quản lý URL qua `flutter_dotenv`, giải mã token bằng `jwt_decoder` và lưu trữ phiên đăng nhập bằng `shared_preferences`.

---

## 2. Cấu trúc thư mục dự án

```text
NguyenHuuThang_2380602081/
├── .gitignore                    # Bỏ qua file build, cache và biến môi trường bí mật
├── README.md                     # Hướng dẫn dự án và cách chạy
├── FUNCTIONS_STATUS.txt          # Danh sách checklist theo dõi tiến độ chức năng & API
│
├── docs/                         # Tài liệu thiết kế và đặc tả kỹ thuật
│   ├── API_DESIGN.md             # Đặc tả chi tiết các đầu API RESTful
│   ├── DATABASE_SCHEMA.md        # Thiết kế và lược đồ CSDL SQL Server
│   └── SETUP_GUIDE.md            # Hướng dẫn cài đặt chi tiết từng bước
│
├── backend/                      # Mở bằng Visual Studio
│   ├── NguyenHuuThang_2380602081.sln
│   └── NguyenHuuThang_2380602081.API/
│       ├── Controllers/          # API Controllers (Auth, Students, Attendance)
│       ├── Data/                 # DbContext và cấu hình Entity Framework
│       ├── Models/               # Các thực thể dữ liệu (User, Student, Attendance, ...)
│       ├── DTOs/                 # Data Transfer Objects
│       ├── appsettings.json      # Chuỗi kết nối CSDL và cấu hình JWT
│       └── Program.cs            # Dependency Injection, Middleware, Swagger, CORS
│
└── mobile/                       # Mở bằng Android Studio hoặc VS Code
    ├── pubspec.yaml              # Khai báo thư viện (http, dotenv, jwt_decoder, ...)
    ├── .env.example              # Mẫu cấu hình API Base URL
    ├── .env                      # File cấu hình môi trường thực tế (không commit Git)
    ├── android/                  # Cấu hình Android native (Internet permission, cleartext)
    └── lib/
        ├── config/               # Cấu hình API URL và hằng số
        ├── models/               # Model dữ liệu phía Mobile
        ├── services/             # Gọi API HTTP và xử lý Token
        ├── screens/              # Màn hình giao diện (Login, Register, Home, Attendance)
        └── main.dart             # Điểm bắt đầu ứng dụng Flutter
```

---

## 3. Công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện | Mục đích |
| :--- | :--- | :--- |
| **Backend** | ASP.NET Core Web API (.NET 8) | Xây dựng RESTful API |
| **ORM** | Entity Framework Core | Thao tác cơ sở dữ liệu Code-First |
| **Database** | Microsoft SQL Server | Lưu trữ dữ liệu hệ thống |
| **Security** | ASP.NET Core Identity & JWT | Xác thực, mã hóa mật khẩu, phân quyền |
| **Documentation** | Swagger / OpenAPI | Kiểm thử và tài liệu API trực quan |
| **Mobile** | Flutter & Dart | Ứng dụng di động đa nền tảng |
| **Networking** | `http` | Gửi request HTTP GET, POST, PUT, DELETE |
| **Config** | `flutter_dotenv` | Tách biệt cấu hình URL API khỏi mã nguồn |
| **Token Auth** | `jwt_decoder` | Giải mã thông tin người dùng và quyền từ JWT |
| **Local Storage** | `shared_preferences` | Lưu trữ Access Token để tự động đăng nhập |

---

## 4. Hướng dẫn chạy dự án

### 4.1. Khởi động Backend (ASP.NET Core Web API)
1. Mở file `backend/NguyenHuuThang_2380602081.sln` bằng **Visual Studio** (hoặc mở thư mục `backend/NguyenHuuThang_2380602081.API` trong VS Code).
2. Kiểm tra chuỗi kết nối trong `appsettings.json` cho phù hợp với máy của bạn:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=DESKTOP-ELMNPUO;Database=NguyenHuuThang_2380602081_DB;Trusted_Connection=True;TrustServerCertificate=True"
   }
   ```
3. Mở **Package Manager Console** hoặc Terminal tại `backend/NguyenHuuThang_2380602081.API/` và chạy lệnh cập nhật database:
   ```bash
   dotnet ef database update
   ```
4. Chạy project:
   - Trong Visual Studio: Nhấn **F5** hoặc nút **Run (https / http)**.
   - Hoặc bằng dòng lệnh:
     ```bash
     dotnet run
     ```
5. Mở trình duyệt truy cập Swagger UI:
   - `http://localhost:5000/swagger` hoặc `https://localhost:7001/swagger`

---

### 4.2. Khởi động Mobile App (Flutter)
1. Mở thư mục `mobile/` bằng **Android Studio** hoặc **VS Code**.
2. Sao chép file `.env.example` thành `.env`:
   ```bash
   cp .env.example .env
   ```
3. Cài đặt các thư viện cần thiết:
   ```bash
   flutter pub get
   ```
4. Cấu hình địa chỉ gọi API trong file `.env`:
   - Nếu chạy trên **Android Emulator (Máy ảo)**:
     ```env
     API_BASE_URL=http://10.0.2.2:5000/api
     ```
   - Nếu chạy trên **Điện thoại thật (qua Wi-Fi)**:
     ```env
     API_BASE_URL=http://<IP_LAN_CUA_MAY_TINH>:5000/api
     ```
   - Nếu chạy trên **Chrome / Windows App**:
     ```env
     API_BASE_URL=http://localhost:5000/api
     ```
5. Chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 5. Quy trình quản lý mã nguồn trên GitHub
1. Kiểm tra trạng thái thay đổi:
   ```bash
   git status
   ```
2. Thêm file và commit theo chức năng cụ thể:
   ```bash
   git add .
   git commit -m "feat: triển khai API quản lý sinh viên"
   ```
3. Kết nối với remote repository trên GitHub và đẩy mã nguồn:
   ```bash
   git remote add origin https://github.com/<tai-khoan-github>/NguyenHuuThang_2380602081.git
   git branch -M main
   git push -u origin main
   ```
4. Cập nhật tiến độ vào file `FUNCTIONS_STATUS.txt` sau mỗi chức năng hoàn thành.
