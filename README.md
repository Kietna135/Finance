# Dự Án Nhỏ 3: FinanceAI Pro - Quản Lý Chi Phí & Phân Tích Hóa Đơn Bằng OCR (Flutter & Web)

Hệ thống quản lý tài chính cá nhân thông minh dành cho sinh viên và thủ quỹ câu lạc bộ, tích hợp trí tuệ nhân tạo nhận diện chữ viết trên thiết bị (**Google ML Kit / Tesseract OCR**), thuật toán Heuristic Regex trích xuất thông tin hóa đơn tiếng Việt ngoại tuyến (Offline, <100ms), biểu đồ phân tích trực quan bằng **CustomPainter / HTML5 Canvas** và hệ thống dự báo tài chính thông minh.

---

## 🚀 Các Tính Năng Được Nâng Cấp (Pro 2.0 Features)

1. **Quản Lý Hạn Mức Ngân Sách Tháng & Cảnh Báo Thông Minh**:
   - Thiết lập hạn mức ngân sách tháng linh hoạt.
   - Thanh tiến trình ngân sách trực quan với 3 mức trạng thái (Xanh lá <70%, Vàng 70-90%, Đỏ >90% cảnh báo vượt ngưỡng).
   - Tự động tính toán số tiền còn lại và **Mức chi tiêu an toàn mỗi ngày**.

2. **Công Cụ AI OCR Nhận Diện Hóa Đơn & Bounding Value Inspector**:
   - Trích xuất văn bản hóa đơn ngoại tuyến ngay trên thiết bị.
   - Thuật toán Heuristic Regex nhận diện: Tổng tiền (`150.000 đ`, `150,000 VND`, `TOTAL`), Tên cửa hàng, Ngày giao dịch (`DD/MM/YYYY`) và tự động phân loại danh mục.
   - Màn hình **Review & Verification**: Xem lại văn bản thô, ảnh hóa đơn và chỉnh sửa thủ công trước khi lưu.
   - Hỗ trợ khung ngắm camera quét laser & các mẫu biên lai giả lập (*WinMart, Highlands Coffee, Fahasa, GrabBike*).

3. **Dự Báo Tài Chính & AI Recommendations (Insights Tab)**:
   - Thống kê mức chi tiêu trung bình mỗi ngày.
   - Dự báo tổng số tiền sẽ chi tiêu vào cuối tháng dựa trên tốc độ tiêu dùng hiện tại.
   - Phân tích nhóm chi phí chiếm tỷ trọng cao nhất và đưa ra khuyến nghị tài chính tối ưu.

4. **Trực Quan Hóa Với CustomPainter / Canvas Thuần**:
   - **Donut / Pie Chart**: Cơ cấu phân bổ danh mục, chạm để xem chi tiết ở tâm và chú thích phần trăm.
   - **Weekly Bar Chart**: Biểu đồ cột chi tiêu 7 ngày với gradient, đường lưới ngang và nhãn ngày (`T2` - `CN`, `H.nay`).

5. **Xuất Báo Cáo & Quản Lý Dữ Liệu**:
   - Xuất dữ liệu sang định dạng **Excel CSV** (hỗ trợ tiếng Việt UTF-8 BOM).
   - Sao lưu và phục hồi dữ liệu qua file **JSON**.
   - Bộ lọc đa năng: Tìm kiếm tức thì, lọc theo chip danh mục, sắp xếp theo Ngày và Số tiền.

---

## 🌐 Triển Khai Lên Vercel & Cài Đặt Dưới Dạng App (PWA)

### 1. Triển khai lên Vercel (1 Click Deploy)
1. Đăng nhập [Vercel](https://vercel.com/) bằng tài khoản GitHub.
2. Chọn **"Add New..."** -> **"Project"**.
3. Chọn repository `Finance` (`https://github.com/Kietna135/Finance.git`).
4. Giữ nguyên thiết lập mặc định (Framework Preset: *Other*, Root Directory: `./`) và nhấn **Deploy**.
5. Vercel sẽ tự động cấp domain HTTPS tốc độ cao (ví dụ: `https://finance-xyz.vercel.app`).

### 2. Cài đặt web thành App trên điện thoại & máy tính:
- **Trên Android / Chrome**: Truy cập link Vercel -> Bấm nút **`Cài App`** trên góc màn hình hoặc vào menu 3 chấm (⋮) chọn **"Cài đặt ứng dụng"** / **"Thêm vào Màn hình chính"**.
- **Trên iPhone / iPad (iOS Safari)**: Truy cập link Vercel trên Safari -> Bấm nút **Chia sẻ** (biểu tượng hộp có mũi tên ⎋) -> Chọn **"Thêm vào MH chính" (Add to Home Screen)**.
- **Trên Máy tính (Chrome/Edge)**: Bấm biểu tượng Cài đặt trên thanh địa chỉ URL để mở ứng dụng trong cửa sổ độc lập không viền như App desktop.

---

## 💻 Chạy Cục Bộ (Local)

- **Địa chỉ truy cập:** [http://localhost:3000](http://localhost:3000)
- **Khởi chạy máy chủ:**
  ```powershell
  node server.js
  ```

