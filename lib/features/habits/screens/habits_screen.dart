import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
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
import 'package:aether/features/habits/widgets/add_habit_dialog.dart';
import 'package:aether/features/habits/widgets/empty_habits.dart';
import 'package:aether/features/habits/models/habit.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProfileTap;

  const HabitsScreen({super.key, this.onProfileTap});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  static final DateTime _referenceDate = DateTime(2025, 8, 12);
  int _dayOffset = 0;

  @override
  void initState() {
    super.initState();
    // Register the habit add action for the global Add button
    Future.microtask(() {
      ref.read(globalAddActionProvider.notifier).state = () => _showAddHabitDialog();
    });
  }

  @override
  void dispose() {
    // Optionally clear the action when leaving the screen
    if (ref.read(globalAddActionProvider) == _showAddHabitDialog) {
      ref.read(globalAddActionProvider.notifier).state = null;
    }
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

  Future<void> _showAddHabitDialog() async {
    final result = await showAddHabitDialog(context);
    if (result == null || !mounted) return;
    ref.read(habitsProvider.notifier).createHabit(
          name: result.name,
          category: result.category,
          icon: result.icon,
          color: result.color,
        );
  }

  Future<void> _showEditHabitDialog(Habit habit) async {
    final result = await showEditHabitDialog(
      context,
      currentName: habit.name,
      currentCategory: habit.category,
    );
    if (result == null || !mounted) return;
    ref.read(habitsProvider.notifier).updateHabit(
          habit.copyWith(
            name: result.name,
            category: result.category,
            color: result.category.color,
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
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
            },
            child: const Text('Delete', style: TextStyle(color: HabitRepository.redAccent)),
          ),
        ],
      ),
    );
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
              onMenuTap: () => ref.read(drawerProvider.notifier).state = true,
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
                      onAddHabit: _showAddHabitDialog,
                    ),
                    const SizedBox(height: 12),
                    if (filteredHabits.isEmpty)
                      const EmptyHabitsState()
                    else
                      ...filteredHabits.map(
                        (habit) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HabitCard(
                            habit: habit,
                            onToggle: () => ref
                                .read(habitsProvider.notifier)
                                .toggleCompletion(habit.id),
                            onEdit: () => _showEditHabitDialog(habit),
                            onDelete: () => _confirmDeleteHabit(habit),
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
                    AddHabitTile(onTap: _showAddHabitDialog),
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
