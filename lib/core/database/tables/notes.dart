import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/tables/courses.dart';

@DataClassName('Note')
class Notes extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get courseId => text().nullable().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
