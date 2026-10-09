import 'package:flutter/material.dart';

enum TransactionType {
  expense,
  income;

  String get displayName => this == TransactionType.expense ? 'Khoản chi' : 'Khoản thu';
  Color get color => this == TransactionType.expense ? const Color(0xFFE53935) : const Color(0xFF2E7D32);
  IconData get icon => this == TransactionType.expense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
}

enum ExpenseCategory {
  food,
  education,
  travel,
  devices,
  shopping,
  bills,
  entertainment,
  health,
  salary,
  bonus,
  investment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.education:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Đi lại & Du lịch';
      case ExpenseCategory.devices:
        return 'Thiết bị & Đồ dùng';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.bills:
        return 'Hóa đơn & Tiện ích';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.health:
        return 'Sức khỏe & Y tế';
      case ExpenseCategory.salary:
        return 'Tiền lương';
      case ExpenseCategory.bonus:
        return 'Tiền thưởng';
      case ExpenseCategory.investment:
        return 'Đầu tư & Tiết kiệm';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  TransactionType get defaultType {
    switch (this) {
      case ExpenseCategory.salary:
      case ExpenseCategory.bonus:
      case ExpenseCategory.investment:
        return TransactionType.income;
      default:
        return TransactionType.expense;
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
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_creation_rounded;
      case ExpenseCategory.health:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.salary:
        return Icons.payments_rounded;
      case ExpenseCategory.bonus:
        return Icons.card_giftcard_rounded;
      case ExpenseCategory.investment:
        return Icons.trending_up_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFE65100);
      case ExpenseCategory.education:
        return const Color(0xFF1565C0);
      case ExpenseCategory.travel:
        return const Color(0xFF00897B);
      case ExpenseCategory.devices:
        return const Color(0xFF6A1B9A);
      case ExpenseCategory.shopping:
        return const Color(0xFFD81B60);
      case ExpenseCategory.bills:
        return const Color(0xFF5E35B1);
      case ExpenseCategory.entertainment:
        return const Color(0xFFC2185B);
      case ExpenseCategory.health:
        return const Color(0xFF00ACC1);
      case ExpenseCategory.salary:
        return const Color(0xFF2E7D32);
      case ExpenseCategory.bonus:
        return const Color(0xFFF57F17);
      case ExpenseCategory.investment:
        return const Color(0xFF00838F);
      case ExpenseCategory.other:
        return const Color(0xFF546E7A);
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }

  static List<ExpenseCategory> get expenseCategories => [
        ExpenseCategory.food,
        ExpenseCategory.shopping,
        ExpenseCategory.travel,
        ExpenseCategory.bills,
        ExpenseCategory.education,
        ExpenseCategory.devices,
        ExpenseCategory.entertainment,
        ExpenseCategory.health,
        ExpenseCategory.other,
      ];

  static List<ExpenseCategory> get incomeCategories => [
        ExpenseCategory.salary,
        ExpenseCategory.bonus,
        ExpenseCategory.investment,
        ExpenseCategory.other,
      ];

  static ExpenseCategory fromString(String? name) {
    if (name == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
