import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/expense_item.dart';
import '../services/database_helper.dart';

class ExpenseState {
  final List<ExpenseItem> allExpenses;
  final List<ExpenseItem> filteredExpenses;
  final Map<ExpenseCategory, double> categoryTotals;
  final Map<DateTime, double> weeklyTotals;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double monthlyBudget;
  final double currentMonthExpense;
  final TransactionType? filterType;
  final ExpenseCategory? filterCategory;
  final DateTime selectedCalendarDate;
  final String searchQuery;
  final bool isLoading;

  ExpenseState({
    required this.allExpenses,
    required this.filteredExpenses,
    required this.categoryTotals,
    required this.weeklyTotals,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.monthlyBudget,
    required this.currentMonthExpense,
    required this.selectedCalendarDate,
    this.filterType,
    this.filterCategory,
    this.searchQuery = '',
    this.isLoading = false,
  });

  double get budgetUsageRatio =>
      monthlyBudget > 0 ? (currentMonthExpense / monthlyBudget).clamp(0.0, 2.0) : 0.0;

  double get remainingBudget => (monthlyBudget - currentMonthExpense);

  factory ExpenseState.initial() {
    final Map<ExpenseCategory, double> initialCategories = {};
    for (final c in ExpenseCategory.values) {
      initialCategories[c] = 0.0;
    }

    final now = DateTime.now();
    return ExpenseState(
      allExpenses: [],
      filteredExpenses: [],
      categoryTotals: initialCategories,
      weeklyTotals: {},
      totalIncome: 0.0,
      totalExpense: 0.0,
      netBalance: 0.0,
      monthlyBudget: 5000000.0,
      currentMonthExpense: 0.0,
      selectedCalendarDate: DateTime(now.year, now.month, now.day),
      isLoading: true,
    );
  }

  ExpenseState copyWith({
    List<ExpenseItem>? allExpenses,
    List<ExpenseItem>? filteredExpenses,
    Map<ExpenseCategory, double>? categoryTotals,
    Map<DateTime, double>? weeklyTotals,
    double? totalIncome,
    double? totalExpense,
    double? netBalance,
    double? monthlyBudget,
    double? currentMonthExpense,
    DateTime? selectedCalendarDate,
    TransactionType? filterType,
    bool clearFilterType = false,
    ExpenseCategory? filterCategory,
    bool clearCategoryFilter = false,
    String? searchQuery,
    bool? isLoading,
  }) {
    return ExpenseState(
      allExpenses: allExpenses ?? this.allExpenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      weeklyTotals: weeklyTotals ?? this.weeklyTotals,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      netBalance: netBalance ?? this.netBalance,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currentMonthExpense: currentMonthExpense ?? this.currentMonthExpense,
      selectedCalendarDate: selectedCalendarDate ?? this.selectedCalendarDate,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterCategory: clearCategoryFilter ? null : (filterCategory ?? this.filterCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DatabaseHelper _dbHelper;

  ExpenseNotifier(this._dbHelper) : super(ExpenseState.initial()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final expenses = await _dbHelper.getAllExpenses();
      final catTotals = await _dbHelper.getCategoryTotals(type: TransactionType.expense);
      final weekly = await _dbHelper.getWeeklyDailyTotals(type: TransactionType.expense);
      final budget = await _dbHelper.getBudgetLimit();

      double income = 0;
      double expense = 0;
      final now = DateTime.now();
      double monthExpense = 0;

      for (final item in expenses) {
        if (item.isIncome) {
          income += item.amount;
        } else {
          expense += item.amount;
          if (item.date.year == now.year && item.date.month == now.month) {
            monthExpense += item.amount;
          }
        }
      }

      state = state.copyWith(
        allExpenses: expenses,
        categoryTotals: catTotals,
        weeklyTotals: weekly,
        totalIncome: income,
        totalExpense: expense,
        netBalance: income - expense,
        monthlyBudget: budget,
        currentMonthExpense: monthExpense,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void filterByType(TransactionType? type) {
    if (type == state.filterType) {
      state = state.copyWith(clearFilterType: true);
    } else {
      state = state.copyWith(filterType: type);
    }
    _applyFilters();
  }

  void filterByCategory(ExpenseCategory? category) {
    if (category == state.filterCategory) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
    _applyFilters();
  }

  void selectCalendarDate(DateTime date) {
    state = state.copyWith(
      selectedCalendarDate: DateTime(date.year, date.month, date.day),
    );
  }

  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<ExpenseItem>.from(state.allExpenses);

    if (state.filterType != null) {
      result = result.where((e) => e.type == state.filterType).toList();
    }

    if (state.filterCategory != null) {
      result = result.where((e) => e.category == state.filterCategory).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.toLowerCase().trim();
      result = result.where((e) {
        final merchantMatch = e.merchant.toLowerCase().contains(q);
        final noteMatch = e.note?.toLowerCase().contains(q) ?? false;
        final catMatch = e.category.displayName.toLowerCase().contains(q);
        return merchantMatch || noteMatch || catMatch;
      }).toList();
    }

    state = state.copyWith(filteredExpenses: result);
  }

  Future<void> addExpense(ExpenseItem item) async {
    await _dbHelper.insertExpense(item);
    await loadData();
  }

  Future<void> updateExpense(ExpenseItem item) async {
    await _dbHelper.updateExpense(item);
    await loadData();
  }

  Future<void> deleteExpense(String id) async {
    await _dbHelper.deleteExpense(id);
    await loadData();
  }

  Future<void> setBudgetLimit(double limit) async {
    await _dbHelper.setBudgetLimit(limit);
    state = state.copyWith(monthlyBudget: limit);
  }

  Future<String> exportCsv() => _dbHelper.exportToCsv();
  Future<String> exportJson() => _dbHelper.exportToJson();

  Future<int> importJson(String content) async {
    final count = await _dbHelper.importFromJson(content);
    if (count > 0) {
      await loadData();
    }
    return count;
  }

  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
    await loadData();
  }
}

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ExpenseNotifier(dbHelper);
});
