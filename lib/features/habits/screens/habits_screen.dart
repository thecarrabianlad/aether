import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart'; // For constants like colors
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
import 'package:aether/features/habits/models/habit_codec.dart'; // New import

class HabitsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  const HabitsScreen({super.key, this.onMenuTap, this.onProfileTap});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  static final DateTime _referenceDate = DateTime(2025, 8, 12);
  int _dayOffset = 0;

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
        );
  }

  Future<void> _showEditHabitDialog(Habit habit) async {
    final result = await showEditHabitDialog(
      context,
      currentName: habit.name,
      currentCategory: habit.category,
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
          ),
        );
  }

  void _confirmDeleteHabit(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Habit',
          style: TextStyle(color: HabitRepository.whiteText, fontSize: 18),
        ),
        content: Text(
          'Delete "${habit.name}" permanently?',
          style: const TextStyle(color: HabitRepository.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: HabitRepository.greyText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(habitsServiceProvider).deleteHabit(habit.id);
            },
            child: const Text('Delete', style: TextStyle(color: HabitRepository.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Future.microtask(() {
    //   ref.read(globalAddActionProvider.notifier).state = () => _showAddHabitDialog();
    // });
  }

  @override
  void dispose() {
    // if (ref.read(globalAddActionProvider) == _showAddHabitDialog) {
    //   ref.read(globalAddActionProvider.notifier).state = null;
    // }
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

  DateTime get _selectedDate =>
      _referenceDate.add(Duration(days: _dayOffset));

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

  String get _dateNavigatorLabel {
    if (_dayOffset == 0) return 'Today';
    if (_dayOffset == -1) return 'Yesterday';
    if (_dayOffset == 1) return 'Tomorrow';
    return _weekdayNames[_selectedDate.weekday - 1];
  }

  String get _fullDateLabel {
    final day = _selectedDate.day;
    final month = _monthNames[_selectedDate.month - 1];
    final year = _selectedDate.year;
    return '$day${_ordinalSuffix(day)} $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabitsAsync = ref.watch(filteredHabitsProvider);
    final overviewMetricsAsync = ref.watch(overviewMetricsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      color: HabitRepository.darkBg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HabitsAppBar(
              onMenuTap: widget.onMenuTap ?? () {}, // TODO: Wire drawer
              onProfileTap: widget.onProfileTap ?? () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    DateNavigatorCard(
                      label: _dateNavigatorLabel,
                      subtitle: _fullDateLabel,
                      onPrevious: () =>
                          setState(() => _dayOffset -= 1),
                      onNext: () =>
                          setState(() => _dayOffset += 1),
                    ),
                    const SizedBox(height: 20),
                    overviewMetricsAsync.when(
                      data: (overviewMetrics) => OverviewMetricsSection(
                        metrics: overviewMetrics,
                        onViewCalendar: () {},
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 20),
                    CategoryFiltersRow(
                      selectedCategory: selectedCategory,
                      onCategorySelected: (cat) => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = cat,
                      onAddHabit: () => _showAddHabitDialog(),
                    ),
                    const SizedBox(height: 12),
                    filteredHabitsAsync.when(
                      data: (filteredHabits) {
                        if (filteredHabits.isEmpty) {
                          return const EmptyHabitsState();
                        } else {
                          return Column(
                            children: filteredHabits.map(
                              (habit) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: HabitCard(
                                  habit: habit,
                                  onToggle: () => ref
                                      .read(habitsServiceProvider)
                                      .toggleCompletion(habit.id, !habit.isCompletedToday),
                                  onEdit: () => _showEditHabitDialog(habit),
                                  onDelete: () => _confirmDeleteHabit(habit),
                                ),
                              ),
                            ).toList(),
                          );
                        }
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: weeklyProgressAsync.when(
                            data: (weeklyProgress) => WeeklyProgressCard(data: weeklyProgress),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Error: $err'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: categoryStatsAsync.when(
                            data: (categoryStats) => CategoryStatsCard(stats: categoryStats),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Error: $err'),
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
