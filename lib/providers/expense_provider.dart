import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/expense_item.dart';
import '../services/database_helper.dart';

class ExpenseState {
  final List<ExpenseItem> allExpenses;
  final List<ExpenseItem> filteredExpenses;
  final Map<ExpenseCategory, double> categoryTotals;
  final Map<DateTime, double> weeklyTotals;
  final double totalAmount;
  final ExpenseCategory? filterCategory;
  final String searchQuery;
  final bool isLoading;

  ExpenseState({
    required this.allExpenses,
    required this.filteredExpenses,
    required this.categoryTotals,
    required this.weeklyTotals,
    required this.totalAmount,
    this.filterCategory,
    this.searchQuery = '',
    this.isLoading = false,
  });

  factory ExpenseState.initial() {
    final Map<ExpenseCategory, double> initialCategories = {};
    for (final c in ExpenseCategory.values) {
      initialCategories[c] = 0.0;
    }

    return ExpenseState(
      allExpenses: [],
      filteredExpenses: [],
      categoryTotals: initialCategories,
      weeklyTotals: {},
      totalAmount: 0.0,
      isLoading: true,
    );
  }

  ExpenseState copyWith({
    List<ExpenseItem>? allExpenses,
    List<ExpenseItem>? filteredExpenses,
    Map<ExpenseCategory, double>? categoryTotals,
    Map<DateTime, double>? weeklyTotals,
    double? totalAmount,
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
      totalAmount: totalAmount ?? this.totalAmount,
      filterCategory: clearCategoryFilter
          ? null
          : (filterCategory ?? this.filterCategory),
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
      final catTotals = await _dbHelper.getCategoryTotals();
      final weekly = await _dbHelper.getWeeklyDailyTotals();

      final total = expenses.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );

      state = state.copyWith(
        allExpenses: expenses,
        categoryTotals: catTotals,
        weeklyTotals: weekly,
        totalAmount: total,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void filterByCategory(ExpenseCategory? category) {
    if (category == state.filterCategory) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
    _applyFilters();
  }

  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<ExpenseItem>.from(state.allExpenses);

    if (state.filterCategory != null) {
      result = result.where((e) => e.category == state.filterCategory).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.toLowerCase().trim();
      result = result.where((e) {
        return e.merchant.toLowerCase().contains(q) ||
            (e.note?.toLowerCase().contains(q) ?? false) ||
            e.category.displayName.toLowerCase().contains(q);
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
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(DatabaseHelper.instance);
});
