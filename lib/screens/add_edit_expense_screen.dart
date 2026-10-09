import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseItem? itemToEdit;
  final ExpenseItem? expenseToEdit;
  final DateTime? initialDate;

  const AddEditExpenseScreen({
    super.key,
    this.itemToEdit,
    this.expenseToEdit,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  late TransactionType _selectedType;
  String? _receiptImagePath;
  String? _rawOcrText;

  ExpenseItem? get _targetItem => widget.itemToEdit ?? widget.expenseToEdit;
  bool get _isEditing => _targetItem != null;

  @override
  void initState() {
    super.initState();
    final item = _targetItem;
    _merchantController = TextEditingController(text: item?.merchant ?? '');
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    _selectedDate = item?.date ?? widget.initialDate ?? DateTime.now();
    _selectedType = item?.type ?? TransactionType.expense;
    _selectedCategory = item?.category ??
        (_selectedType == TransactionType.expense ? ExpenseCategory.food : ExpenseCategory.salary);
    _receiptImagePath = item?.receiptImagePath;
    _rawOcrText = item?.rawOcrText;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amountToAdd) {
    final currentAmount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final newAmount = currentAmount + amountToAdd;
    setState(() {
      _amountController.text = newAmount.toStringAsFixed(0);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _receiptImagePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
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

    final rawAmount = _amountController.text.replaceAll(',', '').replaceAll('.', '').trim();
    final amount = double.tryParse(rawAmount) ?? 0.0;

    final item = ExpenseItem(
      id: _targetItem?.id ?? const Uuid().v4(),
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : (_selectedType == TransactionType.expense ? 'Chi tiêu' : 'Thu nhập'),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: _selectedType,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      receiptImagePath: _receiptImagePath,
      rawOcrText: _rawOcrText,
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
    final availableCategories = _selectedType == TransactionType.expense
        ? ExpenseCategory.expenseCategories
        : ExpenseCategory.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Sửa Giao Dịch' : 'Thêm Giao Dịch Mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa giao dịch?'),
                    content: const Text('Bạn có chắc muốn xóa giao dịch này?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(expenseProvider.notifier).deleteExpense(_targetItem!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Segmented Button for Expense vs Income
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Khoản Chi (-)', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.arrow_downward_rounded, color: Colors.red),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Khoản Thu (+)', style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.arrow_upward_rounded, color: Colors.green),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                  _selectedCategory = _selectedType == TransactionType.expense
                      ? ExpenseCategory.food
                      : ExpenseCategory.salary;
                });
              },
            ),
            const SizedBox(height: 16),

            // Amount Input Card
            Card(
              elevation: 0,
              color: _selectedType.color.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _selectedType.color.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số Tiền (${_selectedType.displayName})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedType.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _selectedType.color,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'đ',
                        suffixStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _selectedType.color,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (parsed == null || parsed <= 0) {
                          return 'Số tiền phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 16),
                    // Quick add buttons
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        {'label': '+20k', 'val': 20000.0},
                        {'label': '+50k', 'val': 50000.0},
                        {'label': '+100k', 'val': 100000.0},
                        {'label': '+200k', 'val': 200000.0},
                        {'label': '+500k', 'val': 500000.0},
                        {'label': '+1tr', 'val': 1000000.0},
                        {'label': '+5tr', 'val': 5000000.0},
                        {'label': 'Xóa', 'val': 0.0},
                      ].map((btn) {
                        final isClear = btn['val'] == 0.0;
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            btn['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isClear ? Colors.red : theme.colorScheme.primary,
                            ),
                          ),
                          onPressed: () {
                            if (isClear) {
                              setState(() => _amountController.text = '');
                            } else {
                              _addQuickAmount(btn['val'] as double);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Merchant / Source Field
            TextFormField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: _selectedType == TransactionType.expense ? 'Nơi chi / Cửa hàng' : 'Nguồn thu / Người gửi',
                hintText: _selectedType == TransactionType.expense ? 'VD: WinMart, Highlands...' : 'VD: Lương công ty, Thưởng...',
                prefixIcon: const Icon(Icons.storefront_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thông tin nơi chi / nguồn thu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Picker Field
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày giao dịch',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
            Text(
              'Danh Mục',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCategories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: cat.backgroundColor,
                    child: Icon(cat.icon, size: 16, color: cat.color),
                  ),
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Note Field
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm (Tùy chọn)',
                prefixIcon: Icon(Icons.note_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Receipt photo attachment
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ảnh Hóa Đơn (Tùy chọn)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton.outlined(
                              icon: const Icon(Icons.camera_alt_rounded, size: 18),
                              onPressed: () => _pickImage(ImageSource.camera),
                              tooltip: 'Chụp ảnh',
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              onPressed: () => _pickImage(ImageSource.gallery),
                              tooltip: 'Chọn từ thư viện',
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_receiptImagePath != null && File(_receiptImagePath!).existsSync()) ...[
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_receiptImagePath!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() => _receiptImagePath = null);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _isEditing ? 'Cập Nhật Giao Dịch' : 'Lưu Giao Dịch',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
