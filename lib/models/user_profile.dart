class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final int level;
  final int experience;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.level,
    required this.experience,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate the experience needed for the next level
  // This is a simple exponential formula, can be adjusted
  int get experienceForNextLevel => (1000 * (level * 0.5)).toInt();

  // Progress from 0.0 to 1.0 for current level
  double get levelProgress {
    return experience / experienceForNextLevel;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'level': level,
      'experience': experience,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    int? level,
    int? experience,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}