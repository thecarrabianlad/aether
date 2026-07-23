import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class CategoryFiltersRow extends StatelessWidget {
  final HabitCategory? selectedCategory;
  final ValueChanged<HabitCategory?> onCategorySelected;
  final VoidCallback onAddHabit;

  const CategoryFiltersRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Habits",
          style: TextStyle(
            color: HabitRepository.whiteText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip(
                label: 'All Habits',
                icon: Icons.check_circle_outline,
                color: HabitRepository.redAccent,
                isSelected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
              ),
              const SizedBox(width: 8),
              for (final cat in HabitCategory.values)
                Row(
                  children: [
                    _buildChip(
                      label: cat.label,
                      icon: cat.icon,
                      color: cat.color,
                      isSelected: selectedCategory == cat,
                      onTap: () => onCategorySelected(cat),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              _buildAddHabitChip(onTap: onAddHabit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : HabitRepository.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : HabitRepository.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : HabitRepository.greyText, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : HabitRepository.greyText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHabitChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: HabitRepository.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HabitRepository.redAccent.withOpacity(0.4),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: HabitRepository.redAccent, size: 16),
            SizedBox(width: 4),
            Text(
              'Add Habit',
              style: TextStyle(
                color: HabitRepository.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}