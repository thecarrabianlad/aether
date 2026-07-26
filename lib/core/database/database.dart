import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:uuid/uuid.dart';

import 'tables/courses.dart';
import 'tables/lectures.dart';
import 'tables/assignments.dart';
import 'tables/habits.dart';
import 'tables/sync_queue.dart'; // New sync queue table
import 'tables/tasks.dart';
import 'tables/schedule_templates.dart';
import 'tables/schedule_blocks.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Courses,
  Lectures,
  Assignments,
  Habits,
  HabitLogs,
  SyncQueue,
  Tasks,
  ScheduleTemplates,
  ScheduleBlocks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  @override
int get schemaVersion => 4;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),

  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(habits);
      await m.createTable(habitLogs);
    }

    if (from < 3) {
      await m.createTable(tasks);
      await m.createTable(syncQueue);
    }

    if (from < 4) {
      await m.createTable(scheduleTemplates);
      await m.createTable(scheduleBlocks);
    }
  },
);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    // Make sqlite3 pick a more suitable location for temporary files - only
    // needed for some platforms we don't support, but good to have.
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
} 