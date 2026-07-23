import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';

/// Offline-first service for habits.
class HabitsService {
  final AppDatabase _db;

  HabitsService(this._db);

  Stream<List<Habit>> watchHabits() =>
      _db.select(_db.habits).watch().asyncMap((rows) async {
        final results = <Habit>[];
        for (final row in rows) {
          final logs = await _getLogsForHabit(row.id);
          results.add(_habitFromRow(row, logs));
        }
        return results;
      });

  Future<void> createHabit({
    required String name,
    required HabitCategory category,
    required IconData icon,
    required Color color,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.habits).insert(HabitsCompanion.insert(
          userId: '',
          name: name,
          category: category.name,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> toggleCompletion(String habitId, bool completed) async {
    final today = _normalizeDate(DateTime.now());

    // Check for existing log for today
    final existing = await (_db.select(_db.habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.date.equals(today)))
        .get();

    if (existing.isNotEmpty) {
      await (_db.update(_db.habitLogs)
            ..where((l) => l.id.equals(existing.first.id)))
          .write(HabitLogsCompanion(
        isCompleted: Value(completed),
      ));
    } else {
      await _db.into(_db.habitLogs).insert(HabitLogsCompanion.insert(
            habitId: habitId,
            date: today,
          ));
    }

    await (_db.update(_db.habits)..where((h) => h.id.equals(habitId)))
        .write(HabitsCompanion(
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<List<HabitLog>> _getLogsForHabit(String habitId) async {
    final weekStart =
        _normalizeDate(DateTime.now().subtract(const Duration(days: 6)));
    return (_db.select(_db.habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.date.isBiggerOrEqualValue(weekStart))
          ..orderBy([(l) => OrderingTerm(expression: l.date)]))
        .get();
  }

  Habit _habitFromRow(HabitEntry row, List<HabitLog> logs) {
    final category = HabitCategory.values.firstWhere(
      (c) => c.name == row.category,
      orElse: () => HabitCategory.study,
    );
    final colorInt = int.tryParse(row.color.replaceFirst('#', '0xFF')) ??
        0xFFE8443F;

    final dayCompletions = List.filled(7, false);
    int weeklyCompletions = 0;
    final todayDate = _normalizeDate(DateTime.now());

    for (final log in logs) {
      final logDate = _normalizeDate(log.date);
      final diff = todayDate.difference(logDate).inDays;
      if (diff >= 0 && diff < 7) {
        final idx = 6 - diff;
        dayCompletions[idx] = log.isCompleted;
        if (log.isCompleted) weeklyCompletions++;
      }
    }

    final todayLog = logForDate(logs, todayDate);

    int currentStreak = 0;
    for (int i = 0; i < 30; i++) {
      final checkDate = todayDate.subtract(Duration(days: i));
      final hasLog = logs.any(
          (l) => _normalizeDate(l.date) == checkDate && l.isCompleted);
      if (hasLog) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }

    return Habit(
      id: row.id,
      name: row.name,
      category: category,
      icon: Icons.menu_book_outlined,
      color: Color(colorInt),
      currentStreak: currentStreak,
      longestStreak: row.longestStreak,
      weeklyCompletions: weeklyCompletions,
      weeklyTotal: 7,
      dayCompletions: dayCompletions,
      isCompletedToday: todayLog,
    );
  }

  bool logForDate(List<HabitLog> logs, DateTime date) {
    return logs.any(
        (l) => _normalizeDate(l.date) == date && l.isCompleted);
  }

  DateTime _normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
