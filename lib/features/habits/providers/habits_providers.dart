import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

/// Selected category filter. `null` means "All".
final selectedCategoryProvider = StateProvider<HabitCategory?>((ref) => null);

/// State notifier that manages the in-memory habit list.
/// All mutations go through the repository and notify UI reactively.
final habitsProvider = StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super(HabitRepository.getAll());

  void toggleCompletion(String habitId) {
    HabitRepository.toggleCompletion(habitId);
    state = HabitRepository.getAll();
  }

  void createHabit({
    required String name,
    required HabitCategory category,
    required IconData icon,
    required Color color,
  }) {
    HabitRepository.createHabit(
      name: name,
      category: category,
      icon: icon,
      color: color,
    );
    state = HabitRepository.getAll();
  }

  void updateHabit(Habit updated) {
    HabitRepository.updateHabit(updated);
    state = HabitRepository.getAll();
  }

  void deleteHabit(String habitId) {
    HabitRepository.deleteHabit(habitId);
    state = HabitRepository.getAll();
  }
}

/// Filtered list based on selected category.
final filteredHabitsProvider = Provider<List<Habit>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final habits = ref.watch(habitsProvider);
  if (category == null) return habits;
  return habits.where((h) => h.category == category).toList();
});

/// Overview metrics derived from the full habits list.
final overviewMetricsProvider = Provider<OverviewMetrics>((ref) {
  final habits = ref.watch(habitsProvider);
  final completed = habits.where((h) => h.isCompletedToday).length;
  final total = habits.length;
  final bestStreak =
      habits.fold(0, (int m, h) => h.longestStreak > m ? h.longestStreak : m);
  final avgWeekly = habits.isEmpty
      ? 0
      : (habits.fold(0.0, (s, h) => s + (h.weeklyCompletions / h.weeklyTotal * 100)) /
              habits.length)
          .round();
  return OverviewMetrics(
    completedToday: completed,
    totalToday: total,
    currentStreak: habits.isEmpty ? 0 : habits.first.currentStreak,
    longestStreak: bestStreak,
    weeklyScore: avgWeekly,
  );
});

/// Category statistics derived from the full habits list.
final categoryStatsProvider = Provider<List<CategoryStat>>((ref) {
  final habits = ref.watch(habitsProvider);
  return HabitCategory.values.map((cat) {
    final catHabits = habits.where((h) => h.category == cat).toList();
    return CategoryStat(
      category: cat,
      completed: catHabits.where((h) => h.isCompletedToday).length,
      total: catHabits.length,
    );
  }).toList();
});

/// Weekly progress chart data derived from the full habits list.
final weeklyProgressProvider = Provider<WeeklyProgressData>((ref) {
  final habits = ref.watch(habitsProvider);
  final counts = List.filled(7, 0);
  for (final habit in habits) {
    for (int i = 0; i < 7 && i < habit.dayCompletions.length; i++) {
      if (habit.dayCompletions[i]) counts[i]++;
    }
  }
  final max = counts.fold(0, (int a, b) => a > b ? a : b);
  return WeeklyProgressData(dailyCounts: counts, maxCount: max > 0 ? max : 1);
});
