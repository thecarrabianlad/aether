import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aether/features/habits/models/habit.dart';

void main() {
  group('Habit model', () {
    test('OverviewMetrics computes fraction', () {
      const metrics = OverviewMetrics(
        completedToday: 3,
        totalToday: 6,
        currentStreak: 12,
        longestStreak: 28,
        weeklyScore: 83,
      );
      expect(metrics.completedFraction, 0.5);
    });

    test('OverviewMetrics zero-total fraction is 0', () {
      const metrics = OverviewMetrics(
        completedToday: 0,
        totalToday: 0,
        currentStreak: 0,
        longestStreak: 0,
        weeklyScore: 0,
      );
      expect(metrics.completedFraction, 0.0);
    });

    test('Habit copyWith works correctly', () {
      final habit = Habit(
        id: 't1',
        userId: 'u1',
        name: 'Test',
        category: HabitCategory.study,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
        currentStreak: 5,
        longestStreak: 10,
        weeklyCompletions: 3,
        weeklyTotal: 7,
        dayCompletions: [true, false, true, false, true, false, false],
        isCompletedToday: false,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final updated = habit.copyWith(isCompletedToday: true, currentStreak: 6);
      expect(updated.isCompletedToday, true);
      expect(updated.currentStreak, 6);
      expect(updated.name, 'Test');
      expect(updated.weeklyCompletions, 3);
    });

    test('Habit copyWith preserves unmodified fields', () {
      final habit = Habit(
        id: 't2',
        userId: 'u2',
        name: 'Meditate',
        category: HabitCategory.mind,
        icon: Icons.self_improvement,
        color: const Color(0xFFFF9500),
        currentStreak: 1,
        longestStreak: 3,
        weeklyCompletions: 2,
        weeklyTotal: 7,
        dayCompletions: [true, true, false, false, false, false, false],
        isCompletedToday: false,
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
      final updated = habit.copyWith(name: 'Deep Meditation');
      expect(updated.name, 'Deep Meditation');
      expect(updated.id, 't2');
      expect(updated.category, HabitCategory.mind);
      expect(updated.longestStreak, 3);
    });

    test('CategoryStat fraction', () {
      const stat = CategoryStat(
        category: HabitCategory.health,
        completed: 3,
        total: 5,
      );
      expect(stat.fraction, 0.6);
    });

    test('CategoryStat zero-total fraction is 0', () {
      const stat = CategoryStat(
        category: HabitCategory.study,
        completed: 0,
        total: 0,
      );
      expect(stat.fraction, 0.0);
    });

    test('HabitCategory fromLabel round-trips', () {
      expect(HabitCategoryX.fromLabel('study'), HabitCategory.study);
      expect(HabitCategoryX.fromLabel('health'), HabitCategory.health);
      expect(HabitCategoryX.fromLabel('mind'), HabitCategory.mind);
      expect(HabitCategoryX.fromLabel('unknown'), HabitCategory.study);
    });

    test('HabitCategory label and icon', () {
      expect(HabitCategory.study.label, 'Study');
      expect(HabitCategory.health.label, 'Health');
      expect(HabitCategory.mind.label, 'Mind');
      expect(HabitCategory.study.icon, Icons.menu_book_outlined);
    });
  });
}
