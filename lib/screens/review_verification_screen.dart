import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/expense_item.dart';
import '../providers/expense_provider.dart';
import '../services/receipt_parser.dart';

class ReviewVerificationScreen extends ConsumerStatefulWidget {
  final ParsedReceiptResult parsedResult;
  final String? imagePath;

  const ReviewVerificationScreen({
    super.key,
    required this.parsedResult,
    this.imagePath,
  });

  @override
  ConsumerState<ReviewVerificationScreen> createState() =>
      _ReviewVerificationScreenState();
}

class _ReviewVerificationScreenState
    extends ConsumerState<ReviewVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedResult.merchant ?? '',
    );
    _amountController = TextEditingController(
      text: widget.parsedResult.amount != null
          ? widget.parsedResult.amount!.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController();
    _selectedDate = widget.parsedResult.date ?? DateTime.now();
    _selectedCategory = widget.parsedResult.category;
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

  Future<void> _saveToDatabase() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0.0;
    final item = ExpenseItem(
      id: const Uuid().v4(),
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : 'Cửa hàng',
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      receiptImagePath: widget.imagePath,
      rawOcrText: widget.parsedResult.rawText,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    await ref.read(expenseProvider.notifier).addExpense(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã lưu chi phí vào cơ sở dữ liệu!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực & Xem lại hóa đơn'),
        actions: [
          IconButton(
            tooltip: 'Xem kết quả văn bản OCR thô',
            icon: Icon(_showRawOcr ? Icons.code_off : Icons.code),
            onPressed: () {
              setState(() {
                _showRawOcr = !_showRawOcr;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _saveToDatabase,
            icon: const Icon(Icons.save_rounded),
            label: const Text(
              'LƯU VÀO SỔ CHI TIÊU',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
              // Thông báo trạng thái OCR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI đã tự động trích xuất dữ liệu. Vui lòng kiểm tra và chỉnh sửa nếu có sai sót trước khi lưu.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Xem trước hình ảnh biên lai (nếu có)
              if (widget.imagePath != null && File(widget.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Tên Cửa Hàng
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Tên người bán / Cửa hàng *',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên người bán' : null,
              ),
              const SizedBox(height: 16),

              // Số Tiền (VNĐ)
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tổng tiền (VNĐ) *',
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

              // Ngày giao dịch
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày thanh toán',
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

              // Phân loại danh mục
              Text(
                'Danh mục chi phí',
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

              // Ghi chú thêm
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (Tùy chọn)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phần Bounding Value & OCR Inspector
              if (_showRawOcr) ...[
                const Divider(),
                Text(
                  'Văn bản OCR thô (Raw OCR Text):',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    widget.parsedResult.rawText.isNotEmpty
                        ? widget.parsedResult.rawText
                        : 'Không có dữ liệu văn bản',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                if (widget.parsedResult.debugLogs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...widget.parsedResult.debugLogs.map(
                    (log) => Text(
                      '• $log',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
