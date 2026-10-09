import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseItem? itemToEdit;

  const AddEditExpenseScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.itemToEdit?.merchant ?? '',
    );
    _amountController = TextEditingController(
      text: widget.itemToEdit != null
          ? widget.itemToEdit!.amount.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(
      text: widget.itemToEdit?.note ?? '',
    );
    _selectedDate = widget.itemToEdit?.date ?? DateTime.now();
    _selectedCategory = widget.itemToEdit?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
          _amountController.text.replaceAll(',', '').replaceAll('.', ''),
        ) ??
        0.0;

    final item = ExpenseItem(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      merchant: _merchantController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      receiptImagePath: widget.itemToEdit?.receiptImagePath,
      rawOcrText: widget.itemToEdit?.rawOcrText,
    );

    if (_isEditing) {
      await ref.read(expenseProvider.notifier).updateExpense(item);
    } else {
      await ref.read(expenseProvider.notifier).addExpense(item);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa chi phí' : 'Thêm chi phí mới'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc muốn xóa giao dịch này không?'),
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

                if (confirm == true && mounted) {
                  await ref
                      .read(expenseProvider.notifier)
                      .deleteExpense(widget.itemToEdit!.id);
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isEditing ? 'CẬP NHẬT GIAO DỊCH' : 'LƯU GIAO DỊCH',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên Cửa Hàng
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Tên cửa hàng / Dịch vụ *',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
              ),
              const SizedBox(height: 16),

              // Số Tiền
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: 'VNĐ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ngày chi tiêu
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày chi tiêu',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Danh mục
              Text(
                'Danh mục',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 18,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.displayName),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Ghi chú
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ghi chú thêm',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
