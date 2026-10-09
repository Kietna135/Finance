import '../models/category_model.dart';

class ParsedReceiptResult {
  final String? merchant;
  final double? amount;
  final DateTime? date;
  final ExpenseCategory category;
  final String rawText;
  final List<String> debugLogs;

  ParsedReceiptResult({
    this.merchant,
    this.amount,
    this.date,
    this.category = ExpenseCategory.other,
    required this.rawText,
    this.debugLogs = const [],
  });
}

class ReceiptParser {
  /// Trích xuất tổng số tiền từ chuỗi OCR với Regex Heuristic tiếng Việt
  static double? extractTotal(String rawText) {
    final keywordPattern = RegExp(
      r'(t[oổ]ng\s*ti[eề]n|thanh\s*to[aá]n|amount\s*due|total|t[oổ]ng\s*c[oộ]ng|c[oộ]ng\s*ti[eề]n\s*h[aà]ng|ph[aả]i\s*tr[aả]|th[aà]nh\s*ti[eề]n|gi[aá]\s*tr[iị])',
      caseSensitive: false,
    );

    // Bắt số dạng: 150.000, 150,000, 150000, 150,000.00, 150.000,00
    final numberPattern = RegExp(
      r'[\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d{4,9}',
    );

    final lines = rawText.split('\n');

    // Bước 1: Quét các dòng có chứa từ khóa Tổng tiền / Thanh toán / Total
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (keywordPattern.hasMatch(line)) {
        // Tìm số trong cùng dòng
        final matches = numberPattern.allMatches(line);
        if (matches.isNotEmpty) {
          final parsed = _parseCleanNumber(matches.last.group(0)!);
          if (parsed != null && parsed >= 1000) {
            return parsed;
          }
        }

        // Nếu dòng chứa từ khóa nhưng số nằm ở dòng kế tiếp (thường gặp khi căn phải)
        if (i + 1 < lines.length) {
          final nextMatches = numberPattern.allMatches(lines[i + 1]);
          if (nextMatches.isNotEmpty) {
            final parsed = _parseCleanNumber(nextMatches.last.group(0)!);
            if (parsed != null && parsed >= 1000) {
              return parsed;
            }
          }
        }
      }
    }

    // Bước 2: Heuristic dự phòng - Tìm số lớn nhất hợp lý trong văn bản
    double maxAmount = 0;
    for (final line in lines) {
      for (final match in numberPattern.allMatches(line)) {
        final val = _parseCleanNumber(match.group(0)!);
        if (val != null && val >= 1000 && val <= 500000000) {
          // Bỏ qua nếu trông giống năm hoặc số điện thoại (10 chữ số bắt đầu bằng 0)
          if (val > maxAmount) {
            maxAmount = val;
          }
        }
      }
    }

