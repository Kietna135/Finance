import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  education,
  travel,
  devices,
  entertainment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Thực phẩm';
      case ExpenseCategory.education:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Du lịch & Đi lại';
      case ExpenseCategory.devices:
        return 'Thiết bị';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_car_rounded;
      case ExpenseCategory.devices:
        return Icons.devices_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_creation_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFE65100); // Deep Orange
      case ExpenseCategory.education:
        return const Color(0xFF1565C0); // Blue
      case ExpenseCategory.travel:
        return const Color(0xFF00897B); // Teal
      case ExpenseCategory.devices:
        return const Color(0xFF6A1B9A); // Purple
      case ExpenseCategory.entertainment:
        return const Color(0xFFC2185B); // Pink
      case ExpenseCategory.other:
        return const Color(0xFF546E7A); // Blue Grey
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFFF3E0);
      case ExpenseCategory.education:
        return const Color(0xFFE3F2FD);
      case ExpenseCategory.travel:
        return const Color(0xFFE0F2F1);
      case ExpenseCategory.devices:
        return const Color(0xFFF3E5F5);
      case ExpenseCategory.entertainment:
        return const Color(0xFFFCE4EC);
      case ExpenseCategory.other:
        return const Color(0xFFECEFF1);
    }
  }

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
