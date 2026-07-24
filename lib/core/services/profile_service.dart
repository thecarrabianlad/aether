import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aether/core/models/profile.dart';

/// Service for managing user profiles in Supabase.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Get the current user's profile.
  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return Profile.fromJson(response);
  }

  /// Generate a random DiceBear avatar URL.
  static String generateRandomAvatarUrl() {
    final random = Random();
    final styles = ['adventurer', 'avataaars', 'big-ears', 'bottts', 'fun-emoji', 'lorelei', 'micah'];
    final style = styles[random.nextInt(styles.length)];
    final seed = random.nextInt(1000000);
    return 'https://api.dicebear.com/9.x/$style/svg?seed=$seed';
  }

  /// Stream profile changes in real-time.
  Stream<Profile?> get profileStream {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
  }

  /// Update the current user's profile.
  Future<void> updateProfile({
    String? name,
    String? role,
    String? avatarUrl,
    bool? isPremium,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (role != null) updates['role'] = role;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (isPremium != null) updates['is_premium'] = isPremium;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Create a profile for the current user (if it doesn't exist).
  Future<Profile> createProfile({String? name, String? role}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'name': name ?? _client.auth.currentUser?.email?.split('@').first ?? 'User',
          'role': role ?? 'Student',
        })
        .select()
        .single();

    return Profile.fromJson(response);
  }

  /// Upsert profile (create if not exists, update if exists).
  Future<Profile> upsertProfile({String? name, String? role, String? avatarUrl}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('profiles')
        .upsert({
          'id': userId,
          'name': name ?? _client.auth.currentUser?.email?.split('@').first ?? 'User',
          'role': role ?? 'Student',
          'avatar_url': avatarUrl ?? generateRandomAvatarUrl(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Profile.fromJson(response);
  }

  /// Ensure profile exists for current user (creates with default values if missing).
  Future<Profile> ensureProfileExists({String? name, String? role}) async {
    // First try to get existing profile
    final existingProfile = await getProfile();
    if (existingProfile != null) {
      return existingProfile;
    }

    // If not exists, create one
    return await upsertProfile(
      name: name,
      role: role,
      avatarUrl: generateRandomAvatarUrl(),
    );
  }
}
