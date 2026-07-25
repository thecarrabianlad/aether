/// User profile data from Supabase profiles table.
class Profile {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      role: json['role'] as String? ?? 'Student',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
