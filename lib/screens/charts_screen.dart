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

  // Donut Chart Time Mode & Stepper State
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
      // 12 Tháng của năm được chọn
      final monthlyTotals = List.filled(12, 0.0);

      for (final exp in state.allExpenses) {
        if (exp.date.year == _selectedBarYear) {
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
      // 5 năm gần nhất
      final currentYear = now.year;
      final startYear = currentYear - 4;
      final yearMap = <int, double>{};
      for (int y = startYear; y <= currentYear; y++) {
        yearMap[y] = 0.0;
      }

      for (final exp in state.allExpenses) {
        if (yearMap.containsKey(exp.date.year)) {
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
      final sortedEntries = state.weeklyTotals.entries.toList()
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
          'Phân Tích Chi Tiêu',
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
              // Thẻ tổng quan chi tiêu
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
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
                            'Tổng chi tiêu toàn thời gian',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatVnd(state.totalAmount),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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

              // Phần 1: Biểu đồ tròn phân bổ danh mục (Kéo vuốt hoặc chuyển tháng/năm)
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
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _donutMode = newSelection.first;
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
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    children: [
                      // Thanh điều hướng chu kỳ có nút < > và cử chỉ vuốt
                      if (_donutMode != 'all')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                onPressed: () => _stepDonutPeriod(-1), // Lùi 1 tháng / năm
                                tooltip: 'Lùi 1 chu kỳ (hoặc vuốt sang phải)',
                              ),
                              Column(
                                children: [
                                  Text(
                                    donutPeriodLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const Text(
                                    'Kéo / vuốt sang trái hoặc phải để đổi',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: () => _stepDonutPeriod(1), // Tiến 1 tháng / năm
                                tooltip: 'Tiến 1 chu kỳ (hoặc vuốt sang trái)',
                              ),
                            ],
                          ),
                        ),

                      // Vùng biểu đồ Donut có hỗ trợ cử chỉ GestureDetector
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (_donutMode == 'all') return;
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < -150) {
                              // Vuốt sang trái -> Tiến 1 tháng/năm
                              _stepDonutPeriod(1);
                            } else if (details.primaryVelocity! > 150) {
                              // Vuốt sang phải -> Lùi 1 tháng/năm
                              _stepDonutPeriod(-1);
                            }
                          }
                        },
                        child: CustomPieChart(
                          data: donutTotals,
                          totalAmount: donutTotalAmount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Phần 2: Biểu đồ cột đa chế độ (7 Ngày / 12 Tháng / Hàng Năm)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xu hướng chi tiêu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SegmentedButton<ChartTimeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ChartTimeMode.week,
                        label: Text('Tuần', style: TextStyle(fontSize: 11)),
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
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _barMode = newSelection.first;
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
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                  child: FlexibleBarChart(
                    items: barItems,
                    mode: _barMode,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
