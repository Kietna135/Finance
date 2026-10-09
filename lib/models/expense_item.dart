import 'category_model.dart';

class ExpenseItem {
  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? note;
  final DateTime createdAt;

  ExpenseItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImagePath,
    this.rawOcrText,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'receiptImagePath': receiptImagePath,
      'rawOcrText': rawOcrText,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      merchant: map['merchant'] as String? ?? 'Chưa xác định',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: ExpenseCategory.fromString(map['category'] as String?),
      receiptImagePath: map['receiptImagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  ExpenseItem copyWith({
    String? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? rawOcrText,
    String? note,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
