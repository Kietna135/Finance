# 💰 Finance - Quản Lý Tài Chính & OCR Hóa Đơn (Flutter 3.x & Web PWA)

[![Flutter 3.x](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart 3.x](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![PWA Ready](https://img.shields.io/badge/PWA-Ready-2563eb?logo=pwa)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
[![Vercel Deployed](https://img.shields.io/badge/Vercel-Deployed-black?logo=vercel)](https://vercel.com)
[![GitHub Actions CI](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/Kietna135/Finance/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Hệ thống quản lý tài chính cá nhân thông minh đa nền tảng (**Flutter 3.x Android/iOS/Web** & **Web PWA**), tích hợp công nghệ trích xuất giao dịch và hóa đơn bằng **OCR Heuristic Engine** ngoại tuyến (<100ms), trực quan hóa dữ liệu bằng **HTML5 Canvas / CustomPainter** và hệ thống kiểm soát hạn mức ngân sách thông minh.

---

## 🔗 Liên Kết Dự Án (Repository & Downloads)

- **GitHub Repository**: [https://github.com/Kietna135/Finance.git](https://github.com/Kietna135/Finance.git)
- **Tải File Release APK (Android)**: [https://github.com/Kietna135/Finance/releases](https://github.com/Kietna135/Finance/releases)
- **Theo Dõi Tiến Trình Build (CI/CD)**: [https://github.com/Kietna135/Finance/actions](https://github.com/Kietna135/Finance/actions)

---

## 🛠️ Yêu Cầu Môi Trường (Prerequisites)

- **Flutter SDK**: `3.x` (khuyên dùng `Flutter 3.24.x` trở lên)
- **Dart SDK**: `3.x`
- **Java Development Kit**: `JDK 17`
- **Android SDK & Build Tools**: Android API 33/34
- **Node.js** (cho phiên bản Web cục bộ): `v18.x` trở lên

---

## 📱 Hướng Dẫn Biên Dịch & Chạy Flutter 3.x (Build Commands)

### 1. Cài đặt các gói phụ thuộc (Dependencies)
```powershell
flutter pub get
```

### 2. Khởi tạo cấu trúc nền tảng (nếu chưa có thư mục android/ios/web)
```powershell
flutter create . --platforms=android,web,ios --org=com.example.finance
```

### 3. Chạy chế độ phát triển (Debug / Run)
```powershell
# Chạy trên thiết bị Android / Giả lập đã kết nối
flutter run

# Chạy trên trình duyệt Web (Chrome)
flutter run -d chrome
```

### 4. Biên dịch bản phát hành Android (Build Release APK)
```powershell
flutter build apk --release
```
> 📍 **Đường dẫn file sau khi build:**  
> `build/app/outputs/flutter-apk/app-release.apk`

### 5. Biên dịch gói phát hành Google Play Store (App Bundle - AAB)
```powershell
flutter build appbundle --release
```
> 📍 **Đường dẫn file:**  
> `build/app/outputs/bundle/release/app-release.aab`

### 6. Biên dịch gói Web Production
```powershell
flutter build web --release
```
> 📍 **Đường dẫn thư mục web build:**  
> `build/web/`

---

## 🤖 Tự Động Build APK Qua GitHub Actions (Cloud CI/CD)

Repository đã được tích hợp sẵn workflow tự động `.github/workflows/build_apk.yml`:
1. Mỗi khi có lệnh `git push` lên nhánh `main`, GitHub Actions sẽ tự động:
   - Cài đặt môi trường JDK 17 & Flutter 3.24.x.
   - Tự động dựng khung `android` và cài đặt packages.
   - Chạy lệnh `flutter build apk --release`.
   - Đăng tải file `app-release.apk` vào mục **Artifacts** và tạo **GitHub Release** tại [Releases](https://github.com/Kietna135/Finance/releases).

---

## 🌐 Triển Khai Web Lên Vercel & Cài Đặt Dạng App (PWA)

### 1. Triển khai lên Vercel (1-Click Deploy)
1. Đăng nhập [Vercel Dashboard](https://vercel.com/) bằng GitHub.
2. Chọn **"Add New..."** -> **"Project"** -> Import repository `Kietna135/Finance`.
3. Giữ nguyên cấu hình mặc định (Framework: *Other*, Root: `./`) và bấm **Deploy**.
4. Vercel sẽ tự động cấp domain HTTPS (ví dụ: `https://finance-xyz.vercel.app`).

### 2. Cài đặt Web thành App trên thiết bị (PWA):
- 📱 **Android**: Mở link trên Chrome $\rightarrow$ Bấm nút **`Cài App`** trên góc màn hình (hoặc menu 3 chấm `⋮` $\rightarrow$ **"Cài đặt ứng dụng"**).
- 🍎 **iOS (iPhone/iPad)**: Mở link trên Safari $\rightarrow$ Bấm nút **Chia sẻ** `⎋` $\rightarrow$ Chọn **"Thêm vào MH chính" (Add to Home Screen)**.
- 💻 **Máy tính (Windows/Mac)**: Bấm biểu tượng Cài đặt trên thanh địa chỉ trình duyệt để mở cửa sổ App độc lập.

---

## 💻 Chạy Bản Web Local

```powershell
# Chạy máy chủ Node.js cục bộ
node server.js
```
- Mở trình duyệt tại: **`http://localhost:3000`**

---

## 🌟 Tính Năng Cốt Lõi (Features Overview)

1. **Quét OCR Giao Dịch & Hóa Đơn**:
   - Tự động nhận diện dòng tiền `Tiền chi` vs `Tiền thu` (Lương, Thưởng).
   - Bóc tách biên lai chuyển khoản ngân hàng: *Vietcombank, Techcombank, MB Bank, TPBank, VPBank, MoMo, ZaloPay*.
   - Bóc tách hóa đơn bán lẻ: *WinMart, Highlands Coffee, Fahasa, Grab, CGV, TGDĐ, Petrolimex*.
2. **Biểu Đồ Canvas & Vuốt Chọn Kỳ**:
   - Biểu đồ cột chi tiêu hàng tuần, hàng tháng và hàng năm.
   - Biểu đồ Donut cơ cấu danh mục hỗ trợ cảm ứng vuốt/kéo sang trái/phải để chuyển đổi kỳ.
3. **Quản Lý Danh Mục & Ngân Sách Nghiêm Ngặt**:
   - Tùy chỉnh danh mục: Tên, icon, màu sắc và phân loại thu/chi.
   - Cơ chế kiểm soát: $\sum \text{Ngân sách danh mục} \le \text{Tổng hạn mức tháng}$ với cảnh báo trực quan thời gian thực.
4. **Xuất Báo Cáo & Dữ Liệu**:
   - Xuất file **Excel CSV** (UTF-8 BOM) và sao lưu/khôi phục toàn bộ dữ liệu qua **JSON**.

---

## 📄 Bản Quyền (License)
Dự án được phát hành theo giấy phép [MIT License](LICENSE).
