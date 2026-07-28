import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/tables/courses.dart';

@DataClassName('PastPaper')
class PastPapers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get courseId => text().nullable().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get year => text().nullable()();
  TextColumn get examType => text().nullable()();
  TextColumn get fileUrl => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
