class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int requiredLevel;
  final bool isSecret;
  final int points;
  final String category;
  final String? badgeColor;
  final Map<String, dynamic>? criteria;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.requiredLevel,
    this.isSecret = false,
    this.points = 10,
    this.category = 'quest',
    this.badgeColor,
    this.criteria,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['icon_path'],
      requiredLevel: json['required_level'],
      isSecret: json['is_secret'] ?? false,
      points: json['points'] ?? 10,
      category: json['category'] ?? 'quest',
      badgeColor: json['badge_color'],
      criteria: json['criteria'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_path': iconPath,
      'required_level': requiredLevel,
      'is_secret': isSecret,
      'points': points,
      'category': category,
      'badge_color': badgeColor,
      'criteria': criteria,
    };
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}