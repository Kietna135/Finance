import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ChartTimeMode { week, month, year }

typedef BarChartItem = ({String label, double amount, bool isHighlight});

class FlexibleBarChart extends StatefulWidget {
  final List<BarChartItem> items;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _BarChartPainter(
                items: widget.items,
                maxValue: maxVal,
                progress: _animation.value,
                primaryColor: theme.colorScheme.primary,
                gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                textColor: theme.colorScheme.onSurfaceVariant,
                mode: widget.mode,
              ),
            );
          },
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartItem> items;
  final double maxValue;
  final double progress;
  final Color primaryColor;
  final Color gridColor;
  final Color textColor;
  final ChartTimeMode mode;

  _BarChartPainter({
    required this.items,
    required this.maxValue,
    required this.progress,
    required this.primaryColor,
    required this.gridColor,
    required this.textColor,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final bottomPadding = 28.0;
    final topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final count = items.length;
    final slotWidth = size.width / count;

    // Responsive bar width based on number of columns
    final barWidth = mode == ChartTimeMode.month
        ? (slotWidth * 0.55).clamp(8.0, 18.0)
        : (slotWidth * 0.45).clamp(16.0, 36.0);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    // Background horizontal grid lines (0%, 50%, 100%)
    canvas.drawLine(
      Offset(0, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, topPadding + chartHeight * 0.5),
      Offset(size.width, topPadding + chartHeight * 0.5),
      gridPaint..color = gridColor.withValues(alpha: 0.5),
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final safeMax = maxValue > 0 ? maxValue : 1.0;

    for (int i = 0; i < count; i++) {
      final item = items[i];
      final x = slotWidth * i + slotWidth / 2;
      final normalizedHeight = (item.amount / safeMax) * chartHeight * progress;
      final yTop = size.height - bottomPadding - normalizedHeight;

      // Background column track
      final trackPaint = Paint()
        ..color = gridColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final trackRRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - barWidth / 2,
          topPadding,
          x + barWidth / 2,
          size.height - bottomPadding,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(trackRRect, trackPaint);

      // Active fill bar
      if (normalizedHeight > 0) {
        final barPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: item.isHighlight
                ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                : [
                    primaryColor.withValues(alpha: 0.7),
                    primaryColor.withValues(alpha: 0.4),
                  ],
          ).createShader(
            Rect.fromLTRB(
              x - barWidth / 2,
              yTop,
              x + barWidth / 2,
              size.height - bottomPadding,
            ),
          );

        final barRRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - barWidth / 2,
            yTop,
            x + barWidth / 2,
            size.height - bottomPadding,
          ),
          Radius.circular(barWidth / 2),
        );
        canvas.drawRRect(barRRect, barPaint);
      }

      // Value label on top of bar
      if (item.amount > 0 && mode != ChartTimeMode.month) {
        String displayVal;
        if (item.amount >= 1000000) {
          displayVal = '${(item.amount / 1000000).toStringAsFixed(1)}tr';
        } else if (item.amount >= 1000) {
          displayVal = '${(item.amount / 1000).toInt()}k';
        } else {
          displayVal = '${item.amount.toInt()}';
        }

        textPainter.text = TextSpan(
          text: displayVal,
          style: TextStyle(
            color: item.isHighlight ? primaryColor : textColor,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, yTop - textPainter.height - 3),
        );
      }

      // X Axis label
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

class WeeklyBarChart extends StatelessWidget {
  final Map<DateTime, double>? weeklyData;
  final List<BarChartItem>? items;
  final ChartTimeMode mode;

  const WeeklyBarChart({
    super.key,
    this.weeklyData,
    this.items,
    this.mode = ChartTimeMode.week,
  });

  @override
  Widget build(BuildContext context) {
    if (items != null) {
      return FlexibleBarChart(items: items!, mode: mode);
    }

    final data = weeklyData ?? {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    final chartItems = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dateKey = DateTime(date.year, date.month, date.day);
      final amount = data[dateKey] ?? 0.0;
      final label = index == 6 ? 'H.nay' : dayNames[date.weekday % 7];
      final isHighlight = index == 6;

      return (
        label: label,
        amount: amount,
        isHighlight: isHighlight,
      );
    });

    return FlexibleBarChart(
      items: chartItems,
      mode: mode,
    );
  }
}
