import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';

class CategoryStatsCard extends StatelessWidget {
  final List<CategoryStat> stats;

  const CategoryStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.aether.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Categories',
            style: TextStyle(
              color: context.aether.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildCategoryRow(context, stats[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, CategoryStat stat) {
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
                  style: TextStyle(
                    color: context.aether.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${stat.completed}/${stat.total}',
              style: TextStyle(
                color: context.aether.textMuted,
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
            backgroundColor: context.aether.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(stat.category.color),
          ),
        ),
      ],
    );
  }
}
