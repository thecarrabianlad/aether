import 'package:flutter/material.dart';

enum HabitCategory {
  study,
  health,
  mind,
}

extension HabitCategoryX on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.study:
        return 'Study';
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.mind:
        return 'Mind';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.study:
        return Icons.menu_book_outlined;
      case HabitCategory.health:
        return Icons.favorite_border;
      case HabitCategory.mind:
        return Icons.self_improvement;
    }
  }

  Color get color {
    switch (this) {
      case HabitCategory.study:
        return const Color(0xFF8B5CF6); // purple
      case HabitCategory.health:
        return const Color(0xFF34C759); // green
      case HabitCategory.mind:
        return const Color(0xFFFF9500); // orange
    }
  }

  static HabitCategory fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'study':
        return HabitCategory.study;
      case 'health':
        return HabitCategory.health;
      case 'mind':
        return HabitCategory.mind;
      default:
        return HabitCategory.study;
    }
  }
}

class Habit {
  final String id;
  final String name;
  final HabitCategory category;
  final IconData icon;
  final Color color;
  final int currentStreak;
  final int longestStreak;
  final int weeklyCompletions; // completed count this week
  final int weeklyTotal; // total days in week with data (usually 7)
  final List<bool> dayCompletions; // Mon-Sun (index 0 = Monday)
  final bool isCompletedToday;

  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyCompletions,
    required this.weeklyTotal,
    required this.dayCompletions,
    required this.isCompletedToday,
  });

  Habit copyWith({
    String? id,
    String? name,
    HabitCategory? category,
    IconData? icon,
    Color? color,
    int? currentStreak,
    int? longestStreak,
    int? weeklyCompletions,
    int? weeklyTotal,
    List<bool>? dayCompletions,
    bool? isCompletedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
      weeklyTotal: weeklyTotal ?? this.weeklyTotal,
      dayCompletions: dayCompletions ?? this.dayCompletions,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }
}

class OverviewMetrics {
  final int completedToday;
  final int totalToday;
  final int currentStreak;
  final int longestStreak;
  final int weeklyScore; // 0-100

  const OverviewMetrics({
    required this.completedToday,
    required this.totalToday,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyScore,
  });

  double get completedFraction =>
      totalToday > 0 ? completedToday / totalToday : 0.0;
}

class CategoryStat {
  final HabitCategory category;
  final int completed;
  final int total;

  const CategoryStat({
    required this.category,
    required this.completed,
    required this.total,
  });

  double get fraction => total > 0 ? completed / total : 0.0;
}

class WeeklyProgressData {
  final List<int> dailyCounts; // Mon-Sun
  final int maxCount;

  const WeeklyProgressData({
    required this.dailyCounts,
    required this.maxCount,
  });
}
