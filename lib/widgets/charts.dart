import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../utils/date_utils.dart';

// ============ حلقة التقدم ============

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 62,
    this.stroke = 7,
  });

  final double value; // 0..1
  final String label;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          color: scheme.primary,
          track: scheme.outlineVariant,
          stroke: stroke,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (value > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}

// ============ أعمدة إنجاز آخر 7 أيام ============

class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.days});

  final List<DayStat> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 150,
      child: Row(
        children: days.map((d) {
          final full = d.total > 0 && d.done == d.total;
          final partial = d.done > 0 && !full;
          final barColor =
              full ? scheme.primary : (partial ? scheme.secondary : scheme.outlineVariant);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.total == 0 ? '—' : '${d.done}/${d.total}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 86,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: d.ratio <= 0 ? 3 : (86 * d.ratio).clamp(6.0, 86.0),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============ الدونات (توزيع حسب التصنيف) ============

class DonutSlice {
  const DonutSlice({required this.color, required this.value, required this.label});

  final Color color;
  final double value;
  final String label;
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, this.size = 150});

  final List<DonutSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          holeColor: scheme.surface,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.holeColor});

  final List<DonutSlice> slices;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in slices) {
      final sweep = 2 * math.pi * (s.value / total);
      paint.color = s.color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    final hole = Paint()..color = holeColor;
    canvas.drawCircle(center, radius * 0.52, hole);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

// ============ أعمدة ساعات المواعيد ============

class HoursBars extends StatelessWidget {
  const HoursBars({super.key, required this.hours});

  final List<double> hours; // [1..7]

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH =
        hours.fold<double>(0, (m, h) => math.max(m, h)).clamp(1.0, 24.0);
    return SizedBox(
      height: 150,
      child: Row(
        children: List.generate(7, (i) {
          final wd = i + 1;
          final h = hours[wd];
          final ratio = h <= 0 ? 0.0 : (h / maxH).clamp(0.06, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    h <= 0 ? '—' : '${h.toStringAsFixed(1)}س',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 86,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: (86 * ratio).clamp(3.0, 86.0),
                        decoration: BoxDecoration(
                          color: h <= 0
                              ? scheme.outlineVariant
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekdayShort(wd),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
