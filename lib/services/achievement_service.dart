import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

// Provider for user achievements
final userAchievementsProvider = FutureProvider.autoDispose<List<UserAchievement>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];
  
  try {
    // Fetch user achievements joined with achievement details
    final response = await SupabaseService.client
        .from('user_achievements')
        .select('*, achievements(*)')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);
    
    ErrorHandler.logInfo('Fetched user achievements: $response');
    
    // Convert to List<UserAchievement>
    final List<UserAchievement> userAchievements = [];
    
    for (final item in response) {
      final achievement = Achievement.fromJson(item['achievements']);
      final userAchievement = UserAchievement(
        id: item['id'],
        userId: item['user_id'],
        achievementId: item['achievement_id'],
        unlockedAt: DateTime.parse(item['unlocked_at']),
      );
      
      // Add to list
      userAchievements.add(userAchievement);
    }
    
    return userAchievements;
  } catch (e) {
    ErrorHandler.logError('Failed to fetch user achievements', e);
    return [];
  }
});

// Provider for all available achievements
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  try {
    final response = await SupabaseService.achievements
        .select()
        .order('required_level', ascending: true);
    
    ErrorHandler.logInfo('Fetched achievements: $response');
    
    // Convert to List<Achievement>
    final List<Map<String, dynamic>> typedData =
        (response as List).map((item) => item as Map<String, dynamic>).toList();
    
    return typedData.map((json) => Achievement.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch achievements', e);
    return [];
  }
});

