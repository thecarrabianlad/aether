import 'package:flutter/material.dart';
import 'package:aether/features/habits/models/habit.dart';

/// In-memory habit repository with seed data matching the reference design.
///
/// This is the source of truth until a persistent layer (Drift or Supabase)
/// is connected. The interface is designed for a drop-in replacement:
/// the providers depend only on this repository's static methods.
class HabitRepository {
  HabitRepository._();

  static final List<Habit> _habits = <Habit>[];
  static int _nextId = 1;

  /// Resets the ID counter (used in tests).
  static void resetIdCounter() => _nextId = 1;

  // ── Category colours used across the feature ──
  static const Color redAccent = Color(0xFFE8443F);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF34C759);
  static const Color orangeAccent = Color(0xFFFF9500);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color cardBg = Color(0xFF121212);
  static const Color cardBorder = Color(0xFF262626);
  static const Color greyText = Color(0xFF9A9A9E);
  static const Color whiteText = Color(0xFFF5F5F5);
  static const Color darkBg = Color(0xFF000000);

  static List<Habit> getAll() => List.unmodifiable(_habits);

  static List<Habit> getByCategory(HabitCategory? category) {
    if (category == null) return getAll();
    return _habits.where((h) => h.category == category).toList();
  }

  static Habit createHabit({
    required String name,
    required HabitCategory category,
    required IconData icon,
    required Color color,
  }) {
    final habit = Habit(
      id: 'h$_nextId',
      name: name,
      category: category,
      icon: icon,
      color: color,
      currentStreak: 0,
      longestStreak: 0,
      weeklyCompletions: 0,
      weeklyTotal: 7,
      dayCompletions: [false, false, false, false, false, false, false],
      isCompletedToday: false,
    );
    _nextId++;
    _habits.insert(0, habit);
    return habit;
  }

  static void toggleCompletion(String habitId) {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = _habits[index];
    final newCompleted = !habit.isCompletedToday;

    // Update day completions (assume today is the last entry for simplicity;
    // a real implementation maps the correct weekday index)
    final updatedDays = List<bool>.from(habit.dayCompletions);
    // Shift day-completions to represent the current week's Mon-Sun.
    // For the mock we update the last (most-right) dot which represents today.
    // In a real impl this would use weekday index.
    // Given 7 dots, update index 6 (Sunday) as "today".
    const todayIndex = 6;

    updatedDays[todayIndex] = newCompleted;

    final updated = habit.copyWith(
      isCompletedToday: newCompleted,
      dayCompletions: updatedDays,
      weeklyCompletions:
          updatedDays.where((d) => d).length,
      currentStreak: newCompleted
          ? habit.currentStreak + 1
          : habit.currentStreak > 0
              ? habit.currentStreak - 1
              : 0,
    );

    _habits[index] = updated;
  }

  // ── Update and delete ──

  static void updateHabit(Habit updated) {
    final index = _habits.indexWhere((h) => h.id == updated.id);
    if (index == -1) return;
    _habits[index] = updated;
  }

  static void deleteHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
  }

  static OverviewMetrics getOverview() {
    final all = _habits;
    final completed = all.where((h) => h.isCompletedToday).length;
    final total = all.length;
    final bestStreak = all.fold(0, (int max, h) => h.longestStreak > max ? h.longestStreak : max);
    final avgWeekly = all.isEmpty
        ? 0
        : (all.fold(0.0, (sum, h) => sum + (h.weeklyCompletions / h.weeklyTotal * 100)) /
                all.length)
            .round();

    return OverviewMetrics(
      completedToday: completed,
      totalToday: total,
      currentStreak: all.isEmpty ? 0 : all[0].currentStreak,
      longestStreak: bestStreak,
      weeklyScore: avgWeekly,
    );
  }

  static List<CategoryStat> getCategoryStats() {
    return HabitCategory.values.map((cat) {
      final catHabits = _habits.where((h) => h.category == cat).toList();
      final completed = catHabits.where((h) => h.isCompletedToday).length;
      return CategoryStat(
        category: cat,
        completed: completed,
        total: catHabits.length,
      );
    }).toList();
  }

  static WeeklyProgressData getWeeklyProgress() {
    // Build daily counts from the habit day-completions arrays.
    // Index 0 = Monday … 6 = Sunday
    // Returns how many habits were completed each day of the week.
    final counts = List.filled(7, 0);
    for (final habit in _habits) {
      for (int i = 0; i < 7 && i < habit.dayCompletions.length; i++) {
        if (habit.dayCompletions[i]) counts[i]++;
      }
    }
    final max = counts.fold(0, (int a, b) => a > b ? a : b);
    return WeeklyProgressData(dailyCounts: counts, maxCount: max > 0 ? max : 1);
  }

}
