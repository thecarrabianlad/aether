import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/widgets/common/async_value_widget.dart';
import 'package:aether/widgets/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'package:aether/core/database/database.dart'; // For HabitEntry
import 'package:aether/features/habits/widgets/habits_app_bar.dart';
import 'package:aether/features/habits/widgets/date_navigator.dart';
import 'package:aether/features/habits/widgets/overview_metrics.dart';
import 'package:aether/features/habits/widgets/category_filters.dart';
import 'package:aether/features/habits/widgets/habit_card.dart';
import 'package:aether/features/habits/widgets/weekly_chart.dart';
import 'package:aether/features/habits/widgets/category_stats.dart';
import 'package:aether/features/habits/widgets/add_habit_tile.dart';
import 'package:aether/features/habits/widgets/add_habit_dialog.dart';
import 'package:aether/features/habits/widgets/empty_habits.dart';
import 'package:aether/features/habits/models/habit_codec.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  const HabitsScreen({super.key, this.onMenuTap, this.onProfileTap});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  Future<void> _showAddHabitDialog() async {
    final result = await showAddHabitDialog(context);
    if (result == null || !mounted) return;
    final iconString = HabitCodec.iconToString(result.icon);
    final colorString = HabitCodec.colorToString(result.color);
    await ref.read(habitsServiceProvider).createHabit(
          name: result.name,
          category: result.category.name,
          icon: iconString,
          color: colorString,
          reminderTime: result.reminderTime,
          reminderDays: result.reminderDays,
        );
  }

  Future<void> _showEditHabitDialog(Habit habit) async {
    final result = await showEditHabitDialog(
      context,
      currentName: habit.name,
      currentCategory: habit.category,
      currentReminderTime: habit.reminderTime,
      currentReminderDays: habit.reminderDays,
    );
    if (result == null || !mounted) return;
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

  void _confirmDeleteHabit(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.aether.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Habit',
          style: TextStyle(color: context.aether.text, fontSize: 18),
        ),
        content: Text(
          'Delete "${habit.name}" permanently?',
          style: TextStyle(color: context.aether.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.aether.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(habitsServiceProvider).deleteHabit(habit.id);
            },
            child: Text('Delete', style: TextStyle(color: context.aether.danger)),
          ),
        ],
      ),
    );
  }

  /// Named method (not an inline closure) so the dispose-time equality check
  /// below matches what initState registered — tear-offs of the same instance
  /// method compare equal.
  void _addHabitAction() => _showAddHabitDialog();

  @override
  void initState() {
    super.initState();
    // Deferred — modifying a provider synchronously during initState would
    // throw while the widget tree is building.
    Future.microtask(() {
      if (mounted) {
        ref.read(globalAddActionProvider.notifier).state = _addHabitAction;
        _rescheduleAllHabitReminders();
      }
    });
  }

  /// Reschedule all habit notifications on app start and settings changes.
  /// Gated on [NotificationSettings.enabled] && [NotificationSettings.habits].
  Future<void> _rescheduleAllHabitReminders() async {
    final settings = ref.read(notificationSettingsProvider);
    final notificationService = ref.read(notificationServiceProvider);
    if (settings.enabled && settings.habits) {
      final entries = await ref.read(
        habitsServiceProvider).getAllHabitEntries();
      await notificationService.rescheduleAll(entries);
    } else {
      await notificationService.cancelAll();
    }
  }

  @override
  void dispose() {
    // Capture the notifier now (ref is unusable after dispose), but defer the
    // actual clear — mutating a provider synchronously mid-tree-teardown can
    // throw "modified a provider while the widget tree was building".
    final notifier = ref.read(globalAddActionProvider.notifier);
    final action = _addHabitAction;
    Future.microtask(() {
      // Only clear if we still own the action; a newly-mounted screen may
      // have already registered its own by the time this runs.
      if (notifier.state == action) notifier.state = null;
    });
    super.dispose();
  }


  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  DateTime get _today => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _dateNavigatorLabel(DateTime selectedDate) {
    final dayOffset = selectedDate.difference(_today).inDays;
    if (dayOffset == 0) return 'Today';
    if (dayOffset == -1) return 'Yesterday';
    if (dayOffset == 1) return 'Tomorrow';
    return _weekdayNames[selectedDate.weekday - 1];
  }

  String _fullDateLabel(DateTime selectedDate) {
    final day = selectedDate.day;
    final month = _monthNames[selectedDate.month - 1];
    final year = selectedDate.year;
    return '$day${_ordinalSuffix(day)} $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabitsAsync = ref.watch(filteredHabitsProvider);
    final overviewMetricsAsync = ref.watch(overviewMetricsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isFutureDate = selectedDate.isAfter(_today);

    return Container(
      color: context.aether.background,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HabitsAppBar(
              onMenuTap: widget.onMenuTap ??
                  () => ref.read(drawerProvider.notifier).state = true,
              onProfileTap: widget.onProfileTap ??
                  () => context.push('/profile'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    DateNavigatorCard(
                      label: _dateNavigatorLabel(selectedDate),
                      subtitle: _fullDateLabel(selectedDate),
                      onPrevious: () => ref
                          .read(selectedDateProvider.notifier)
                          .state = selectedDate.subtract(const Duration(days: 1)),
                      onNext: () => ref
                          .read(selectedDateProvider.notifier)
                          .state = selectedDate.add(const Duration(days: 1)),
                    ),
                    const SizedBox(height: 20),
                    AsyncValueWidget(
                              value: overviewMetricsAsync,
                              loadingSkeleton: const SkeletonCard(height: 72),
                              data: (overviewMetrics) => OverviewMetricsSection(
                                metrics: overviewMetrics,
                                onViewCalendar: () => context.push('/habits/calendar'),
                              ),
                              onRetry: () => ref.invalidate(overviewMetricsProvider),
                            ),
                    const SizedBox(height: 20),
                    CategoryFiltersRow(
                      selectedCategory: selectedCategory,
                      onCategorySelected: (cat) => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = cat,
                      onAddHabit: () => _showAddHabitDialog(),
                    ),
                     AsyncValueWidget(
                      value: filteredHabitsAsync,
                      data: (habits) {
                        if (habits.isEmpty) {
                          return const EmptyHabitsState();
                        }

                        return Column(
                          children: habits.map(
                            (habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => context.push('/habit-detail/${habit.id}'),
                                borderRadius: BorderRadius.circular(14),
                                child: HabitCard(
                                  habit: habit,
                                  onToggle: isFutureDate
                                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Can't complete a habit for a future date",
                                              ),
                                            ),
                                          )
                                      : () => ref
                                          .read(habitsServiceProvider)
                                          .toggleCompletion(
                                            habit.id,
                                            !habit.isCompletedToday,
                                            date: selectedDate,
                                          ),
                                  onEdit: () => _showEditHabitDialog(habit),
                                  onDelete: () => _confirmDeleteHabit(habit),
                                ),
                              ),
                            ),
                          ).toList(),
                        );
                      },
                      onRetry: () => ref.invalidate(habitsProvider),
                    ),
                                        const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AsyncValueWidget(
                            value: weeklyProgressAsync,
                            loadingSkeleton: const SkeletonCard(height: 160),
                            data: (weeklyProgress) =>
                                WeeklyProgressCard(data: weeklyProgress),
                            onRetry: () => ref.invalidate(weeklyProgressProvider),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AsyncValueWidget(
                            value: categoryStatsAsync,
                            loadingSkeleton: const SkeletonCard(height: 160),
                            data: (categoryStats) =>
                                CategoryStatsCard(stats: categoryStats),
                            onRetry: () => ref.invalidate(categoryStatsProvider),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AddHabitTile(onTap: () => _showAddHabitDialog()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}