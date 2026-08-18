import 'package:drift/drift.dart';
import 'package:aether/core/database/tables/courses.dart'; // Import Courses for reference

@DataClassName('Grade')
class Grades extends Table {
  TextColumn get id => text()(); // Simplified, primaryKey handles UNIQUE and NOT NULL
  TextColumn get userId => text()(); // Removed references for userId for now, as there's no explicit User table
  TextColumn get courseId => text().references(Courses, #id)(); // References Courses.id
  TextColumn get title => text().withLength(min: 1, max: 255)();
  RealColumn get gradeValue => real().nullable()();
  RealColumn get totalPoints => real().nullable()();
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  TextColumn get feedback => text().nullable()();
  DateTimeColumn get gradedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
