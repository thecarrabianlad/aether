import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class WeeklyProgressCard extends StatelessWidget {
  final WeeklyProgressData data;

  const WeeklyProgressCard({super.key, required this.data});

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HabitRepository.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabitRepository.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up,
                  color: HabitRepository.greenAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  color: HabitRepository.whiteText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _LineChartPainter(
                dailyCounts: data.dailyCounts,
                maxCount: data.maxCount,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _dayNames
                .map((d) => Text(
                      d,
                      style: const TextStyle(
                        color: HabitRepository.greyText,
                        fontSize: 10,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Score
          Row(
            children: [
              const Text(
                'Weekly Score',
                style: TextStyle(
                  color: HabitRepository.greyText,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${_computeScore()}%',
                style: const TextStyle(
                  color: HabitRepository.blueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _computeScore() {
    if (data.maxCount == 0) return 0;
    final sum = data.dailyCounts.fold(0, (a, b) => a + b);
    final totalRatio = sum / (data.dailyCounts.length * data.maxCount);
    return (totalRatio * 100).round();
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> dailyCounts;
  final int maxCount;

  _LineChartPainter({
    required this.dailyCounts,
    required this.maxCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (maxCount == 0) return;

    final paint = Paint()
      ..color = HabitRepository.greyText.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines (3)
    for (int i = 0; i < 3; i++) {
      final y = size.height * (1 - (i + 1) / 3.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    if (dailyCounts.length < 2) return;

    final xStep = size.width / (dailyCounts.length - 1);
    final linePaint = Paint()
      ..color = HabitRepository.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HabitRepository.blueAccent.withOpacity(0.25),
          HabitRepository.blueAccent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < dailyCounts.length; i++) {
      final x = i * xStep;
      final ratio = maxCount > 0 ? dailyCounts[i] / maxCount : 0.0;
      final y = size.height * (1 - ratio);
      points.add(Offset(x, y));
    }

    // Draw fill
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final dotPaint = Paint()
        ..color = i == points.length - 1
            ? HabitRepository.blueAccent
            : HabitRepository.blueAccent.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], i == points.length - 1 ? 4 : 2.5, dotPaint);

      // Highlight the last point
      if (i == points.length - 1) {
        final highlightPaint = Paint()
          ..color = HabitRepository.blueAccent.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 7, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.dailyCounts != dailyCounts ||
        oldDelegate.maxCount != maxCount;
  }
}
