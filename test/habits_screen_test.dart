import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/models/habit_repository.dart';
import 'package:aether/features/habits/screens/habits_screen.dart';

Widget createTestApp() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: HabitsScreen()),
    ),
  );
}

void main() {
  // Clear repository between tests to avoid cross-contamination.
  setUp(() {
    while (HabitRepository.getAll().isNotEmpty) {
      HabitRepository.deleteHabit(HabitRepository.getAll().first.id);
    }
    HabitRepository.resetIdCounter();
  });

  group('HabitsScreen', () {
    testWidgets('renders header and overview with empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Header
      expect(find.text('HABIT TRACKER'), findsOneWidget);

      // Date navigator
      expect(find.text('Today'), findsOneWidget);

      // Overview section title
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);

      // Category section title
      expect(find.text("Today's Habits"), findsOneWidget);

      // Empty state — no habits
      expect(find.text('No habits yet.'), findsOneWidget);
    });

    testWidgets('no seed habits by default', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Read'), findsNothing);
      expect(find.text('Meditate'), findsNothing);
      expect(find.text('Running'), findsNothing);
      expect(find.text('Skincare'), findsNothing);
      expect(find.text('No Sugar'), findsNothing);
      expect(find.text('Study Math'), findsNothing);
      expect(find.text('Medication'), findsNothing);
    });

    testWidgets('Add New Habit tile opens create dialog', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Scroll down to the Add New Habit tile
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -800));
      await tester.pump();

      await tester.tap(find.text('Add New Habit').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Habit'), findsAtLeast(1));
    });

    testWidgets('add habit then edit it', (tester) async {
      // Create a habit first
      HabitRepository.createHabit(
        name: 'Test Habit',
        category: HabitCategory.health,
        icon: Icons.favorite_border,
        color: const Color(0xFF34C759),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Test Habit'), findsOneWidget);

      // Open 3-dot menu and tap Edit
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should be pre-filled
      expect(find.text('Edit Habit'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Clean up
      HabitRepository.deleteHabit(HabitRepository.getAll().first.id);
    });

    testWidgets('add habit then delete it', (tester) async {
      HabitRepository.createHabit(
        name: 'Delete Me',
        category: HabitCategory.study,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Delete Me'), findsOneWidget);

      // Open 3-dot menu and tap Delete
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm deletion
      await tester.tap(find.text('Delete').last);
      await tester.pump();

      expect(find.text('Delete Me'), findsNothing);
    });
  });

  group('Habit model', () {
    test('OverviewMetrics computes fraction', () {
      const metrics = OverviewMetrics(
        completedToday: 3,
        totalToday: 6,
        currentStreak: 12,
        longestStreak: 28,
        weeklyScore: 83,
      );
      expect(metrics.completedFraction, 0.5);
    });

    test('Habit copyWith works correctly', () {
      final habit = Habit(
        id: 't1',
        name: 'Test',
        category: HabitCategory.study,
        icon: Icons.menu_book_outlined,
        color: Color(0xFF8B5CF6),
        currentStreak: 5,
        longestStreak: 10,
        weeklyCompletions: 3,
        weeklyTotal: 7,
        dayCompletions: [true, false, true, false, true, false, false],
        isCompletedToday: false,
      );
      final updated = habit.copyWith(isCompletedToday: true, currentStreak: 6);
      expect(updated.isCompletedToday, true);
      expect(updated.currentStreak, 6);
      expect(updated.name, 'Test');
      expect(updated.weeklyCompletions, 3);
    });

    test('CategoryStat fraction', () {
      const stat = CategoryStat(
        category: HabitCategory.health,
        completed: 3,
        total: 5,
      );
      expect(stat.fraction, 0.6);
    });
  });

  group('HabitRepository operations', () {
    setUp(() {
      // Ensure empty state for each test
      while (HabitRepository.getAll().isNotEmpty) {
        HabitRepository.deleteHabit(HabitRepository.getAll().first.id);
      }
    });

    test('starts empty', () {
      expect(HabitRepository.getAll(), isEmpty);
    });

    test('create and get', () {
      HabitRepository.createHabit(
        name: 'My Habit',
        category: HabitCategory.study,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
      );
      expect(HabitRepository.getAll().length, 1);
      expect(HabitRepository.getAll().first.name, 'My Habit');
    });

    test('delete removes habit', () {
      HabitRepository.createHabit(
        name: 'Temp',
        category: HabitCategory.health,
        icon: Icons.favorite_border,
        color: const Color(0xFF34C759),
      );
      final id = HabitRepository.getAll().first.id;
      HabitRepository.deleteHabit(id);
      expect(HabitRepository.getAll(), isEmpty);
    });

    test('update changes habit', () {
      final habit = HabitRepository.createHabit(
        name: 'Original',
        category: HabitCategory.study,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
      );
      HabitRepository.updateHabit(habit.copyWith(name: 'Updated'));
      expect(HabitRepository.getAll().first.name, 'Updated');
    });
  });
}
