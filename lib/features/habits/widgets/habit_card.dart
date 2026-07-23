import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onMenuTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onMenuTap,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HabitRepository.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HabitRepository.cardBorder),
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
                  style: const TextStyle(
                    color: HabitRepository.whiteText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  habit.category.label,
                  style: const TextStyle(
                    color: HabitRepository.greyText,
                    fontSize: 12,
                  ),
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
                                    ? HabitRepository.redAccent.withOpacity(0.4)
                                    : HabitRepository.cardBorder,
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
                                      ? HabitRepository.redAccent
                                      : HabitRepository.greyText,
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
                    const Icon(Icons.calendar_today,
                        color: HabitRepository.greyText, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.weeklyCompletions}/${habit.weeklyTotal}',
                      style: const TextStyle(
                        color: HabitRepository.greyText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
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
                      : HabitRepository.greyText.withOpacity(0.4),
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
          GestureDetector(
            onTap: onMenuTap,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert,
                  color: HabitRepository.greyText, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}