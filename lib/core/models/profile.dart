/// User profile data from Supabase profiles table.
class Profile {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isPremium;

  const Profile({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.isPremium,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      role: json['role'] as String? ?? 'Student',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
    };
  }

  Profile copyWith({
    String? name,
    String? role,
    String? avatarUrl,
    bool? isPremium,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
