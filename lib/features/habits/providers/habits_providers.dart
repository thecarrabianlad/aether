import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart'; // For habitsServiceProvider
import 'package:aether/features/habits/models/habit.dart';

/// Selected category filter. `null` means "All".
final selectedCategoryProvider = StateProvider<HabitCategory?>((ref) => null);

/// The full list of habits, transformed from Drift entries and logs into UI models.
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final habitsService = ref.watch(habitsServiceProvider);

  // Watch for changes in HabitEntry table
  final habitEntriesStream = habitsService.watchHabits();

  // Combine with habit logs for each habit
  return habitEntriesStream.asyncMap((habitEntries) async {
    final List<Habit> habits = [];
    for (final entry in habitEntries) {
      final logs = await habitsService.watchLogsForHabit(entry.id).first; // Get current logs once

      // Calculate streak and completion metrics
      final Habit calculatedHabit = _calculateHabitMetrics(entry, logs);
      habits.add(calculatedHabit);
    }
    return habits;
  });
});

/// Filtered list based on selected category.
final filteredHabitsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final allHabitsAsync = ref.watch(habitsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return allHabitsAsync.whenData((habits) {
    if (selectedCategory == null) return habits;
    return habits.where((h) => h.category == selectedCategory).toList();
  });
});

/// Overview metrics derived from the full habits list.
final overviewMetricsProvider = Provider<AsyncValue<OverviewMetrics>>((ref) {
  final allHabitsAsync = ref.watch(habitsProvider);

  return allHabitsAsync.whenData((all) {
    if (all.isEmpty) {
      return const OverviewMetrics(
        completedToday: 0,
        totalToday: 0,
        currentStreak: 0,
        longestStreak: 0,
        weeklyScore: 0,
      );
    }
    final completed = all.where((h) => h.isCompletedToday).length;
    final total = all.length;
    final bestStreak = all.fold(0, (int max, h) => h.longestStreak > max ? h.longestStreak : max);

    // Calculate average weekly completion percentage
    double sumWeeklyCompletionPercentages = 0;
    int habitsWithWeeklyData = 0;
    for (final h in all) {
      if (h.weeklyTotal > 0) {
        sumWeeklyCompletionPercentages += (h.weeklyCompletions / h.weeklyTotal);
        habitsWithWeeklyData++;
      }
    }
    final avgWeekly = habitsWithWeeklyData > 0
        ? (sumWeeklyCompletionPercentages / habitsWithWeeklyData * 100).round()
        : 0;

    return OverviewMetrics(
      completedToday: completed,
      totalToday: total,
      currentStreak: all.isEmpty ? 0 : _calculateCombinedCurrentStreak(all),
      longestStreak: bestStreak,
      weeklyScore: avgWeekly,
    );
  });
});

/// Category statistics derived from the full habits list.
final categoryStatsProvider = Provider<AsyncValue<List<CategoryStat>>>((ref) {
  final allHabitsAsync = ref.watch(habitsProvider);

  return allHabitsAsync.whenData((all) {
    return HabitCategory.values.map((cat) {
      final catHabits = all.where((h) => h.category == cat).toList();
      final completed = catHabits.where((h) => h.isCompletedToday).length;
      return CategoryStat(
        category: cat,
        completed: completed,
        total: catHabits.length,
      );
    }).toList();
  });
});

/// Weekly progress chart data derived from the full habits list.
final weeklyProgressProvider = Provider<AsyncValue<WeeklyProgressData>>((ref) {
  final allHabitsAsync = ref.watch(habitsProvider);

  return allHabitsAsync.whenData((all) {
    final counts = List.filled(7, 0); // Index 0 = Monday … 6 = Sunday
    for (final habit in all) {
      for (int i = 0; i < 7 && i < habit.dayCompletions.length; i++) {
        if (habit.dayCompletions[i]) counts[i]++;
      }
    }
    final max = counts.fold(0, (int a, b) => a > b ? a : b);
    return WeeklyProgressData(dailyCounts: counts, maxCount: max > 0 ? max : 1);
  });
});

// ── Helper methods for Habit model transformation ──────────────────────────
// This could be moved into HabitsService or a dedicated transformer utility.

Habit _calculateHabitMetrics(HabitEntry entry, List<HabitLog> logs) {
  final todayDate = _normalizeDate(DateTime.now());

  // Weekly completions
  final dayCompletions = List.filled(7, false); // Mon-Sun
  int weeklyCompletions = 0;

  for (final log in logs) {
    final logDate = _normalizeDate(log.date);
    // Adjusted weekday index calculation: Monday is 0, Sunday is 6
    final weekdayIndex = (logDate.weekday - 1);

    // Check if log falls within the current week for dashboard display
    final startOfWeek = todayDate.subtract(Duration(days: todayDate.weekday - 1)); // Assuming week starts Monday
    if (logDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && logDate.isBefore(todayDate.add(const Duration(days: 1)))) {
      if (log.isCompleted) {
        if (weekdayIndex >= 0 && weekdayIndex < 7) { // Ensure index is valid
          dayCompletions[weekdayIndex] = true;
        }
        weeklyCompletions++;
      }
    }
  }

  // Current streak
  int currentStreak = 0;
  DateTime checkDate = todayDate;
  bool completedToday = logs.any((l) => _normalizeDate(l.date) == todayDate && l.isCompleted);
  if (completedToday) {
    currentStreak = 1;
    checkDate = todayDate.subtract(const Duration(days: 1));
  } else {
    // If not completed today, streak starts from 0 (if user missed today).
    // Or, if user completed yesterday but not today, streak resets.
    // This is a strict consecutive day streak.
  }

  // Check previous days for streak
  for (int i = 0; i < 30; i++) { // Max streak of 30 days for calculation purpose
    final hasLog = logs.any((l) => _normalizeDate(l.date) == checkDate && l.isCompleted);
    if (hasLog) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  // Longest streak - this should ideally be updated in the service upon streak change.
  // For now, it will use the stored longestStreak from HabitEntry.
  int longestStreak = entry.longestStreak;
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }


  return Habit(
    id: entry.id,
    userId: entry.userId,
    name: entry.name,
    category: HabitCategory.values.firstWhere((e) => e.name == entry.category),
    icon: _iconFromString(entry.icon),
    color: _colorFromString(entry.color),
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    weeklyCompletions: weeklyCompletions,
    weeklyTotal: 7,
    dayCompletions: dayCompletions,
    isCompletedToday: completedToday,
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
    reminderTime: entry.reminderTime,
    reminderDays: entry.reminderDays,
  );
}

int _calculateCombinedCurrentStreak(List<Habit> habits) {
  if (habits.isEmpty) return 0;
  // For now, return the maximum current streak found among habits
  // A more sophisticated approach might look for a "global" streak across categories
  return habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
}

DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

IconData _iconFromString(String iconName) {
  switch (iconName) {
    case 'menu_book_outlined':
      return Icons.menu_book_outlined;
    case 'favorite_border':
      return Icons.favorite_border;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'directions_run':
      return Icons.directions_run;
    case 'spa_outlined':
      return Icons.spa_outlined;
    case 'water_drop_outlined':
      return Icons.water_drop_outlined;
    case 'medication_outlined':
      return Icons.medication_outlined;
    case 'calculate_outlined':
      return Icons.calculate_outlined;
    case 'nightlight_outlined':
      return Icons.nightlight_outlined;
    default:
      return Icons.check_circle_outline; // Default icon
  }
}

Color _colorFromString(String colorHex) {
  try {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  } catch (e) {
    return Colors.red; // Default to red on error
  }
}