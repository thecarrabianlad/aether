import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class DateNavigatorCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DateNavigatorCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: HabitRepository.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabitRepository.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPrevious,
            child: const Icon(Icons.chevron_left,
                color: HabitRepository.greyText, size: 22),
          ),
          Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: HabitRepository.whiteText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: HabitRepository.greyText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onNext,
            child: const Icon(Icons.chevron_right,
                color: HabitRepository.greyText, size: 22),
          ),
        ],
      ),
    );
  }
}
