import 'package:aether/core/database/database.dart'; // Import all generated models

extension CourseExtension on Course {
  static Course fromJson(Map<String, dynamic> json) {
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
      scheduleDays: json['schedule_days'] as String?,
      scheduleStart: json['schedule_start'] as String?,
      scheduleEnd: json['schedule_end'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'user_id': userId,
        'name': name,
        'code': code,
        'professor': professor,
        'color': color,
        'icon': icon,
        'semester': semester,
        'location': location,
        'credits': credits,
        'schedule_days': scheduleDays,
        'schedule_start': scheduleStart,
        'schedule_end': scheduleEnd,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

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

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'course_id': courseId,
        'user_id': userId,
        'title': title,
        'chapter': chapter,
        'tag': tag,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

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

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'course_id': courseId,
        'user_id': userId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

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

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'user_id': userId,
        'name': name,
        'category': category,
        'icon': icon,
        'color': color,
        'longest_streak': longestStreak,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'reminder_time': reminderTime,
        'reminder_days': reminderDays,
      };

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

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'habit_id': habitId,
        'date': date.toIso8601String().split('T').first,
        'is_completed': isCompleted,
      };
}

extension GradeExtension on Grade { // New GradeExtension
  static Grade fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      gradeValue: (json['grade_value'] as num?)?.toDouble(),
      totalPoints: (json['total_points'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      feedback: json['feedback'] as String?,
      gradedAt: json['graded_at'] != null ? DateTime.parse(json['graded_at'] as String) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() => { // New toJson method
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'title': title,
        'grade_value': gradeValue,
        'total_points': totalPoints,
        'weight': weight,
        'feedback': feedback,
        'graded_at': gradedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}