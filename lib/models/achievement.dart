import 'package:flutter/material.dart';

// In lib/models/achievement.dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int requiredLevel;
  final bool isSecret;
  final int experienceReward;
  final String category;
  
  // Change the type from String to dynamic to handle both formats
  final dynamic criteria;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.requiredLevel,
    this.isSecret = false,
    this.experienceReward = 50,
    this.category = 'general',
    this.criteria = '',
    this.color = Colors.amber,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['icon_path'],
      requiredLevel: json['required_level'],
      isSecret: json['is_secret'] ?? false,
      experienceReward: json['experience_reward'] ?? 50,
      category: json['category'] ?? 'general',
      
      // Handle criteria field that can be String or Map
      criteria: json['criteria'] ?? '',
      
      // Parse color from integer
      color: json['color'] != null ? Color(json['color']) : Colors.amber,
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
      'experience_reward': experienceReward,
      'category': category,
      'criteria': criteria,
      'color': color.value,
    };
  }

  // Helper method to get criteria as a string
  String getCriteriaAsString() {
    if (criteria == null) return '';
    if (criteria is String) return criteria;
    if (criteria is Map) {
      return criteria['requirement'] ?? '';
    }
    return criteria.toString();
  }
}
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  // New field
  final double progress;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.progress = 1.0,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
      progress: (json['progress'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'progress': progress,
    };
  }
}

// Combined achievement with unlocked status
class AchievementWithStatus {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;

  const AchievementWithStatus({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0.0,
  });
}