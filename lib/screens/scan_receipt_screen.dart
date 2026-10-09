import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../widgets/camera_scan_overlay.dart';
import 'review_verification_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImageFile(String path) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _ocrService.processReceiptImage(path);
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewVerificationScreen(
              parsedResult: result,
              imagePath: path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý OCR: $e')),
        );
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        await _processImageFile(photo.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở máy ảnh: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        await _processImageFile(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh từ thư viện: $e')),
      );
    }
  }

  /// Mô phỏng quét nhanh các mẫu hóa đơn thực tế tại Việt Nam (Dành cho máy ảo / giả lập)
  void _simulateSampleReceipt(String type) {
    String sampleRawText = '';
    switch (type) {
      case 'winmart':
        sampleRawText = '''
SIEU THI WINMART+
Dia chi: 123 Nguyen Trai, Q.1, TP.HCM
Ngay: 08/10/2026 14:30
--------------------------------
1. Sua tuoi Vinamilk      32.000
2. Banh mi sandwich       25.000
3. Tao My Envy (1kg)      95.000
4. Nuoc khoang Lavie      10.000
--------------------------------
TONG TIEN: 162.000 VND
Thanh toan: 162.000 d
VAT (8%): 12.000
Cam on Quy khach!
''';
        break;
      case 'highlands':
        sampleRawText = '''
HIGHLANDS COFFEE
Chi nhanh: Landmark 81
Ngay HD: 07/10/2026
Thu ngan: Tran Van B
-----------------------------
1. Freeze Tra Xanh (L)    69.000
2. Phin Sua Da (M)        39.000
3. Banh Mousse Dao        45.000
-----------------------------
TONG CONG: 153.000 d
THANH TOAN: 153.000 VND
Chuc ban ngay moi vui ve!
''';
        break;
      case 'fahasa':
        sampleRawText = '''
NHA SACH FAHASA
D/C: 40 Nguyen Hue, Quan 1
Ngay GD: 06/10/2026
-----------------------------
1. Giao trinh Lap trinh Dart   145.000
2. So tay A5 Bullet Journal     65.000
3. But gel Pilot (2 cay)        30.000
-----------------------------
CONG TIEN HANG: 240.000
THANH TOAN: 240.000 d
''';
        break;
      case 'grab':
        sampleRawText = '''
GRAB VIETNAM
BIEN LAI DIEN TU
Chuyen di GrabBike
Ngay: 05/10/2026 - 08:15
Diem don: KTX Khu B DHQG
Diem den: Truong Dai Hoc
-----------------------------
Gia tri chuyen di: 38.000 VND
Giam gia khuyen mai: -5.000 VND
-----------------------------
TOTAL: 33.000 d
''';
        break;
    }

    final parsed = ReceiptParser.parse(sampleRawText);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewVerificationScreen(
          parsedResult: parsed,
          imagePath: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quét Hóa Đơn AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Thử mẫu hóa đơn (Simulator)',
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onSelected: _simulateSampleReceipt,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'winmart',
                child: Text('Mẫu 1: Siêu thị WinMart (162.000đ)'),
              ),
              const PopupMenuItem(
                value: 'highlands',
                child: Text('Mẫu 2: Highlands Coffee (153.000đ)'),
              ),
              const PopupMenuItem(
                value: 'fahasa',
                child: Text('Mẫu 3: Nhà sách Fahasa (240.000đ)'),
              ),
              const PopupMenuItem(
                value: 'grab',
                child: Text('Mẫu 4: Chuyến đi GrabBike (33.000đ)'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Viewfinder Camera Scan Overlay
          CameraScanOverlay(
            onCapture: _captureFromCamera,
            onPickGallery: _pickFromGallery,
            onToggleFlash: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
            isFlashOn: _isFlashOn,
          ),

          // Loading Overlay khi đang xử lý OCR
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'AI đang đọc và phân tích hóa đơn...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tốc độ xử lý dưới 100ms với Google ML Kit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
