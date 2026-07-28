import 'package:aether/core/database/database.dart';
import 'package:aether/core/models/profile.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/core/services/profile_service.dart';
import 'package:aether/core/services/settings_service.dart';
import 'package:aether/core/services/notification_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:aether/core/services/sync_service.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Singleton notification service — initialised in [main] before runApp.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final authProvider = Provider<AuthService>((ref) => AuthService.instance);

// Providers for other services (Academics, Habits)
// NOTE: These three providers form a dependency cycle (academics/habits need the
// sync queue to enqueue work; the queue needs them to replay it). The cycle is
// broken at runtime by the lazy callbacks passed to SyncQueueService, but Dart's
// top-level type inference still can't resolve it — so the variable types are
// written out explicitly rather than left to inference.
final Provider<AcademicsService> academicsServiceProvider =
    Provider<AcademicsService>((ref) {
  final db = ref.watch(databaseProvider);
  final syncQueueService = ref.watch(syncQueueServiceProvider);
  return AcademicsService(db, syncQueueService);
});

final Provider<HabitsService> habitsServiceProvider =
    Provider<HabitsService>((ref) {
  final db = ref.watch(databaseProvider);
  final syncQueueService = ref.watch(syncQueueServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return HabitsService(db, syncQueueService, notificationService);
});

/// Service provider for sync queue operations
final Provider<SyncQueueService> syncQueueServiceProvider =
    Provider<SyncQueueService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncQueueService(
    db,
    () => ref.read(academicsServiceProvider),
    () => ref.read(habitsServiceProvider),
  );
});

/// Service provider for sync operations
final syncServiceProvider = Provider<SyncService>((ref) {
  final academicsService = ref.watch(academicsServiceProvider);
  final habitsService = ref.watch(habitsServiceProvider);
  return SyncService(academicsService, habitsService);
});

/// Global provider for the "Add" button action in the BottomNavbar.
/// The currently active screen can override this to set its specific action.
final globalAddActionProvider = StateProvider<VoidCallback?>((ref) => null);

/// State provider for opening and closing the side drawer.
final drawerProvider = StateProvider<bool>((ref) => false);

/// Profile service provider.
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService.instance);

/// Current user's profile (null-safe, loads on demand).
final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);

/// Notifier for managing profile state.
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    return _loadProfile();
  }

  Future<Profile?> _loadProfile() async {
    final service = ref.read(profileServiceProvider);
    return service.getProfile();
  }

  /// Reload profile from server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile());
  }

  /// Update profile fields.
  Future<void> updateProfile({
    String? name,
    String? role,
    String? avatarUrl,
    bool? isPremium,
  }) async {
    final service = ref.read(profileServiceProvider);
    await service.updateProfile(
      name: name,
      role: role,
      avatarUrl: avatarUrl,
      isPremium: isPremium,
    );
    await refresh();
  }
}

/// Stream of auth state changes.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.onAuthStateChange;
});

/// Settings service, loaded once at startup and overridden in main().
final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError(
    'settingsServiceProvider must be overridden in ProviderScope',
  );
});

/// Controls the active theme (accent + background variant), persisting
/// changes through [SettingsService].
final themeControllerProvider =
    StateNotifierProvider<ThemeController, AppThemeState>((ref) {
  return ThemeController(ref.watch(settingsServiceProvider));
});

class ThemeController extends StateNotifier<AppThemeState> {
  final SettingsService _settings;

  ThemeController(this._settings) : super(_settings.themeState);

  Future<void> setAccent(AccentPreset accent) async {
    state = state.copyWith(accent: accent);
    await _settings.saveThemeState(state);
  }

  Future<void> setBackground(BackgroundVariant background) async {
    state = state.copyWith(background: background);
    await _settings.saveThemeState(state);
  }
}

/// Notification preference toggles, persisted locally.
/// When toggling [enabled] or [habits] the controller cancels or
/// re-schedules all habit reminders through [NotificationService].
final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsController, NotificationSettings>((ref) {
  return NotificationSettingsController(
    ref.watch(settingsServiceProvider),
    ref.watch(notificationServiceProvider),
    () => ref.read(habitsServiceProvider).getAllHabitEntries(),
  );
});

@immutable
class NotificationSettings {
  final bool enabled;
  final bool tasks;
  final bool habits;
  final bool lectures;

  const NotificationSettings({
    required this.enabled,
    required this.tasks,
    required this.habits,
    required this.lectures,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? tasks,
    bool? habits,
    bool? lectures,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      lectures: lectures ?? this.lectures,
    );
  }
}

class NotificationSettingsController
    extends StateNotifier<NotificationSettings> {
  final SettingsService _settings;
  final NotificationService _notificationService;
  final Future<List<HabitEntry>> Function() _getHabits;

  NotificationSettingsController(
    this._settings,
    this._notificationService,
    this._getHabits,
  ) : super(NotificationSettings(
          enabled: _settings.notificationsEnabled,
          tasks: _settings.notifyTasks,
          habits: _settings.notifyHabits,
          lectures: _settings.notifyLectures,
        ));

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _settings.setNotificationsEnabled(value);
    await _rescheduleHabits();
  }

  Future<void> setTasks(bool value) async {
    state = state.copyWith(tasks: value);
    await _settings.setNotifyTasks(value);
  }

  Future<void> setHabits(bool value) async {
    state = state.copyWith(habits: value);
    await _settings.setNotifyHabits(value);
    await _rescheduleHabits();
  }

  Future<void> setLectures(bool value) async {
    state = state.copyWith(lectures: value);
    await _settings.setNotifyLectures(value);
  }

  /// Cancel or reschedule habit reminders depending on [enabled] && [habits].
  Future<void> _rescheduleHabits() async {
    if (state.enabled && state.habits) {
      final habits = await _getHabits();
      await _notificationService.rescheduleAll(habits);
    } else {
      await _notificationService.cancelAll();
    }
  }
}

/// Last successful manual/auto sync time, for the settings page.
final lastSyncedAtProvider = StateProvider<DateTime?>((ref) {
  return ref.watch(settingsServiceProvider).lastSyncedAt;
});

/// Count of operations waiting in the offline sync queue.
final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.syncQueue).get();
  return rows.length;
});


