import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';
import 'add_edit_expense_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _formatVnd(double value) {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return f.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);

    // Group transactions by date for current month
    final Map<int, List<ExpenseItem>> dayMap = {};
    for (final exp in state.allExpenses) {
      if (exp.date.year == _currentMonth.year && exp.date.month == _currentMonth.month) {
        dayMap.putIfAbsent(exp.date.day, () => []).add(exp);
      }
    }

    // Transactions for selected day
    final selectedExpenses = _selectedDay != null
        ? state.allExpenses.where((e) =>
            e.date.year == _selectedDay!.year &&
            e.date.month == _selectedDay!.month &&
            e.date.day == _selectedDay!.day).toList()
        : <ExpenseItem>[];

    double dayIncome = 0;
    double dayExpense = 0;
    for (final e in selectedExpenses) {
      if (e.isIncome) {
        dayIncome += e.amount;
      } else {
        dayExpense += e.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Thu Chi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Hôm nay',
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _currentMonth = DateTime(now.year, now.month, 1);
                _selectedDay = DateTime(now.year, now.month, now.day);
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Month navigation header
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    'Tháng ${_currentMonth.month} / ${_currentMonth.year}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Calendar Grid Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Day of week headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                        .map((d) => SizedBox(
                              width: 38,
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: d == 'CN' ? Colors.red : theme.hintColor,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const Divider(height: 16),
                  _buildCalendarDays(dayMap),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected Day Summary Card
          if (_selectedDay != null) ...[
            Card(
              elevation: 1,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDay!),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '+${_formatVnd(dayIncome)}',
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '-${_formatVnd(dayExpense)}',
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditExpenseScreen(
                              initialDate: _selectedDay,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // List of transactions for selected day
            if (selectedExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 40, color: theme.disabledColor),
                      const SizedBox(height: 8),
                      Text('Không có giao dịch nào trong ngày này',
                          style: TextStyle(color: theme.hintColor)),
                    ],
                  ),
                ),
              )
            else
              ...selectedExpenses.map((e) => _buildDayTransactionTile(context, e)),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarDays(Map<int, List<ExpenseItem>> dayMap) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Monday = 1, Sunday = 7
    final firstWeekday = firstDayOfMonth.weekday; // 1 to 7

    final List<Widget> dayWidgets = [];

    // Empty spaces for leading days before the 1st
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 38, height: 48));
    }

    // Days in current month
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final isSelected = _selectedDay != null &&
          date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;

      final items = dayMap[day] ?? [];
      final hasIncome = items.any((e) => e.isIncome);
      final hasExpense = items.any((e) => e.isExpense);

      dayWidgets.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          child: Container(
            width: 38,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasIncome)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.greenAccent : const Color(0xFF2E7D32),
                        ),
                      ),
                    if (hasExpense)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.orangeAccent : const Color(0xFFE53935),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.start,
      children: dayWidgets,
    );
  }

  Widget _buildDayTransactionTile(BuildContext context, ExpenseItem item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.category.backgroundColor,
          child: Icon(item.category.icon, color: item.category.color, size: 20),
        ),
        title: Text(
          item.merchant,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          item.category.displayName + (item.note != null && item.note!.isNotEmpty ? ' • ${item.note}' : ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${item.isIncome ? '+' : '-'}${_formatVnd(item.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: item.type.color,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditExpenseScreen(expenseToEdit: item),
            ),
          );
        },
      ),
    );
  }
}