// Provider for achievements by category
final achievementsByCategoryProvider = 
    FutureProvider.family.autoDispose<List<Achievement>, String>((ref, category) async {
  try {
    final response = await SupabaseService.achievements
        .select()
        .eq('category', category)
        .order('required_level', ascending: true);
    
    ErrorHandler.logInfo('Fetched achievements for category $category: $response');
    
    final List<Map<String, dynamic>> typedData =
        (response as List).map((item) => item as Map<String, dynamic>).toList();
    
    return typedData.map((json) => Achievement.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch achievements for category $category', e);
    return [];
  }
});

class AchievementService {
  // Check and unlock achievements based on different triggers
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final List<Achievement> newlyUnlocked = [];
    
    try {
      // Fetch user profile for level-based achievements
      final userData = await SupabaseService.profiles
          .select('level, experience')
          .eq('id', userId)
          .single();
      
      final int userLevel = userData['level'] ?? 1;
      
      // Fetch quest stats for quest-based achievements
      final questResponse = await SupabaseService.quests
          .select('id, status, difficulty')
          .eq('user_id', userId);
      
      final quests = questResponse as List;
      final completedQuests = quests.where((q) => q['status'] == 'completed').length;
      final completedEpicQuests = quests.where(
        (q) => q['status'] == 'completed' && q['difficulty'].toLowerCase() == 'epic'
      ).length;
      
      // Fetch already unlocked achievements
      final unlockedAchievements = await SupabaseService.userAchievements
          .select('achievement_id')
          .eq('user_id', userId);
      
      final unlockedIds = (unlockedAchievements as List)
          .map((item) => item['achievement_id'])
          .toList();
      
      // Fetch all available achievements
      final allAchievements = await SupabaseService.achievements
          .select();
      
      // Check each achievement and unlock if conditions are met
      for (final achievementData in allAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Skip if already unlocked
        if (unlockedIds.contains(achievement.id)) continue;
        
        bool shouldUnlock = false;
        
        // Parse criteria JSON if available
        Map<String, dynamic>? criteria;
        if (achievementData['criteria'] != null) {
          try {
            criteria = achievementData['criteria'] as Map<String, dynamic>;
          } catch (e) {
            ErrorHandler.logError('Failed to parse criteria for achievement ${achievement.id}', e);
          }
        }
        
        // Check achievement criteria
        if (criteria != null) {
          shouldUnlock = _checkCriteria(
            criteria, 
            userLevel: userLevel,
            completedQuests: completedQuests,
            completedEpicQuests: completedEpicQuests,
          );
        } else {
          // Fallback to basic ID-based checks for backwards compatibility
          if (achievement.id == 'first_quest' && completedQuests >= 1) {
            shouldUnlock = true;
          } else if (achievement.id == 'quest_master' && completedQuests >= 10) {
            shouldUnlock = true;
          } else if (achievement.id == 'epic_challenge' && completedEpicQuests >= 1) {
            shouldUnlock = true;
          } else if (achievement.id.startsWith('level_') && userLevel >= achievement.requiredLevel) {
            shouldUnlock = true;
          }
        }
        
        // Unlock the achievement if conditions are met
        if (shouldUnlock) {
          await unlockAchievement(achievement);
          newlyUnlocked.add(achievement);
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      ErrorHandler.logError('Failed to check achievements', e);
      return [];
    }
  }
  
  // Helper method to check achievement criteria
  bool _checkCriteria(
    Map<String, dynamic> criteria, {
    required int userLevel,
    required int completedQuests,
    required int completedEpicQuests,
  }) {
    try {
      // Check each criterion type
      if (criteria.containsKey('min_level') && userLevel < criteria['min_level']) {
        return false;
      }
      
      if (criteria.containsKey('min_completed_quests') && 
          completedQuests < criteria['min_completed_quests']) {
        return false;
      }
      
      if (criteria.containsKey('min_epic_quests') && 
          completedEpicQuests < criteria['min_epic_quests']) {
        return false;
      }
      
      // If we reach here, all criteria are met
      return true;
    } catch (e) {
      ErrorHandler.logError('Error checking achievement criteria', e);
      return false;
    }
  }
  
  // Unlock a specific achievement
  Future<void> unlockAchievement(Achievement achievement) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Create a user achievement record
      final userAchievement = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'achievement_id': achievement.id,
        'unlocked_at': DateTime.now().toIso8601String(),
      };
      
      await SupabaseService.userAchievements.insert(userAchievement);
      
      // Track analytics
      AnalyticsService.trackAchievementUnlocked(
        achievement.id,
        achievement.title,
      );
      
      ErrorHandler.logInfo('Achievement unlocked: ${achievement.title}');
    } catch (e) {
      ErrorHandler.logError('Failed to unlock achievement', e);
    }
  }
  
  // Check for level-based achievements
  Future<List<Achievement>> checkLevelAchievements(int newLevel) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final List<Achievement> unlockedAchievements = [];
    
    try {
      // Fetch already unlocked achievements
      final unlockedData = await SupabaseService.userAchievements
          .select('achievement_id')
          .eq('user_id', userId);
      
      final unlockedIds = (unlockedData as List)
          .map((item) => item['achievement_id'])
          .toList();
      
      // Fetch level-based achievements using the category field
      final levelAchievements = await SupabaseService.achievements
          .select()
          .eq('category', 'level')
          .lte('required_level', newLevel);
      
      // Check each achievement
      for (final achievementData in levelAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Skip if already unlocked
        if (unlockedIds.contains(achievement.id)) continue;
        
        // Unlock the achievement
        await unlockAchievement(achievement);
        unlockedAchievements.add(achievement);
      }
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check level achievements', e);
      return [];
    }
  }
  
  // Check for quest completion achievements
  Future<List<Achievement>> checkQuestCompletionAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final List<Achievement> unlockedAchievements = [];
    
    try {
      // Get count of completed quests
      final response = await SupabaseService.client
          .from('quests')
          .select('id, difficulty', const FetchOptions(
            count: CountOption.exact
          ))
          .eq('user_id', userId)
          .eq('status', 'completed');
      
      final int completedQuestCount = response.count ?? 0;
      final List quests = response.data as List;
      
      // Count quests by difficulty
      final completedEpicQuests = quests.where(
        (q) => q['difficulty'].toString().toLowerCase() == 'epic'
      ).length;
      
      // Fetch already unlocked achievements
      final unlockedData = await SupabaseService.userAchievements
          .select('achievement_id')
          .eq('user_id', userId);
      
      final unlockedIds = (unlockedData as List)
          .map((item) => item['achievement_id'])
          .toList();
      
      // Fetch quest-related achievements
      final questAchievements = await SupabaseService.achievements
          .select()
          .eq('category', 'quest');
      
      for (final achievementData in questAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Skip if already unlocked
        if (unlockedIds.contains(achievement.id)) continue;
        
        // Check criteria in advanced way
        bool shouldUnlock = false;
        
        if (achievementData['criteria'] != null) {
          final criteria = achievementData['criteria'] as Map<String, dynamic>;
          
          shouldUnlock = _checkCriteria(
            criteria,
            userLevel: 0,  // Not needed for quest achievements
            completedQuests: completedQuestCount,
            completedEpicQuests: completedEpicQuests,
          );
        } else {
          // Fallback for older achievements
          if (achievement.id == 'first_quest' && completedQuestCount >= 1) {
            shouldUnlock = true;
          } else if (achievement.id == 'quest_master' && completedQuestCount >= 10) {
            shouldUnlock = true;
          } else if (achievement.id == 'epic_challenge' && completedEpicQuests >= 1) {
            shouldUnlock = true;
          }
        }
        
        if (shouldUnlock) {
          await unlockAchievement(achievement);
          unlockedAchievements.add(achievement);
        }
      }
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check quest completion achievements', e);
      return [];
    }
  }
  
  // Show achievement alert dialog
  static void showAchievementDialog(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievement Unlocked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: getAchievementColor(achievement.badgeColor).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getAchievementIcon(achievement.id),
                color: getAchievementColor(achievement.badgeColor),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${achievement.points} points',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: getAchievementColor(achievement.badgeColor),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nice!'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get color based on badge_color string
  static Color getAchievementColor(String? badgeColor) {
    if (badgeColor == null) return Colors.amber;
    
    switch (badgeColor.toLowerCase()) {
      case 'gold': 
        return Colors.amber;
      case 'silver': 
        return Colors.blueGrey.shade300;
      case 'bronze': 
        return Colors.brown.shade300;
      case 'blue': 
        return Colors.blue;
      case 'green': 
        return Colors.green;
      case 'purple': 
        return Colors.purple;
      case 'red': 
        return Colors.red;
      default:
        // Try to parse hex color
        if (badgeColor.startsWith('#') && badgeColor.length == 7) {
          try {
            return Color(int.parse(badgeColor.substring(1), radix: 16) + 0xFF000000);
          } catch (e) {
            // Fallback to default
            return Colors.amber;
          }
        }
        return Colors.amber;
    }
  }
  
  // Helper method to get icon based on achievement ID or category
  static IconData getAchievementIcon(String achievementId) {
    // Map achievement IDs to specific icons
    switch (achievementId) {
      case 'first_quest':
        return Icons.check_circle_outline;
      case 'quest_master':
        return Icons.auto_awesome;
      case 'streak_warrior':
        return Icons.local_fire_department;
      case 'epic_challenge':
        return Icons.diamond;
      case 'balanced_life':
        return Icons.balance;
      case 'early_bird':
        return Icons.wb_sunny;
      case 'night_owl':
        return Icons.nightlight_round;
      default:
        if (achievementId.startsWith('level_')) {
          return Icons.star;
        }
        return Icons.emoji_events;
    }
  }
}