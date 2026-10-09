import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../providers/expense_provider.dart';
import 'add_edit_expense_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final ExpenseItem expense;

  const TransactionDetailScreen({super.key, required this.expense});

  String _formatVnd(double value) {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return f.format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncome = expense.isIncome;
    final typeColor = expense.type.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Giao Dịch', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditExpenseScreen(expenseToEdit: expense),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Xóa giao dịch',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Bạn có chắc muốn xóa giao dịch "${expense.merchant}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Amount Card
          Card(
            elevation: 0,
            color: typeColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: typeColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(expense.type.icon, size: 14, color: typeColor),
                        const SizedBox(width: 6),
                        Text(
                          expense.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${isIncome ? '+' : '-'}${_formatVnd(expense.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    expense.merchant,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detail Properties Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: expense.category.backgroundColor,
                      child: Icon(expense.category.icon, color: expense.category.color, size: 20),
                    ),
                    title: const Text('Danh mục', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    subtitle: Text(
                      expense.category.displayName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(indent: 70, endIndent: 16, height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    title: const Text('Ngày giao dịch', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    subtitle: Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(expense.date),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const Divider(indent: 70, endIndent: 16, height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFFBEB),
                        child: Icon(Icons.notes_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      title: const Text('Ghi chú', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      subtitle: Text(
                        expense.note!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attached Receipt Image (if present)
          if (expense.receiptImagePath != null && File(expense.receiptImagePath!).existsSync()) ...[
            Text('Ảnh Hóa Đơn Đính Kèm', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(expense.receiptImagePath!),
                fit: BoxFit.cover,
                height: 240,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Raw OCR Text (if present)
          if (expense.rawOcrText != null && expense.rawOcrText!.trim().isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.document_scanner_rounded, color: Color(0xFF2563EB)),
                title: const Text(
                  'Văn bản OCR trích xuất',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text('Xem dữ liệu thô nhận diện từ hóa đơn', style: TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            expense.rawOcrText!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: expense.rawOcrText!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã sao chép nội dung OCR!')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Sao chép văn bản OCR'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
