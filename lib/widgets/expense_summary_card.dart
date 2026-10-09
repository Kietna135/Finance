import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final VoidCallback onTap;

  const ExpenseSummaryCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category = ExpenseCategory.other,
    required this.onTap,
  });

  /// Định dạng số tiền kiểu Việt Nam Đồng (###.### đ)
  String _formatVnd(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  /// Định dạng ngày (DD/MM/YYYY)
  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // 1. Icon inside a circular container indicating category
              Container(
                width: 46.0,
                height: 46.0,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 14.0),

              // 2. Store name and date stacked vertically with CrossAxisAlignment.start
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
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _formatDate(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // 3. Highlighted monetary amount formatted as Vietnamese Dong ( ###.### đ )
              Text(
                _formatVnd(amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
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
