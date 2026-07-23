import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('HabitEntry')
class Habits extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()(); // 'study' | 'health' | 'mind'
  TextColumn get icon => text().withDefault(const Constant('menu_book_outlined'))();
  TextColumn get color => text().withDefault(const Constant('#E8443F'))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HabitLog')
class HabitLogs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'UNIQUE(habit_id, date)',
      ];
}
