import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class CategoryStatsCard extends StatelessWidget {
  final List<CategoryStat> stats;

  const CategoryStatsCard({super.key, required this.stats});

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
          const Text(
            'Habit Categories',
            style: TextStyle(
              color: HabitRepository.whiteText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildCategoryRow(stats[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryStat stat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stat.category.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stat.category.label,
                  style: const TextStyle(
                    color: HabitRepository.whiteText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${stat.completed}/${stat.total}',
              style: const TextStyle(
                color: HabitRepository.greyText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stat.fraction,
            minHeight: 4,
            backgroundColor: const Color(0xFF2C2C2E),
            valueColor: AlwaysStoppedAnimation<Color>(stat.category.color),
          ),
        ),
      ],
    );
  }
}
