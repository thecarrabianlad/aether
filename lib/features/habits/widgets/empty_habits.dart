import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EmptyHabitsState extends StatelessWidget {
  const EmptyHabitsState({super.key});

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
              color: context.aether.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.aether.border),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: context.aether.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet.',
            style: TextStyle(
              color: context.aether.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add New Habit" to create your first one.',
            style: TextStyle(
              color: context.aether.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}