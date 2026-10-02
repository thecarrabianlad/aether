import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/tables/courses.dart';

@DataClassName('FlashcardDeck')
class FlashcardDecks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get courseId => text().nullable().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Flashcard')
class Flashcards extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get deckId => text().references(FlashcardDecks, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  // Spaced repetition fields
  IntColumn get intervalDays => integer().withDefault(const Constant(1))();
  IntColumn get easeFactor => integer().withDefault(const Constant(250))(); // 2.5 * 100
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
