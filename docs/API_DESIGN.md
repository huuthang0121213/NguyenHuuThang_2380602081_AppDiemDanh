# Tài Liệu Thiết Kế RESTful API

**Dự án:** Hệ thống Điểm danh Sinh viên  
**Sinh viên:** Nguyễn Hữu Thắng - MSSV: 2380602081  
**Giao thức:** HTTP/HTTPS  
**Định dạng dữ liệu:** JSON (`application/json`)  
**Base Route:** `/api`  

---

## 1. Xác thực & Người dùng (Authentication)

### 1.1. Đăng ký tài khoản
- **Method:** `POST`
- **Endpoint:** `/api/auth/register`
- **Quyền truy cập:** Public
- **Request Body:**
  ```json
  {
    "username": "thang2380602081",
    "email": "thang.2380602081@student.edu.vn",
    "password": "Password123@",
    "fullName": "Nguyễn Hữu Thắng",
    "role": "Student"
  }
  ```
- **Response Success (200 OK):**
  ```json
  {
    "success": true,
    "message": "Đăng ký tài khoản thành công!",
    "userId": "guid-here"
  }
  ```

### 1.2. Đăng nhập
- **Method:** `POST`
- **Endpoint:** `/api/auth/login`
- **Quyền truy cập:** Public
- **Request Body:**
  ```json
  {
    "username": "thang2380602081",
    "password": "Password123@"
  }
  ```
- **Response Success (200 OK):**
  ```json
  {
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiration": "2026-10-22T10:00:00Z",
    "user": {
      "id": "guid-here",
      "username": "thang2380602081",
      "fullName": "Nguyễn Hữu Thắng",
      "email": "thang.2380602081@student.edu.vn",
      "role": "Student"
    }
  }
  ```

### 1.3. Xem thông tin cá nhân
- **Method:** `GET`
- **Endpoint:** `/api/auth/profile`
- **Headers:** `Authorization: Bearer <token>`
- **Response Success (200 OK):**
  ```json
  {
    "id": "guid-here",
    "username": "thang2380602081",
    "fullName": "Nguyễn Hữu Thắng",
    "email": "thang.2380602081@student.edu.vn",
    "role": "Student"
  }
  ```

---

## 2. Quản lý Sinh viên (Students)

### 2.1. Lấy danh sách tất cả sinh viên
- **Method:** `GET`
- **Endpoint:** `/api/students`
- **Headers:** `Authorization: Bearer <token>`
- **Response Success (200 OK):**
  ```json
  [
    {
      "id": 1,
      "studentCode": "2380602081",
      "fullName": "Nguyễn Hữu Thắng",
      "email": "thang.2380602081@student.edu.vn",
      "phoneNumber": "0987654321",
      "className": "23DTHB1",
      "isActive": true
    }
  ]
  ```

### 2.2. Lấy chi tiết sinh viên theo ID
- **Method:** `GET`
- **Endpoint:** `/api/students/{id}`
- **Headers:** `Authorization: Bearer <token>`
- **Response Success (200 OK):**
  ```json
  {
    "id": 1,
    "studentCode": "2380602081",
    "fullName": "Nguyễn Hữu Thắng",
    "email": "thang.2380602081@student.edu.vn",
    "phoneNumber": "0987654321",
    "className": "23DTHB1",
    "isActive": true
  }
  ```

### 2.3. Thêm sinh viên mới
- **Method:** `POST`
- **Endpoint:** `/api/students`
- **Headers:** `Authorization: Bearer <token>` (Admin hoặc Giảng viên)
- **Request Body:**
  ```json
  {
    "studentCode": "2380602081",
    "fullName": "Nguyễn Hữu Thắng",
    "email": "thang.2380602081@student.edu.vn",
    "phoneNumber": "0987654321",
    "className": "23DTHB1"
  }
  ```
- **Response Success (201 Created):**
  ```json
  {
    "id": 1,
    "studentCode": "2380602081",
    "fullName": "Nguyễn Hữu Thắng",
    "email": "thang.2380602081@student.edu.vn",
    "phoneNumber": "0987654321",
    "className": "23DTHB1",
    "isActive": true
  }
  ```

### 2.4. Cập nhật thông tin sinh viên
- **Method:** `PUT`
- **Endpoint:** `/api/students/{id}`
- **Headers:** `Authorization: Bearer <token>` (Admin)
- **Request Body:**
  ```json
  {
    "studentCode": "2380602081",
    "fullName": "Nguyễn Hữu Thắng",
    "email": "thang.2380602081@student.edu.vn",
    "phoneNumber": "0987654321",
    "className": "23DTHB1",
    "isActive": true
  }
  ```
- **Response Success (200 OK hoặc 204 No Content)**

### 2.5. Xóa sinh viên
- **Method:** `DELETE`
- **Endpoint:** `/api/students/{id}`
- **Headers:** `Authorization: Bearer <token>` (Admin)
- **Response Success (200 OK / 204 No Content)**

---

## 3. Điểm danh (Attendance)

### 3.1. Tạo phiên điểm danh mới (Dành cho Giảng viên)
- **Method:** `POST`
- **Endpoint:** `/api/attendance/session`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
  ```json
  {
    "courseId": 1,
    "title": "Buổi 1: Lập trình di động Flutter",
    "sessionCode": "SES-20261021-01",
    "durationMinutes": 15,
    "latitude": 10.7769,
    "longitude": 106.7009,
    "allowedRadiusMeters": 50
  }
  ```
- **Response Success (200 OK):**
  ```json
  {
    "sessionId": 101,
    "sessionCode": "SES-20261021-01",
    "qrToken": "qr_jwt_or_guid_hash",
    "expiresAt": "2026-10-21T11:15:00Z"
  }
  ```

### 3.2. Sinh viên quét mã QR điểm danh (Check-in)
- **Method:** `POST`
- **Endpoint:** `/api/attendance/check-in`
- **Headers:** `Authorization: Bearer <token>` (Sinh viên)
- **Request Body:**
  ```json
  {
    "sessionId": 101,
    "qrToken": "qr_jwt_or_guid_hash",
    "latitude": 10.7769,
    "longitude": 106.7009
  }
  ```
- **Response Success (200 OK):**
  ```json
  {
    "success": true,
    "message": "Điểm danh thành công lúc 11:05:22 21/10/2026!",
    "status": "Present"
  }
  ```

### 3.3. Xem lịch sử điểm danh của sinh viên
- **Method:** `GET`
- **Endpoint:** `/api/attendance/history`
- **Headers:** `Authorization: Bearer <token>`
- **Response Success (200 OK):**
  ```json
  [
    {
      "id": 501,
      "courseName": "Lập trình thiết bị di động",
      "sessionTitle": "Buổi 1: Giới thiệu Flutter & API",
      "checkInTime": "2026-10-21T11:05:22Z",
      "status": "Present",
      "method": "QRCode"
    }
  ]
  ```
