import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ChartTimeMode { week, month, year }

class FlexibleBarChart extends StatefulWidget {
  final List<({String label, double amount, bool isHighlight})> items;
  final ChartTimeMode mode;

  const FlexibleBarChart({
    super.key,
    required this.items,
    this.mode = ChartTimeMode.week,
  });

  @override
  State<FlexibleBarChart> createState() => _FlexibleBarChartState();
}

class _FlexibleBarChartState extends State<FlexibleBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FlexibleBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items || oldWidget.mode != widget.mode) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = widget.items.fold<double>(
      0.0,
      (prev, elem) => math.max(prev, elem.amount),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 190),
          painter: _BarChartPainter(
            items: widget.items,
            maxValue: maxVal > 0 ? maxVal : 100000,
            progress: _animation.value,
            primaryColor: theme.colorScheme.primary,
            secondaryColor: theme.colorScheme.primaryContainer,
            gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
            textColor: theme.colorScheme.onSurfaceVariant,
            mode: widget.mode,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<({String label, double amount, bool isHighlight})> items;
  final double maxValue;
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;
  final ChartTimeMode mode;

  _BarChartPainter({
    required this.items,
    required this.maxValue,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
    required this.mode,
  });

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    const bottomPadding = 32.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final count = items.length;
    final totalSpacing = size.width / count;
    final barWidth = math.min(
      mode == ChartTimeMode.month ? 22.0 : 28.0,
      totalSpacing * (mode == ChartTimeMode.month ? 0.65 : 0.55),
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    // 3 đường lưới ngang
    for (int i = 0; i <= 2; i++) {
      final y = topPadding + chartHeight * (1 - i / 2.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final barPaint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < count; i++) {
      final item = items[i];
      final x = (i * totalSpacing) + (totalSpacing / 2);
      final heightRatio = (item.amount / maxValue).clamp(0.0, 1.0);
      final barHeight = chartHeight * heightRatio * progress;
      final yTop = topPadding + chartHeight - barHeight;

      // Gradient
      barPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: item.isHighlight
            ? [primaryColor, primaryColor.withOpacity(0.75)]
            : [secondaryColor, secondaryColor.withOpacity(0.5)],
      ).createShader(Rect.fromLTWH(x - barWidth / 2, yTop, barWidth, barHeight));

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - barWidth / 2, yTop, barWidth, math.max(barHeight, 4.0)),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(rrect, barPaint);

      // Nhãn số tiền trên đỉnh
      if (item.amount > 0) {
        textPainter.text = TextSpan(
          text: _formatCompact(item.amount),
          style: TextStyle(
            color: item.isHighlight ? primaryColor : textColor,
            fontSize: mode == ChartTimeMode.month ? 8.5 : 10.0,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, yTop - textPainter.height - 3),
        );
      }

      // Nhãn trục hoành (T1..T12, Năm, Ngày)
      textPainter.text = TextSpan(
        text: item.label,
        style: TextStyle(
          color: item.isHighlight ? primaryColor : textColor,
          fontSize: mode == ChartTimeMode.month ? 9.5 : 11.0,
          fontWeight: item.isHighlight ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.items != items ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.mode != mode;
  }
}
