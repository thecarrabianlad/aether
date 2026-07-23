import 'package:aether/core/database/database.dart';
import 'package:aether/core/models/profile.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/core/services/profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final authProvider = Provider<AuthService>((ref) => AuthService.instance);

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
        if (previous?.valueOrNull?.event != next.valueOrNull?.event) {
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
