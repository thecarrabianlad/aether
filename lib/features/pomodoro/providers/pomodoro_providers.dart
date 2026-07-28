import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/pomodoro/services/pomodoro_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pomodoroServiceProvider = Provider<PomodoroService>((ref) {
  final db = ref.watch(databaseProvider);
  return PomodoroService(db);
});

final todaySessionsProvider = StreamProvider<List<PomodoroSession>>((ref) {
  final service = ref.watch(pomodoroServiceProvider);
  return service.watchTodaySessions();
});

final recentSessionsProvider = StreamProvider<List<PomodoroSession>>((ref) {
  final service = ref.watch(pomodoroServiceProvider);
  return service.watchRecentSessions();
});