import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.aether.border),
      ),
      child: Row(
        children: [
          // Habit icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(habit.icon, color: habit.color, size: 22),
          ),
          const SizedBox(width: 12),
          // Middle section: name, category subtitle, day dots, streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    color: context.aether.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      habit.category.label,
                      style: TextStyle(
                        color: context.aether.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (habit.reminderTime != null &&
                        habit.reminderDays != null &&
                        habit.reminderDays!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.notifications_outlined,
                        color: context.aether.accent,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        habit.reminderTime!,
                        style: TextStyle(
                          color: context.aether.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Day of week dots
                    ..._dayLabels.asMap().entries.map((entry) {
                      final dayIdx = entry.key;
                      final isCompleted = dayIdx < habit.dayCompletions.length &&
                          habit.dayCompletions[dayIdx];
                      final isToday = dayIdx == 6; // Sunday = today marker
                      return Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(
                          right: dayIdx < 6 ? 4 : 0,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? HabitRepository.greenAccent.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? HabitRepository.greenAccent
                                : isToday
                                    ? context.aether.accent.withValues(alpha: 0.4)
                                    : context.aether.border,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[dayIdx],
                            style: TextStyle(
                              color: isCompleted
                                  ? HabitRepository.greenAccent
                                  : isToday
                                      ? context.aether.accent
                                      : context.aether.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                // Streak + weekly fraction
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: HabitRepository.orangeAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak}',
                      style: const TextStyle(
                        color: HabitRepository.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today,
                        color: context.aether.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.weeklyCompletions}/${habit.weeklyTotal}',
                      style: TextStyle(
                        color: context.aether.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: context.aether.surfaceAlt,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            habit.weeklyTotal > 0 ? habit.weeklyCompletions / habit.weeklyTotal : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: habit.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Completion toggle ring
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isCompletedToday
                    ? HabitRepository.greenAccent.withOpacity(0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: habit.isCompletedToday
                      ? HabitRepository.greenAccent
                      : context.aether.textMuted.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: habit.isCompletedToday
                  ? const Icon(Icons.check,
                      color: HabitRepository.greenAccent, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          // 3-dot menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            color: context.aether.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.aether.border),
            ),
            offset: const Offset(-12, 0),
            icon: Icon(Icons.more_vert,
                color: context.aether.textMuted, size: 18),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        color: context.aether.textMuted, size: 16),
                    SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(color: context.aether.text, fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: context.aether.danger, size: 16),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: context.aether.danger, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}