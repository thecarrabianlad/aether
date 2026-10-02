import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_codec.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:aether/features/habits/widgets/add_habit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen detail view for a single habit.
///
/// Shows stat cards, a mini 30-day completion grid, a scrollable history
/// log (past 60 days), and action buttons (edit / delete).
class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final habitsAsync = ref.watch(habitsProvider);
    final habitsService = ref.read(habitsServiceProvider);

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: aether.text.withValues(alpha: 0.75)),
          onPressed: () => context.pop(),
        ),
      ),
      body: habitsAsync.when(
        data: (habits) {
          final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
          if (habit == null) {
            return Center(
              child: Text('Habit not found',
                  style: TextStyle(color: aether.textMuted)),
            );
          }

          return _DetailContent(
            habit: habit,
            habitId: widget.habitId,
            habitsService: habitsService,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: TextStyle(color: aether.danger)),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final Habit habit;
  final String habitId;
  final HabitsService habitsService;

  const _DetailContent({
    required this.habit,
    required this.habitId,
    required this.habitsService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // ── Header ──────────────────────────────────────
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(habit.icon, color: habit.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      color: aether.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.category.label,
                    style: TextStyle(color: aether.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Stat cards ──────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Current Streak',
                value: '${habit.currentStreak}d',
                icon: Icons.local_fire_department,
                color: aether.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Longest Streak',
                value: '${habit.longestStreak}d',
                icon: Icons.emoji_events_outlined,
                color: aether.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'This Week',
                value: '${habit.weeklyCompletions}/${habit.weeklyTotal}',
                icon: Icons.calendar_today,
                color: aether.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Completed Today',
                value: habit.isCompletedToday ? 'Yes' : 'Not yet',
                icon: habit.isCompletedToday
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: habit.isCompletedToday
                    ? aether.success
                    : aether.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── 30-Day Mini Grid ────────────────────────────
        Text(
          'Last 30 Days',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: aether.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _MiniHistoryGrid(habitId: habitId),
        const SizedBox(height: 24),

        // ── Reminder info ───────────────────────────────
        if (habit.reminderTime != null && habit.reminderDays != null &&
            habit.reminderDays!.isNotEmpty) ...[
          Text(
            'Reminder',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: aether.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: aether.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: aether.border),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: aether.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${habit.reminderTime} on ${_formatDays(habit.reminderDays!)}',
                  style: TextStyle(color: aether.text, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Actions ─────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editHabit(context, ref),
                icon: Icon(Icons.edit_outlined, color: aether.accent, size: 18),
                label: Text('Edit',
                    style: TextStyle(color: aether.accent, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: aether.accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteHabit(context, ref),
                icon: Icon(Icons.delete_outline, color: aether.danger, size: 18),
                label: Text('Delete',
                    style: TextStyle(color: aether.danger, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: aether.danger.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDays(String daysCsv) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final indices = daysCsv.split(',').map((s) => int.parse(s.trim()) - 1).toList();
    return indices.where((i) => i >= 0 && i < 7).map((i) => labels[i]).join(', ');
  }

  Future<void> _editHabit(BuildContext context, WidgetRef ref) async {
    final result = await showEditHabitDialog(
      context,
      currentName: habit.name,
      currentCategory: habit.category,
      currentReminderTime: habit.reminderTime,
      currentReminderDays: habit.reminderDays,
    );
    if (result == null || !context.mounted) return;
    final iconString = HabitCodec.iconToString(result.icon);
    final colorString = HabitCodec.colorToString(result.color);
    await ref.read(habitsServiceProvider).updateHabit(
      HabitEntry(
        id: habit.id,
        userId: habit.userId,
        name: result.name,
        category: result.category.name,
        icon: iconString,
        color: colorString,
        longestStreak: habit.longestStreak,
        createdAt: habit.createdAt,
        updatedAt: DateTime.now(),
        reminderTime: result.reminderTime,
        reminderDays: result.reminderDays,
      ),
    );
  }

  Future<void> _deleteHabit(BuildContext context, WidgetRef ref) async {
    final aether = context.aether;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: aether.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Habit',
          style: TextStyle(color: aether.text, fontSize: 18),
        ),
        content: Text(
          'Delete "${habit.name}" permanently?',
          style: TextStyle(color: aether.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: aether.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(habitsServiceProvider).deleteHabit(habit.id);
              if (context.mounted) context.pop();
            },
            child: Text('Delete', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
  }
}

/// Small stat tile with an icon, label, and value.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aether.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: aether.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 30-day mini completion grid (6 rows × 7 cols) showing whether
/// the habit was completed on that day.
class _MiniHistoryGrid extends ConsumerWidget {
  final String habitId;
  const _MiniHistoryGrid({required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;
    final logsAsync = ref.watch(
      _habitLogsProvider(habitId),
    );

    return logsAsync.when(
      data: (logs) {
        final completedDates = logs
            .where((l) => l.isCompleted)
            .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
            .toSet();

        final today = DateTime.now();
        final cells = <Widget>[];
        for (int i = 29; i >= 0; i--) {
          final date = DateTime(today.year, today.month, today.day - i);
          final completed = completedDates.contains(date);
          cells.add(
            Container(
              decoration: BoxDecoration(
                color: completed ? aether.accent.withValues(alpha: 0.4) : aether.surfaceAlt,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: i == 0
                      ? aether.accent.withValues(alpha: 0.6)
                      : aether.border,
                ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 9,
                    color: completed ? aether.accent : aether.textMuted,
                    fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: GridView.count(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text('Error: $err',
          style: TextStyle(color: aether.danger, fontSize: 12)),
    );
  }
}

/// Provider that watches habit logs for a specific habit ID.
final _habitLogsProvider =
    StreamProvider.family<List<HabitLog>, String>((ref, habitId) {
  return ref.read(habitsServiceProvider).watchLogsForHabit(habitId);
});
