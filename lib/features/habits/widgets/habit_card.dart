import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

class HabitCard extends StatefulWidget {
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

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _onToggle() {
    _popCtrl.forward(from: 0).then((_) => _popCtrl.reverse());
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final aether = context.aether;
    final todayIndex = DateTime.now().weekday - 1; // Monday = 0 ... Sunday = 6
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aether.border),
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
                    color: aether.text,
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
                        color: aether.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (habit.reminderTime != null &&
                        habit.reminderDays != null &&
                        habit.reminderDays!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.notifications_outlined,
                        color: aether.accent,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        habit.reminderTime!,
                        style: TextStyle(
                          color: aether.accent,
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
                    ..._dayLabels.asMap().entries.map((entry) {
                      final dayIdx = entry.key;
                      final isCompleted = dayIdx < habit.dayCompletions.length &&
                          habit.dayCompletions[dayIdx];
final isToday = dayIdx == todayIndex;
                      return Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(right: dayIdx < 6 ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? HabitRepository.greenAccent.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? HabitRepository.greenAccent
                                : isToday
                                    ? aether.accent.withValues(alpha: 0.4)
                                    : aether.border,
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
                                      ? aether.accent
                                      : aether.textMuted,
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
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: HabitRepository.orangeAccent, size: 14),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '${habit.currentStreak}',
                        key: ValueKey(habit.currentStreak),
                        style: const TextStyle(
                          color: HabitRepository.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today,
                        color: HabitRepository.greenAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.weeklyCompletions}/${habit.weeklyTotal}',
                      style: TextStyle(color: aether.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: aether.surfaceAlt,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: habit.weeklyTotal > 0
                            ? habit.weeklyCompletions / habit.weeklyTotal
                            : 0,
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
          // Completion toggle ring — spring-pop on toggle.
          AnimatedBuilder(
            animation: _popCtrl,
            builder: (context, child) {
              final scale = 1.0 + _popCtrl.value * 0.15;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: _onToggle,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isCompletedToday
                          ? HabitRepository.greenAccent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: habit.isCompletedToday
                            ? HabitRepository.greenAccent
                            : aether.textMuted.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: habit.isCompletedToday
                        ? const Icon(Icons.check,
                            color: HabitRepository.greenAccent, size: 18)
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          // 3-dot menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') widget.onEdit();
              if (value == 'delete') widget.onDelete();
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