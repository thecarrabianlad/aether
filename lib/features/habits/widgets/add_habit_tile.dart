import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class AddHabitTile extends StatelessWidget {
  final VoidCallback onTap;

  const AddHabitTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: HabitRepository.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HabitRepository.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HabitRepository.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: HabitRepository.redAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Habit',
                    style: TextStyle(
                      color: HabitRepository.whiteText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Track something new',
                    style: TextStyle(
                      color: HabitRepository.greyText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: HabitRepository.greyText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
