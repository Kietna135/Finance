import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/custom_pie_chart.dart';
import '../widgets/weekly_bar_chart.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  ChartTimeMode _barMode = ChartTimeMode.week;
  int _selectedBarYear = DateTime.now().year;

  // Donut Chart State
  TransactionType _chartTxType = TransactionType.expense;
  String _donutMode = 'month'; // 'all', 'month', 'year'
  int _donutMonth = DateTime.now().month;
  int _donutYear = DateTime.now().year;

  String _formatVnd(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  void _stepDonutPeriod(int direction) {
    setState(() {
      if (_donutMode == 'month') {
        _donutMonth += direction;
        if (_donutMonth > 12) {
          _donutMonth = 1;
          _donutYear += 1;
        } else if (_donutMonth < 1) {
          _donutMonth = 12;
          _donutYear -= 1;
        }
      } else if (_donutMode == 'year') {
        _donutYear += direction;
      }
    });
  }

  Map<ExpenseCategory, double> _getFilteredCategoryTotals(ExpenseState state) {
    final Map<ExpenseCategory, double> totals = {};
    for (final c in ExpenseCategory.values) {
      totals[c] = 0.0;
    }

    final filtered = state.allExpenses.where((exp) {
      if (exp.type != _chartTxType) return false;
      if (_donutMode == 'month') {
        return exp.date.year == _donutYear && exp.date.month == _donutMonth;
      } else if (_donutMode == 'year') {
        return exp.date.year == _donutYear;
      }
      return true;
    });

    for (final exp in filtered) {
      totals[exp.category] = (totals[exp.category] ?? 0.0) + exp.amount;
    }

    return totals;
  }

  double _getFilteredTotalAmount(Map<ExpenseCategory, double> totals) {
    return totals.values.fold<double>(0.0, (sum, val) => sum + val);
  }

  List<({String label, double amount, bool isHighlight})> _buildBarChartItems(
    ExpenseState state,
  ) {
    final now = DateTime.now();

    if (_barMode == ChartTimeMode.month) {
      final monthlyTotals = List.filled(12, 0.0);

      for (final exp in state.allExpenses) {
        if (exp.type == _chartTxType && exp.date.year == _selectedBarYear) {
          monthlyTotals[exp.date.month - 1] += exp.amount;
        }
      }

      return List.generate(12, (index) {
        return (
          label: 'T${index + 1}',
          amount: monthlyTotals[index],
          isHighlight: (_selectedBarYear == now.year && (index + 1) == now.month),
        );
      });
    } else if (_barMode == ChartTimeMode.year) {
      final currentYear = now.year;
      final startYear = currentYear - 4;
      final yearMap = <int, double>{};
      for (int y = startYear; y <= currentYear; y++) {
        yearMap[y] = 0.0;
      }

      for (final exp in state.allExpenses) {
        if (exp.type == _chartTxType && yearMap.containsKey(exp.date.year)) {
          yearMap[exp.date.year] = (yearMap[exp.date.year] ?? 0.0) + exp.amount;
        }
      }

      return yearMap.entries.map((e) {
        return (
          label: '${e.key}',
          amount: e.value,
          isHighlight: e.key == currentYear,
        );
      }).toList();
    } else {
      // 7 ngày gần nhất
      final today = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = today.subtract(const Duration(days: 6));

      final Map<DateTime, double> dailyTotals = {};
      for (int i = 6; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        dailyTotals[DateTime(d.year, d.month, d.day)] = 0.0;
      }

      for (final exp in state.allExpenses) {
        if (exp.type == _chartTxType && !exp.date.isBefore(sevenDaysAgo)) {
          final k = DateTime(exp.date.year, exp.date.month, exp.date.day);
          if (dailyTotals.containsKey(k)) {
            dailyTotals[k] = (dailyTotals[k] ?? 0.0) + exp.amount;
          }
        }
      }

      final sortedEntries = dailyTotals.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return sortedEntries.map((e) {
        final isToday = e.key.year == now.year &&
            e.key.month == now.month &&
            e.key.day == now.day;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);
    final donutTotals = _getFilteredCategoryTotals(state);
    final donutTotalAmount = _getFilteredTotalAmount(donutTotals);
    final barItems = _buildBarChartItems(state);

    String donutPeriodLabel = 'Toàn bộ thời gian';
    if (_donutMode == 'month') {
      donutPeriodLabel = 'Tháng $_donutMonth/$_donutYear';
    } else if (_donutMode == 'year') {
      donutPeriodLabel = 'Năm $_donutYear';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phân Tích Thu Chi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expenseProvider.notifier).loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Segment (Chi tiêu vs Thu nhập)
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Phân Tích Chi Tiêu'),
                    icon: Icon(Icons.arrow_downward_rounded, color: Colors.red, size: 18),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Phân Tích Thu Nhập'),
                    icon: Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 18),
                  ),
                ],
                selected: {_chartTxType},
                onSelectionChanged: (set) {
                  setState(() => _chartTxType = set.first);
                },
              ),
              const SizedBox(height: 16),

              // Overview Summary Card
              Card(
                elevation: 0,
                color: _chartTxType.color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _chartTxType.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chartTxType == TransactionType.expense
                                ? 'Tổng chi tiêu toàn thời gian'
                                : 'Tổng thu nhập toàn thời gian',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatVnd(_chartTxType == TransactionType.expense
                                ? state.totalExpense
                                : state.totalIncome),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _chartTxType.color,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _chartTxType.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Donut Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phân bổ danh mục',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text('Tất cả', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: 'month',
                        label: Text('Tháng', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: 'year',
                        label: Text('Năm', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_donutMode},
                    onSelectionChanged: (newSet) {
                      setState(() {
                        _donutMode = newSet.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stepper (prev / next for Month / Year)
              if (_donutMode != 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => _stepDonutPeriod(-1),
                        tooltip: 'Thời gian trước',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          donutPeriodLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => _stepDonutPeriod(1),
                        tooltip: 'Thời gian sau',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: CustomPieChart(
                          categoryTotals: donutTotals,
                          totalAmount: donutTotalAmount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryLegend(context, donutTotals, donutTotalAmount),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section 2: Bar Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xu hướng giao dịch',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SegmentedButton<ChartTimeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ChartTimeMode.week,
                        label: Text('7 Ngày', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: ChartTimeMode.month,
                        label: Text('12 Tháng', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: ChartTimeMode.year,
                        label: Text('Năm', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_barMode},
                    onSelectionChanged: (newSet) {
                      setState(() {
                        _barMode = newSet.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: WeeklyBarChart(
                          items: barItems,
                          mode: _barMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    Map<ExpenseCategory, double> totals,
    double totalAmount,
  ) {
    final theme = Theme.of(context);
    final sortedCategories = totals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Không có dữ liệu trong khoảng thời gian này',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: sortedCategories.map((entry) {
        final cat = entry.key;
        final amount = entry.value;
        final percentage = totalAmount > 0 ? (amount / totalAmount * 100) : 0.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cat.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat.displayName} (${percentage.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
