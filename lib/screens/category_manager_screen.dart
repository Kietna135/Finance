import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Danh Mục', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Danh Mục Chi Tiêu', icon: Icon(Icons.arrow_downward_rounded, color: Colors.red)),
            Tab(text: 'Danh Mục Thu Nhập', icon: Icon(Icons.arrow_upward_rounded, color: Colors.green)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(ExpenseCategory.expenseCategories, theme, isExpense: true),
          _buildCategoryList(ExpenseCategory.incomeCategories, theme, isExpense: false),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<ExpenseCategory> categories, ThemeData theme, {required bool isExpense}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: cat.backgroundColor,
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            title: Text(
              cat.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              isExpense ? 'Loại: Khoản Chi' : 'Loại: Khoản Thu',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isExpense ? Colors.red : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isExpense ? 'Chi phí' : 'Thu nhập',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
