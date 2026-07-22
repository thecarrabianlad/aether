import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/features/habits/models/habit_repository.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'package:aether/features/habits/widgets/habits_app_bar.dart';
import 'package:aether/features/habits/widgets/date_navigator.dart';
import 'package:aether/features/habits/widgets/overview_metrics.dart';
import 'package:aether/features/habits/widgets/category_filters.dart';
import 'package:aether/features/habits/widgets/habit_card.dart';
import 'package:aether/features/habits/widgets/weekly_chart.dart';
import 'package:aether/features/habits/widgets/category_stats.dart';
import 'package:aether/features/habits/widgets/add_habit_tile.dart';

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
    final filteredHabits = ref.watch(filteredHabitsProvider);
    final overviewMetrics = ref.watch(overviewMetricsProvider);
    final categoryStats = ref.watch(categoryStatsProvider);
    final weeklyProgress = ref.watch(weeklyProgressProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      color: HabitRepository.darkBg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            HabitsAppBar(
              onMenuTap: widget.onMenuTap ?? () {},
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
                    OverviewMetricsSection(
                      metrics: overviewMetrics,
                      onViewCalendar: () {},
                    ),
                    const SizedBox(height: 20),
                    CategoryFiltersRow(
                      selectedCategory: selectedCategory,
                      onCategorySelected: (cat) => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = cat,
                      onAddHabit: () {},
                    ),
                    const SizedBox(height: 12),
                    ...filteredHabits.map(
                      (habit) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HabitCard(
                          habit: habit,
                          onToggle: () => ref
                              .read(habitsProvider.notifier)
                              .toggleCompletion(habit.id),
                          onMenuTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WeeklyProgressCard(
                              data: weeklyProgress),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CategoryStatsCard(
                              stats: categoryStats),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AddHabitTile(onTap: () {}),
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
