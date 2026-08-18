// ignore_for_file: unused_import, unnecessary_type_check, duplicate_ignore
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Using mocktail
import 'package:drift/drift.dart' hide Column; // hide Column to avoid conflict with flutter Column
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:aether/core/database/tables/courses.dart'; // Import Courses for mocking references

// Mocks for mocktail
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSyncQueueService extends Mock implements SyncQueueService {}

// We need a specific mock for PostgrestFilterBuilder that allows chaining
// and returns itself for non-execute methods, and a PostgrestResponse for execute.
// This is similar to the custom Mockito class, but for mocktail.
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #select ||
        invocation.memberName == #eq ||
        invocation.memberName == #upsert ||
        invocation.memberName == #update ||
        invocation.memberName == #delete ||
        invocation.memberName == #order) {
      return this; // Return self for chaining
    }
    // For execute, it should return a Future<PostgrestResponse>
    // For other methods, use default behavior
    return super.noSuchMethod(invocation);
  }
}

class MockPostgrestResponse extends Mock implements PostgrestResponse<List<Map<String, dynamic>>> {}


void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late MockSyncQueueService mockSyncQueueService;
  late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;
  late MockPostgrestResponse mockPostgrestResponse;
  late AppDatabase db;
  late AcademicsService academicsService;

  setUpAll(() {
    // Register fallbacks for Uuid and DateTime for mocktail
    registerFallbackValue(SyncEntityType.assignment);
    registerFallbackValue(SyncOperation.insert);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    // Initialize in-memory database for Drift
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Mock Supabase components
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    mockSyncQueueService = MockSyncQueueService();
    mockPostgrestFilterBuilder = MockPostgrestFilterBuilder();
    mockPostgrestResponse = MockPostgrestResponse();


    // Mock SupabaseClient interactions
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test_user_id');

    // Mock the chained Supabase calls
    // SupabaseClient.from(tableName) returns MockPostgrestFilterBuilder
    when(() => mockSupabaseClient.from(any())).thenReturn(mockPostgrestFilterBuilder);

    // Any select/upsert/update/delete/eq/order call on the builder returns the builder itself
    // to allow chaining, and finally execute() returns a mock response.
    when(() => mockPostgrestFilterBuilder.select(any()))
        .thenReturn(mockPostgrestFilterBuilder);
    when(() => mockPostgrestFilterBuilder.eq(any(), any()))
        .thenReturn(mockPostgrestFilterBuilder);
    when(() => mockPostgrestFilterBuilder.upsert(any()))
        .thenReturn(mockPostgrestFilterBuilder);
    when(() => mockPostgrestFilterBuilder.update(any()))
        .thenReturn(mockPostgrestFilterBuilder);
    when(() => mockPostgrestFilterBuilder.delete())
        .thenReturn(mockPostgrestFilterBuilder);
    when(() => mockPostgrestFilterBuilder.order(any(), ascending: any(named: 'ascending')))
        .thenReturn(mockPostgrestFilterBuilder); // Added order for lecture/assignment watch
    when(() => mockPostgrestFilterBuilder.execute())
        .thenAnswer((_) async => mockPostgrestResponse);
    when(() => mockPostgrestResponse.data).thenReturn([]); // Default empty data

    // Make sure syncQueueService.enqueue doesn't throw during creation
    when(() => mockSyncQueueService.enqueue(
      entityType: any(named: 'entityType'),
      operation: any(named: 'operation'),
      entityId: any(named: 'entityId'),
      payload: any(named: 'payload'),
    )).thenAnswer((_) async => {});


    academicsService = AcademicsService(db, mockSyncQueueService);
  });

  tearDown(() async {
    await db.close();
    reset(mockSupabaseClient);
    reset(mockGoTrueClient);
    reset(mockUser);
    reset(mockSyncQueueService);
    reset(mockPostgrestFilterBuilder);
    reset(mockPostgrestResponse);
  });

  group('AcademicsService Grades', () {
    const courseId = 'course_id_1';
    const userId = 'test_user_id';

    // Helper to create a course because grades are linked to courses
    Future<Course> createTestCourse(String id) async {
      final course = Course(
        id: id,
        userId: userId,
        name: 'Test Course',
        color: '#000000', // Added default color
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.into(db.courses).insert(course);
      return course;
    }

    test('createGrade inserts grade into local DB and pushes to Supabase', () async {
      await createTestCourse(courseId); // Ensure course exists

      final newGrade = await academicsService.createGrade(
        courseId: courseId,
        title: 'Midterm',
        gradeValue: 85.0,
        totalPoints: 100.0,
      );

      final grades = await academicsService.watchGrades(courseId).first;
      expect(grades.length, 1);
      expect(grades.first.title, 'Midterm');
      expect(grades.first.gradeValue, 85.0);
      expect(grades.first.totalPoints, 100.0);
      expect(grades.first.courseId, courseId);

      // Verify the full chain for upsert
      verify(() => mockSupabaseClient.from(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.upsert(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.execute()).called(1);

      verify(() => mockSyncQueueService.enqueue(
        entityType: SyncEntityType.grade,
        operation: SyncOperation.insert,
        entityId: newGrade.id,
        payload: any(named: 'payload'),
      )).called(1);
    });

    test('watchGrades streams grades for a course', () async {
      await createTestCourse(courseId); // Ensure course exists

      // Clear previous enqueues to avoid confusion in this test
      clearInteractions(mockSyncQueueService);

      final grade1 = await academicsService.createGrade(
        courseId: courseId,
        title: 'Quiz 1',
        gradeValue: 90.0,
      );
      final grade2 = await academicsService.createGrade(
        courseId: courseId,
        title: 'Homework 1',
        gradeValue: 95.0,
      );

      final gradesStream = academicsService.watchGrades(courseId);

      final emittedGrades = await gradesStream.firstWhere((list) => list.length == 2);
      expect(emittedGrades.any((g) => g.id == grade1.id && g.gradeValue == 90.0), true);
      expect(emittedGrades.any((g) => g.id == grade2.id && g.gradeValue == 95.0), true);
    });

    test('updateGrade updates local DB and pushes to Supabase', () async {
      await createTestCourse(courseId); // Ensure course exists

      final grade = await academicsService.createGrade(
        courseId: courseId,
        title: 'Exam',
        gradeValue: 70.0,
      );

      final updatedGrade = grade.copyWith(gradeValue: Value(80.0), updatedAt: DateTime.now());

      await academicsService.updateGrade(updatedGrade);

      final grades = await academicsService.watchGrades(courseId).first;
      expect(grades.length, 1);
      expect(grades.first.gradeValue, 80.0);

      // Verify the full chain for update
      verify(() => mockSupabaseClient.from(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.update(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.eq('id', updatedGrade.id)).called(1);
      verify(() => mockPostgrestFilterBuilder.execute()).called(1);

      verify(() => mockSyncQueueService.enqueue(
        entityType: SyncEntityType.grade,
        operation: SyncOperation.update,
        entityId: updatedGrade.id,
        payload: any(named: 'payload'),
      )).called(1);
    });

    test('deleteGrade removes from local DB and pushes to Supabase', () async {
      await createTestCourse(courseId); // Ensure course exists

      final grade = await academicsService.createGrade(
        courseId: courseId,
        title: 'Final',
        gradeValue: 88.0,
      );

      await academicsService.deleteGrade(grade.id);

      final grades = await academicsService.watchGrades(courseId).first;
      expect(grades.isEmpty, true);

      // Verify the full chain for delete
      verify(() => mockSupabaseClient.from(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.delete()).called(1);
      verify(() => mockPostgrestFilterBuilder.eq('id', grade.id)).called(1);
      verify(() => mockPostgrestFilterBuilder.execute()).called(1);

      verify(() => mockSyncQueueService.enqueue(
        entityType: SyncEntityType.grade,
        operation: SyncOperation.delete,
        entityId: grade.id,
        payload: null,
      )).called(1);
    });

    test('syncGrades fetches from Supabase and updates local DB', () async {
      await createTestCourse(courseId); // Ensure course exists

      // Mock remote data
      final remoteGrades = [
        {
          'id': 'remote_grade_1',
          'user_id': userId,
          'course_id': courseId,
          'title': 'Remote Exam',
          'grade_value': 75.0,
          'total_points': 100.0,
          'weight': 1.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      when(() => mockPostgrestResponse.data).thenReturn(remoteGrades); // Set specific data for this call for syncGrades

      await academicsService.syncGrades(courseId: courseId);

      final grades = await academicsService.watchGrades(courseId).first;
      expect(grades.length, 1);
      expect(grades.first.title, 'Remote Exam');
      expect(grades.first.gradeValue, 75.0);

      // Verify the full chain for select
      verify(() => mockSupabaseClient.from(any())).called(1);
      verify(() => mockPostgrestFilterBuilder.select()).called(1);
      verify(() => mockPostgrestFilterBuilder.eq('course_id', courseId)).called(1);
      verify(() => mockPostgrestFilterBuilder.execute()).called(1);
    });
  });
}
