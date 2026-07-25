import 'package:aether/core/database/database.dart';
import 'package:aether/core/models/profile.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/core/services/profile_service.dart';
import 'package:aether/core/services/sync_queue_service.dart'; // New SyncQueueService
import 'package:aether/core/services/sync_service.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // Added for VoidCallback

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
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
  return HabitsService(db, syncQueueService);
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

/// Global drawer state provider
final drawerProvider = StateProvider<bool>((ref) => false);

/// Profile service provider
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService.instance);

/// Current user's profile (null-safe, loads on demand)
final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);

/// Notifier for managing profile state
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Listen to auth state changes to invalidate and reload the profile
    ref.listen<AsyncValue<AuthState>>(
      authStateChangesProvider,
      (previous, next) {
        // Only invalidate if the auth state actually changed (e.g., logged in/out)
        // This prevents unnecessary reloads on transient AsyncValue states
        if (previous?.value?.event != next.value?.event) {
          ref.invalidateSelf();
        }
      },
    );

    // Load profile on initialization
    return _loadProfile();
  }

  Future<Profile?> _loadProfile() async {
    final service = ref.read(profileServiceProvider);
    return service.getProfile();
  }

  /// Reload profile from server
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile());
  }

  /// Update profile fields
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

/// Stream of auth state changes
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.onAuthStateChange;
});

/// Global provider for the "Add" button action in the BottomNavbar.
/// The currently active screen can override this to set its specific action.
final globalAddActionProvider = StateProvider<VoidCallback?>((ref) => _defaultAddAction);

void _defaultAddAction() {
  // Fallback — screens should override this in build().
}
