import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
          color: context.aether.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.aether.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.aether.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                color: context.aether.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Habit',
                    style: TextStyle(
                      color: context.aether.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Track something new',
                    style: TextStyle(
                      color: context.aether.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.aether.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
