import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';

class CustomPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const CustomPieChart({
    super.key,
    Map<ExpenseCategory, double>? data,
    Map<ExpenseCategory, double>? categoryTotals,
    required this.totalAmount,
  }) : data = data ?? categoryTotals ?? const {};

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CustomPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatVnd(double value) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validCategories = widget.data.entries
        .where((e) => e.value > 0)
        .toList();

    if (widget.totalAmount <= 0 || validCategories.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: theme.disabledColor),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu chi tiêu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _PieChartPainter(
                      data: widget.data,
                      totalAmount: widget.totalAmount,
                      progress: _animation.value,
                      selectedCategory: _selectedCategory,
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                  // Center Text info for Donut Chart
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory != null
                            ? _selectedCategory!.displayName
                            : 'Tổng chi tiêu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCategory != null
                            ? _formatVnd(widget.data[_selectedCategory] ?? 0)
                            : _formatVnd(widget.totalAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _selectedCategory != null
                              ? _selectedCategory!.color
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Chú giải danh mục (Legend)
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: validCategories.map((entry) {
            final cat = entry.key;
            final val = entry.value;
            final percentage = (val / widget.totalAmount * 100).toStringAsFixed(1);
            final isSelected = _selectedCategory == cat;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : cat;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.backgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${cat.displayName} ($percentage%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? cat.color : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;
  final double progress;
  final ExpenseCategory? selectedCategory;
  final Color backgroundColor;

  _PieChartPainter({
    required this.data,
    required this.totalAmount,
    required this.progress,
    this.selectedCategory,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final strokeWidth = outerRadius * 0.32;
    final radius = outerRadius - strokeWidth / 2;

    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final entry in data.entries) {
      if (entry.value <= 0) continue;

      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi * progress;
      final isSelected = selectedCategory == entry.key;

      paint.color = entry.key.color;
      paint.strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.03, // Khoảng cách nhỏ giữa các lát cắt
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.totalAmount != totalAmount;
  }
}
