import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_parser.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Nhận diện văn bản trên thiết bị ngoại tuyến (Offline, <100ms)
  Future<ParsedReceiptResult> processReceiptImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    final inputImage = InputImage.fromFilePath(imagePath);
    
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      stopwatch.stop();

      final rawText = recognizedText.text;
      final parsed = ReceiptParser.parse(rawText);

      return ParsedReceiptResult(
        merchant: parsed.merchant,
        amount: parsed.amount,
        date: parsed.date,
        category: parsed.category,
        rawText: rawText,
        debugLogs: [
          'Tốc độ nhận diện OCR: ${stopwatch.elapsedMilliseconds}ms',
          'Tổng số khối văn bản phát hiện: ${recognizedText.blocks.length}',
          'Tổng số dòng: ${recognizedText.blocks.expand((b) => b.lines).length}',
        ],
      );
    } catch (e) {
      stopwatch.stop();
      // Trả về kết quả dự phòng nếu có lỗi khi đọc OCR
      return ParsedReceiptResult(
        merchant: 'Không thể nhận diện',
        amount: null,
        date: DateTime.now(),
        rawText: 'Lỗi OCR: $e',
        debugLogs: ['Gặp lỗi: $e'],
      );
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
