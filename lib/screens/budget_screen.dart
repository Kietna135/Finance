import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _budgetController = TextEditingController();

  String _formatVnd(double value) {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return f.format(value);
  }

  void _showSetBudgetDialog(double currentBudget) {
    _budgetController.text = currentBudget.toInt().toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết Lập Ngân Sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập hạn mức chi tiêu tối đa trong 1 tháng (VND):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Hạn mức (đ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wallet_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [3000000, 5000000, 10000000, 15000000].map((val) {
                return ActionChip(
                  label: Text('${val ~/ 1000000}tr'),
                  onPressed: () {
                    _budgetController.text = val.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final newBudget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9]'), ''));
              if (newBudget != null && newBudget > 0) {
                ref.read(expenseProvider.notifier).setBudgetLimit(newBudget);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật hạn mức ngân sách: ${_formatVnd(newBudget)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu Hạn Mức'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);

    final ratio = state.budgetUsageRatio;
    final percent = (ratio * 100).toInt();
    final remaining = state.remainingBudget;

    Color statusColor = const Color(0xFF2E7D32);
    String statusTitle = 'Chi Tiêu An Toàn';
    String statusDesc = 'Bạn đang kiểm soát ngân sách rất tốt trong tháng này.';
    IconData statusIcon = Icons.check_circle_rounded;

    if (ratio >= 1.0) {
      statusColor = const Color(0xFFE53935);
      statusTitle = 'Vượt Ngân Sách!';
      statusDesc = 'Chi tiêu đã vượt hạn mức ${_formatVnd(state.currentMonthExpense - state.monthlyBudget)}. Hãy thắt chặt chi tiêu!';
      statusIcon = Icons.warning_rounded;
    } else if (ratio >= 0.8) {
      statusColor = const Color(0xFFF57F17);
      statusTitle = 'Cảnh Báo Hạn Mức';
      statusDesc = 'Đã sử dụng $percent% ngân sách tháng. Hãy cẩn trọng các khoản chi lớn!';
      statusIcon = Icons.info_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Ngân Sách', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Đổi hạn mức',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showSetBudgetDialog(state.monthlyBudget),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Budget Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hạn Mức Tháng ${DateTime.now().month}',
                            style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatVnd(state.monthlyBudget),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showSetBudgetDialog(state.monthlyBudget),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Thay Đổi'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 14,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chi: ${_formatVnd(state.currentMonthExpense)} ($percent%)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        remaining >= 0 ? 'Còn lại: ${_formatVnd(remaining)}' : 'Vượt: ${_formatVnd(-remaining)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: remaining >= 0 ? statusColor : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Advice Card
          Card(
            elevation: 0,
            color: statusColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusDesc,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Top Spending Categories this Month
          Text(
            'Chi Tiêu Theo Danh Mục Tháng Này',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...ExpenseCategory.expenseCategories.map((cat) {
            final total = state.categoryTotals[cat] ?? 0.0;
            final catPercent = state.currentMonthExpense > 0
                ? ((total / state.currentMonthExpense) * 100).toInt()
                : 0;

            if (total == 0) return const SizedBox.shrink();

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: cat.backgroundColor,
                          child: Icon(cat.icon, color: cat.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatVnd(total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '$catPercent% chi tiêu',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (catPercent / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
