import 'package:aether/core/database/database.dart'; // Import all generated models

extension CourseExtension on Course {
  static Course fromJson(Map<String, dynamic> json) {
    // scheduleDays is stored as a comma-separated string (TextColumn nullable)
    return Course(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      professor: json['professor'] as String?,
      color: json['color'] as String,
      icon: json['icon'] as String?,
      semester: json['semester'] as String?,
      location: json['location'] as String?,
      credits: json['credits'] as int?,
      scheduleDays: json['schedule_days'] as String?, // Stored as comma-separated string
      scheduleStart: json['schedule_start'] as String?,
      scheduleEnd: json['schedule_end'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}

extension LectureExtension on Lecture {
  static Lecture fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      chapter: json['chapter'] as String?,
      tag: json['tag'] as String?,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      durationMinutes: json['duration_minutes'] as int? ?? 90,
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}

extension AssignmentExtension on Assignment {
  static Assignment fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}

extension HabitEntryExtension on HabitEntry {
  static HabitEntry fromJson(Map<String, dynamic> json) {
    return HabitEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      longestStreak: json['longest_streak'] as int,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      reminderTime: json['reminder_time'] as String?,
      reminderDays: json['reminder_days'] as String?,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}

extension HabitLogExtension on HabitLog {
  static HabitLog fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['is_completed'] as bool,
    );
  }
}