    return maxAmount > 0 ? maxAmount : null;
  }

  /// Chuẩn hóa chuỗi số tiền thành double
  static double? _parseCleanNumber(String raw) {
    String clean = raw.trim();

    // Nếu chứa cả dấu chấm và dấu phẩy (vd: 150,000.00 hoặc 150.000,00)
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
        // Kiểu Việt Nam: 150.000,00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Kiểu Quốc tế: 150,000.00
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains('.')) {
      // 150.000 (phân tách ngàn)
      clean = clean.replaceAll('.', '');
    } else if (clean.contains(',')) {
      // 150,000
      clean = clean.replaceAll(',', '');
    }

    return double.tryParse(clean);
  }

  /// Trích xuất ngày giao dịch (DD/MM/YYYY hoặc DD-MM-YYYY)
  static DateTime? extractDate(String rawText) {
    final datePatterns = [
      // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
      RegExp(r'(\b\d{1,2})[/\-.]([01]?\d)[/\-.](\d{4}|\d{2})\b'),
      // YYYY-MM-DD
      RegExp(r'(\b\d{4})[/\-.]([01]?\d)[/\-.](\d{1,2})\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        try {
          final p1 = int.parse(match.group(1)!);
          final p2 = int.parse(match.group(2)!);
          var p3 = int.parse(match.group(3)!);

          if (p1 > 1000) {
            // YYYY-MM-DD
            return DateTime(p1, p2, p3);
          } else {
            // DD/MM/YYYY
            if (p3 < 100) p3 += 2000;
            if (p2 >= 1 && p2 <= 12 && p1 >= 1 && p1 <= 31) {
              return DateTime(p3, p2, p1);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Trích xuất tên cửa hàng / người bán từ dòng đầu của hóa đơn
  static String? extractMerchant(String rawText) {
    final ignoredHeaders = RegExp(
      r'(h[oó]a\s*đ[oơ]n|phi[eê]u\s*t[ií]nh\s*ti[eề]n|phi[eê]u\s*thu|receipt|invoice|bill|vat|c[uử]a\s*h[aà]ng|chi\s*nh[aá]nh)',
      caseSensitive: false,
    );

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2)
        .toList();

    for (final line in lines.take(5)) {
      if (!ignoredHeaders.hasMatch(line) &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !line.contains('Tel') &&
          !line.contains('ĐT') &&
          !line.contains('Đ/c') &&
          !line.contains('Địa chỉ')) {
        return line;
      }
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng';
  }

  /// Phỏng đoán danh mục chi tiêu dựa trên từ khóa trong nội dung
  static ExpenseCategory inferCategory(String rawText) {
    final lower = rawText.toLowerCase();

    if (RegExp(r'(c[aà]f[eê]|coffee|tr[aà]|th[iị]t|c[oơ]m|ph[oở]|b[aá]nh|nh[aà]\s*h[aà]ng|si[eê]u\s*th[iị]|winmart|coopmart|circle\s*k|b[aá]ch\s*h[oóa]|food|qu[aá]n|ăn|u[oố]ng)').hasMatch(lower)) {
      return ExpenseCategory.food;
    }

    if (RegExp(r'(s[aá]ch|v[oở]|b[uú]t|h[oọ]c|tr[uư][oờ]ng|gi[aá]o\s*tr[iình]|kho[aá]\s*h[oọ]c|education|t[aà]i\s*li[eệ]u|th[uư]\s*vi[eệ]n)').hasMatch(lower)) {
      return ExpenseCategory.education;
    }

    if (RegExp(r'(x[aă]ng|grab|be\b|gojek|taxi|v[eé]\s*xe|v[eé]\s*m[aá]y\s*bay|g[uử]i\s*xe|petrolimex|travel|chuy[eế]n\s*đi)').hasMatch(lower)) {
      return ExpenseCategory.travel;
    }

    if (RegExp(r'(chu[oộ]t|b[aà]n\s*ph[ií]m|m[aá]y\s*t[ií]nh|laptop|đi[eệ]n\s*tho[aạ]i|tai\s*nghe|fpt|th[eế]\s*gi[oớ]i\s*di\s*đ[oộ]ng|cellphones|ph[uụ]\s*ki[eệ]n)').hasMatch(lower)) {
      return ExpenseCategory.devices;
    }

    if (RegExp(r'(cgv|lotte\s*cinema|rap\s*phim|r[aạ]p|game|karaoke|vé\s*xem|vui\s*ch[oơ]i|billiards)').hasMatch(lower)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.other;
  }

  /// Phân tích toàn diện chuỗi OCR
  static ParsedReceiptResult parse(String rawText) {
    final total = extractTotal(rawText);
    final date = extractDate(rawText) ?? DateTime.now();
    final merchant = extractMerchant(rawText) ?? 'Cửa hàng';
    final category = inferCategory(rawText);

    return ParsedReceiptResult(
      merchant: merchant,
      amount: total,
      date: date,
      category: category,
      rawText: rawText,
    );
  }
}
