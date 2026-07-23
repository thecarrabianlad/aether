import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class EmptyHabitsState extends StatelessWidget {
  final String? categoryLabel;

  const EmptyHabitsState({super.key, this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: HabitRepository.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HabitRepository.cardBorder),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: HabitRepository.greyText,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No habits yet.',
            style: TextStyle(
              color: HabitRepository.whiteText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Add New Habit" to create your first one.',
            style: TextStyle(
              color: HabitRepository.greyText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
