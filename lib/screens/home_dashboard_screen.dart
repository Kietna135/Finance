import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/weekly_bar_chart.dart';
import 'add_edit_expense_screen.dart';
import 'backup_restore_screen.dart';
import 'budget_screen.dart';
import 'calendar_screen.dart';
import 'category_manager_screen.dart';
import 'charts_screen.dart';
import 'scan_receipt_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_list_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardView(),
    CalendarScreen(),
    ChartsScreen(),
    BudgetScreen(),
    TransactionListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ScanReceiptScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.document_scanner_rounded, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Phân tích',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet_rounded),
            label: 'Ngân sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Giao dịch',
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  String _formatVnd(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);
    final recentExpenses = state.allExpenses.take(5).toList();

    final ratio = state.budgetUsageRatio;
    final isOverBudget = ratio >= 1.0;
    final isNearLimit = ratio >= 0.8 && !isOverBudget;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1976D2), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Finance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OCR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Quản lý thu chi & OCR hóa đơn',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Quản lý danh mục',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Sao lưu & Xuất file',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expenseProvider.notifier).loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Net Balance Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số Dư Khả Dụng',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                                const SizedBox(width: 4),
                                Text(
                                  'Tháng ${DateTime.now().month}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatVnd(state.netBalance),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Total Income
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.greenAccent, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng Thu',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    Text(
                                      _formatVnd(state.totalIncome),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Total Expense
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, color: Colors.orangeAccent, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng Chi',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    Text(
                                      _formatVnd(state.totalExpense),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Budget Warning Banner (if over budget or >= 80%)
              if (isOverBudget || isNearLimit)
                Card(
                  elevation: 0,
                  color: (isOverBudget ? Colors.red : Colors.orange).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: (isOverBudget ? Colors.red : Colors.orange).withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          isOverBudget ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                          color: isOverBudget ? Colors.red : Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOverBudget ? 'Cảnh Báo Vượt Ngân Sách!' : 'Cảnh Báo Hạn Mức',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOverBudget ? Colors.red : Colors.orange.shade800,
                                ),
                              ),
                              Text(
                                isOverBudget
                                    ? 'Chi tiêu tháng này đã vượt hạn mức ${_formatVnd(state.currentMonthExpense - state.monthlyBudget)}'
                                    : 'Đã sử dụng ${(ratio * 100).toInt()}% hạn mức ngân sách tháng.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
                          },
                          child: const Text('Xem'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isOverBudget || isNearLimit) const SizedBox(height: 16),

              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanReceiptScreen()));
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Quét Hóa Đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()));
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Nhập Tay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Spending Bar Chart Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi Tiêu 7 Ngày Gần Nhất',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartsScreen()));
                    },
                    child: const Text('Chi tiết'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 180,
                    child: WeeklyBarChart(
                      items: _buildWeeklyItems(state),
                      mode: ChartTimeMode.week,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giao Dịch Gần Đây',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionListScreen()));
                    },
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentExpenses.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('Chưa có giao dịch nào. Hãy bắt đầu quét hóa đơn hoặc nhập tay!'),
                    ),
                  ),
                )
              else
                ...recentExpenses.map(
                  (expense) => ExpenseSummaryCard(
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, double amount, bool isHighlight})> _buildWeeklyItems(
    ExpenseState state,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final Map<DateTime, double> dailyTotals = {};
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dailyTotals[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (final exp in state.allExpenses) {
      if (exp.isExpense && !exp.date.isBefore(sevenDaysAgo)) {
        final k = DateTime(exp.date.year, exp.date.month, exp.date.day);
        if (dailyTotals.containsKey(k)) {
          dailyTotals[k] = (dailyTotals[k] ?? 0.0) + exp.amount;
        }
      }
    }

    final sorted = dailyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) {
      final isToday = e.key.year == now.year && e.key.month == now.month && e.key.day == now.day;
      String label = 'T${e.key.weekday + 1}';
      if (e.key.weekday == 7) label = 'CN';
      if (isToday) label = 'H.nay';

      return (
        label: label,
        amount: e.value,
        isHighlight: isToday,
      );
    }).toList();
  }
}
