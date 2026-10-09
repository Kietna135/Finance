import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_summary_card.dart';
import 'add_edit_expense_screen.dart';
import 'backup_restore_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sổ Giao Dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sao lưu & Xuất file',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Thêm giao dịch',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(expenseProvider.notifier).searchExpenses(val);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(expenseProvider.notifier).searchExpenses('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Filter by Type (All / Chi / Thu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TransactionType?>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: null,
                  label: Text('Tất cả', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Khoản Chi (-)', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.red),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Khoản Thu (+)', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.green),
                ),
              ],
              selected: {state.filterType},
              onSelectionChanged: (set) {
                ref.read(expenseProvider.notifier).filterByType(set.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Category Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('Tất cả danh mục'),
                  selected: state.filterCategory == null,
                  onSelected: (_) {
                    ref.read(expenseProvider.notifier).filterByCategory(null);
                  },
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((cat) {
                  final isSelected = state.filterCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? Colors.white : cat.color,
                      ),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        ref.read(expenseProvider.notifier).filterByCategory(cat);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Summary bar for filtered results
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.filteredExpenses.length} giao dịch',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.filterCategory != null || state.filterType != null || state.searchQuery.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Bỏ lọc', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(expenseProvider.notifier).searchExpenses('');
                      ref.read(expenseProvider.notifier).filterByCategory(null);
                      ref.read(expenseProvider.notifier).filterByType(null);
                    },
                  ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(expenseProvider.notifier).loadData();
              },
              child: state.filteredExpenses.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy giao dịch nào',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: state.filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = state.filteredExpenses[index];
                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: Text('Bạn có chắc muốn xóa "${expense.merchant}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref.read(expenseProvider.notifier).deleteExpense(expense.id);
                          },
                          child: ExpenseSummaryCard(
                            expense: expense,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(
                                    expense: expense,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
