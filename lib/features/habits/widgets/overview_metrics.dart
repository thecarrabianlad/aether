import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class OverviewMetricsSection extends StatelessWidget {
  final OverviewMetrics metrics;
  final VoidCallback onViewCalendar;

  const OverviewMetricsSection({
    super.key,
    required this.metrics,
    required this.onViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                color: HabitRepository.whiteText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: onViewCalendar,
              child: const Row(
                children: [
                  Text(
                    'View Calendar',
                    style: TextStyle(color: HabitRepository.greyText, fontSize: 12),
                  ),
                  Icon(Icons.chevron_right, color: HabitRepository.greyText, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricRing(
                label: 'Completed',
                value: '${metrics.completedToday}/${metrics.totalToday}',
                fraction: metrics.completedFraction,
                color: HabitRepository.greenAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricRing(
                label: 'Streak',
                value: '${metrics.currentStreak}d',
                fraction: metrics.currentStreak / 30.0,
                color: HabitRepository.purpleAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricRing(
                label: 'Longest',
                value: '${metrics.longestStreak}d',
                fraction: metrics.longestStreak / 30.0,
                color: HabitRepository.orangeAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricRing(
                label: 'Score',
                value: '${metrics.weeklyScore}%',
                fraction: metrics.weeklyScore / 100.0,
                color: HabitRepository.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricRing extends StatelessWidget {
  final String label;
  final String value;
  final double fraction; // 0..1
  final Color color;

  const _MetricRing({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: HabitRepository.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabitRepository.cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFF2C2C2E),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: HabitRepository.greyText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
