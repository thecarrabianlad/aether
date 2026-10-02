import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// One exercise on one weekday of the user's workout plan.
///
/// Sets are stored as a JSON-encoded string (see `health_codec.dart` for the
/// encode/decode helpers) rather than a separate table — a plan doesn't need
/// historical rows per set, just "here is this exercise's current sets",
/// which mirrors how `Course.scheduleDays` stores a compact string instead
/// of a child table.
@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  IntColumn get weekday => integer()(); // 1 = Monday .. 7 = Sunday (DateTime.weekday)
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'reps' | 'timed'
  TextColumn get setsJson => text()(); // JSON-encoded List<Map> of sets
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
