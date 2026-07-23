import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

/// Selected category filter. `null` means "All".
final selectedCategoryProvider = StateProvider<HabitCategory?>((ref) => null);

/// The full list of habits (live-updating via in-memory repository).
final habitsProvider = StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super(HabitRepository.getAll());

  void toggleCompletion(String habitId) {
    HabitRepository.toggleCompletion(habitId);
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
  ref.watch(habitsProvider);
  return HabitRepository.getOverview();
});

/// Category statistics derived from the full habits list.
final categoryStatsProvider = Provider<List<CategoryStat>>((ref) {
  ref.watch(habitsProvider);
  return HabitRepository.getCategoryStats();
});

/// Weekly progress chart data derived from the full habits list.
final weeklyProgressProvider = Provider<WeeklyProgressData>((ref) {
  ref.watch(habitsProvider);
  return HabitRepository.getWeeklyProgress();
});
