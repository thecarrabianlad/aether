import 'dart:convert';

import 'package:aether/core/database/database.dart' show WorkoutExercise;

// ── Models ─────────────────────────────────────────────────────

enum ExerciseType {
  reps,
  timed;

  String get dbValue => name; // 'reps' | 'timed'

  static ExerciseType fromDb(String value) =>
      ExerciseType.values.firstWhere((t) => t.dbValue == value,
          orElse: () => ExerciseType.reps);
}

enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get short => switch (this) {
        Weekday.monday => 'Mon',
        Weekday.tuesday => 'Tue',
        Weekday.wednesday => 'Wed',
        Weekday.thursday => 'Thu',
        Weekday.friday => 'Fri',
        Weekday.saturday => 'Sat',
        Weekday.sunday => 'Sun',
      };

  String get full => switch (this) {
        Weekday.monday => 'Monday',
        Weekday.tuesday => 'Tuesday',
        Weekday.wednesday => 'Wednesday',
        Weekday.thursday => 'Thursday',
        Weekday.friday => 'Friday',
        Weekday.saturday => 'Saturday',
        Weekday.sunday => 'Sunday',
      };

  /// DateTime.weekday is 1 (Mon) .. 7 (Sun) — matches this enum's order,
  /// and is also how weekday is stored in the `workout_exercises` table.
  int get dbValue => index + 1;

  static Weekday fromDateTime(DateTime d) => Weekday.values[d.weekday - 1];
  static Weekday fromDb(int value) => Weekday.values[value - 1];
}

/// One row of a set: for reps-type exercises this is reps (or "to
/// failure") at a given weight; for timed-type it's a hold duration.
/// Kept per-set so e.g. a pyramid set (10@20kg, 8@25kg, 6@30kg) or a
/// last set taken to failure can differ from the sets before it.
class SetEntry {
  final int? reps; // reps type only; null when toFailure is true
  final bool toFailure; // reps type only
  final double? weight; // reps type only; null/0 = bodyweight
  final int? durationSeconds; // timed type only

  const SetEntry({
    this.reps,
    this.toFailure = false,
    this.weight,
    this.durationSeconds,
  });

  String describe(ExerciseType type) {
    if (type == ExerciseType.timed) return '${durationSeconds ?? 0}s';
    final repPart = toFailure ? 'Failure' : '${reps ?? 0}';
    final weightPart =
        (weight == null || weight == 0) ? 'BW' : '${_fmtWeight(weight!)}kg';
    return '$repPart × $weightPart';
  }

  static String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'toFailure': toFailure,
        'weight': weight,
        'durationSeconds': durationSeconds,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        reps: json['reps'] as int?,
        toFailure: json['toFailure'] as bool? ?? false,
        weight: (json['weight'] as num?)?.toDouble(),
        durationSeconds: json['durationSeconds'] as int?,
      );
}

class Exercise {
  final String id;
  final String name;
  final ExerciseType type;
  final List<SetEntry> sets;
  final bool isCompleted;

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.sets,
    this.isCompleted = false,
  });

  Exercise copyWith({
    String? name,
    ExerciseType? type,
    List<SetEntry>? sets,
    bool? isCompleted,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// e.g. "3 sets × 10 × 20kg" when every set matches, otherwise
  /// "10×20kg, 8×25kg, Failure×30kg" so pyramid/failure sets show through.
  String get subtitle {
    final parts = sets.map((s) => s.describe(type)).toList();
    if (parts.toSet().length == 1) {
      return '${sets.length} ${sets.length == 1 ? 'set' : 'sets'} × ${parts.first}';
    }
    return parts.join(', ');
  }

  /// Builds the UI model from a persisted Drift row.
  factory Exercise.fromRow(WorkoutExercise row) {
    final decoded = jsonDecode(row.setsJson) as List<dynamic>;
    return Exercise(
      id: row.id,
      name: row.name,
      type: ExerciseType.fromDb(row.type),
      sets: decoded
          .map((e) => SetEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: row.isCompleted,
    );
  }

  String get setsJson => jsonEncode(sets.map((s) => s.toJson()).toList());
}
