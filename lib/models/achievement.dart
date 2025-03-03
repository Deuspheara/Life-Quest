import 'package:flutter/material.dart';

enum AchievementCategory {
  quest,
  level,
  streak,
  special,
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.quest:
        return 'Quests';
      case AchievementCategory.level:
        return 'Levels';
      case AchievementCategory.streak:
        return 'Streaks';
      case AchievementCategory.special:
        return 'Special';
    }
  }
  
  Color get color {
    switch (this) {
      case AchievementCategory.quest:
        return Colors.blue;
      case AchievementCategory.level:
        return Colors.purple;
      case AchievementCategory.streak:
        return Colors.orange;
      case AchievementCategory.special:
        return Colors.teal;
    }
  }
  
  IconData get icon {
    switch (this) {
      case AchievementCategory.quest:
        return Icons.assignment_turned_in;
      case AchievementCategory.level:
        return Icons.trending_up;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.special:
        return Icons.stars;
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int requiredLevel;
  final bool isSecret;
  final AchievementCategory category;
  final String? badgeColor; // Optional hex color for badge
  final int points;
  final Map<String, dynamic>? criteria; // For dynamic criteria checking

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.requiredLevel,
    this.isSecret = false,
    this.category = AchievementCategory.quest,
    this.badgeColor,
    this.points = 10,
    this.criteria,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // Handle possible missing fields in older database schema versions
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['icon_path'],
      requiredLevel: json['required_level'],
      isSecret: json['is_secret'] ?? false,
      category: _getCategoryFromString(json['category'] ?? 'quest'),
      badgeColor: json['badge_color'],
      points: json['points'] ?? 10,
      criteria: json['criteria'],
    );
  }

  Map<String, dynamic> toJson() {
    // Start with required fields that should exist in all schema versions
    final Map<String, dynamic> json = {
      'id': id,
      'title': title,
      'description': description,
      'icon_path': iconPath,
      'required_level': requiredLevel,
      'is_secret': isSecret,
    };
    
    // Only add newer fields if they have values
    if (badgeColor != null) {
      json['badge_color'] = badgeColor as Object;
    }
    
    json['points'] = points;
    json['category'] = category.name;
    
    if (criteria != null) {
      json['criteria'] = criteria;
    }
    
    return json;
  }

  static AchievementCategory _getCategoryFromString(String category) {
    switch (category) {
      case 'quest':
        return AchievementCategory.quest;
      case 'level':
        return AchievementCategory.level;
      case 'streak':
        return AchievementCategory.streak;
      case 'special':
        return AchievementCategory.special;
      default:
        return AchievementCategory.quest;
    }
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Achievement achievement;
  final bool isNew; // Indicates if this is newly unlocked (for animations)

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.achievement,
    this.isNew = false,
  });

  factory UserAchievement.fromJson(
      Map<String, dynamic> json, Achievement achievement) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
      achievement: achievement,
      isNew: json['is_new'] ?? false,
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