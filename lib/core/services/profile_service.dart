import 'dart:math';

import 'package:flutter/foundation.dart';
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

    if (response == null) {
      debugPrint('ProfileService: No profile found for user $userId');
      return null;
    }

    debugPrint('ProfileService: Profile found for user $userId: $response');
    return Profile.fromJson(response);
  }

  /// Generate a random DiceBear avatar URL.
  static String generateRandomAvatarUrl() {
    final random = Random();
    final styles = ['adventurer', 'avataaars', 'big-ears', 'bottts', 'fun-emoji', 'lorelei', 'micah'];
    final style = styles[random.nextInt(styles.length)];
    final seed = random.nextInt(1000000);
    // PNG, not SVG — Flutter's NetworkImage can't decode SVG.
    return 'https://api.dicebear.com/9.x/$style/png?seed=$seed';
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

    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (role != null) updates['role'] = role;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (isPremium != null) updates['is_premium'] = isPremium;

    if (updates.isEmpty) return; // Nothing to update

    await _client.from('profiles').update(updates).eq('id', userId);
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
          'avatar_url': avatarUrl, // Can be null, will be generated if missing
        })
        .select()
        .single();

    return Profile.fromJson(response);
  }

  /// Ensure profile exists for current user (creates with default values if missing).
  /// This is typically called after a successful login/signup.
  Future<Profile> ensureProfileExists({String? name, String? role}) async {
    final existingProfile = await getProfile();
    if (existingProfile != null) {
      return existingProfile;
    }

    // If not exists, create one with generated avatar
    return await upsertProfile(
      name: name,
      role: role,
      avatarUrl: generateRandomAvatarUrl(),
    );
  }
}
