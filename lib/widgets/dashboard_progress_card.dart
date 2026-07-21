import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class DashboardProgressCard extends StatelessWidget {
  final double progress;

  const DashboardProgressCard({
    super.key,
    required this.progress,
  });

  static const Color _accentRed = Color(0xFFEF4F4A);
  static const Color _cardColor = Color(0xFF141821);
  static const Color _centerColor = Color(0xFF0B0E14);
  static const Color _trackColor = Color(0xFF2A2F3A);

  static const double _ringSize = 100;
  static const double _strokeWidth = 5;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = '${(clampedProgress * 100).round()}%';

    return SizedBox(
      width: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: _cardColor.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _ringSize,
                  height: _ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(_ringSize, _ringSize),
                        painter: _ProgressRingPainter(
                          progress: clampedProgress,
                          trackColor: _trackColor,
                          activeColor: _accentRed,
                          strokeWidth: _strokeWidth,
                        ),
                      ),
                      Container(
                        width: _ringSize - _strokeWidth * 2 - 10,
                        height: _ringSize - _strokeWidth * 2 - 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _centerColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            percentage,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = math.pi * 2 * progress;

    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
