import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/expense_item.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final ExpenseItem? expense;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final TransactionType type;
  final VoidCallback onTap;

  ExpenseSummaryCard({
    super.key,
    this.expense,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    TransactionType? type,
    required this.onTap,
  })  : merchant = expense?.merchant ?? merchant ?? '',
        amount = expense?.amount ?? amount ?? 0.0,
        date = expense?.date ?? date ?? DateTime.now(),
        category = expense?.category ?? category ?? ExpenseCategory.other,
        type = expense?.type ?? type ?? TransactionType.expense;

  String _formatVnd(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = type == TransactionType.income;
    final amountColor = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFE53935);

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.only(bottom: 10.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Icon inside category background
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 14.0),

              // Merchant & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      merchant.isNotEmpty ? merchant : 'Chưa xác định',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // Amount
              Text(
                '${isIncome ? '+' : '-'}${_formatVnd(amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
