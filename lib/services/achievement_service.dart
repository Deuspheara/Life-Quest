import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

// Provider for all achievements in the system
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  try {
    final response = await SupabaseService.achievements.select();
    
    // Convert to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> typedData =
        (response as List).map((item) => item as Map<String, dynamic>).toList();
    
    return typedData.map((json) => Achievement.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch achievements', e);
    return [];
  }
});

// Provider for the current user's unlocked achievements
final userAchievementsProvider = FutureProvider.autoDispose<List<UserAchievement>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    // First get all achievements
    final achievements = await ref.watch(achievementsProvider.future);
    
    // Then get the user's unlocked achievements
    final response = await SupabaseService.userAchievements
        .select()
        .eq('user_id', userId);

    // Convert to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> typedData =
        (response as List).map((item) => item as Map<String, dynamic>).toList();
    
    // Map each user achievement to its corresponding achievement
    return typedData.map((json) {
      final achievementId = json['achievement_id'] as String;
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => Achievement(
          id: achievementId,
          title: 'Unknown Achievement',
          description: 'This achievement is no longer available',
          iconPath: 'assets/images/achievements/unknown.png',
          requiredLevel: 1,
        ),
      );
      
      return UserAchievement.fromJson(json, achievement);
    }).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch user achievements', e);
    return [];
  }
});

class AchievementService {
  // Check if user has already unlocked an achievement
  Future<bool> hasUnlockedAchievement(String achievementId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await SupabaseService.userAchievements
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();
          
      return response != null;
    } catch (e) {
      ErrorHandler.logError('Failed to check achievement status', e);
      return false;
    }
  }

  // Unlock an achievement for the current user
  Future<UserAchievement?> unlockAchievement(Achievement achievement) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      log('Cannot unlock achievement: No authenticated user');
      return null;
    }

    // Check if already unlocked
    final alreadyUnlocked = await hasUnlockedAchievement(achievement.id);
    if (alreadyUnlocked) {
      log('Achievement ${achievement.title} already unlocked');
      return null;
    }

    try {
      log('Unlocking achievement: ${achievement.title} (${achievement.id})');
      
      // Create a new user achievement record
      final userAchievementId = const Uuid().v4();
      final now = DateTime.now();
      
      await SupabaseService.userAchievements.insert({
        'id': userAchievementId,
        'user_id': userId,
        'achievement_id': achievement.id,
        'unlocked_at': now.toIso8601String(),
      });
      
      log('Achievement record created with ID: $userAchievementId');
      
      // Add achievement points to the user's profile
      await _addAchievementPoints(achievement.points);

      // Return the newly created user achievement
      final userAchievement = UserAchievement(
        id: userAchievementId,
        userId: userId,
        achievementId: achievement.id,
        unlockedAt: now,
        achievement: achievement,
        isNew: true,
      );
      
      log('Achievement successfully unlocked: ${achievement.title}');
      return userAchievement;
    } catch (e) {
      ErrorHandler.logError('Failed to unlock achievement: ${achievement.title}', e);
      return null;
    }
  }

  // Add achievement points to the user's experience
  Future<void> _addAchievementPoints(int points) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get current profile
      final data = await SupabaseService.profiles
          .select('experience')
          .eq('id', userId)
          .single();

      int currentExp = data['experience'];
      int newExp = currentExp + points;

      // Update the profile with the new experience
      await SupabaseService.profiles
          .update({
            'experience': newExp,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      ErrorHandler.logError('Failed to add achievement points', e);
    }
  }

  // Check for level-based achievements
  Future<List<UserAchievement>> checkLevelAchievements(int level) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get all level-based achievements that require the current level or lower
      final response = await SupabaseService.achievements
          .select()
          .eq('category', AchievementCategory.level.name)
          .lte('required_level', level);
          
      // Convert to achievements
      final List<Map<String, dynamic>> typedData =
          (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      final achievements = typedData.map((json) => Achievement.fromJson(json)).toList();
      
      // Unlock each eligible achievement
      final unlockedAchievements = <UserAchievement>[];
      for (final achievement in achievements) {
        final userAchievement = await unlockAchievement(achievement);
        if (userAchievement != null) {
          unlockedAchievements.add(userAchievement);
        }
      }
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check level achievements', e);
      return [];
    }
  }

  // Check for quest-based achievements
  Future<List<UserAchievement>> checkQuestAchievements(int completedQuestsCount) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get all quest-based achievements
      final response = await SupabaseService.achievements
          .select()
          .eq('category', AchievementCategory.quest.name);
          
      // Convert to achievements
      final List<Map<String, dynamic>> typedData =
          (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      final achievements = typedData
          .map((json) => Achievement.fromJson(json))
          .where((a) {
            // Check if the achievement has criteria for completed quests
            final criteria = a.criteria;
            if (criteria == null) return false;
            
            final requiredQuests = criteria['completed_quests'] as int?;
            return requiredQuests != null && completedQuestsCount >= requiredQuests;
          })
          .toList();
      
      // Unlock each eligible achievement
      final unlockedAchievements = <UserAchievement>[];
      for (final achievement in achievements) {
        final userAchievement = await unlockAchievement(achievement);
        if (userAchievement != null) {
          unlockedAchievements.add(userAchievement);
        }
      }
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check quest achievements', e);
      return [];
    }
  }

  // Manually check all possible achievements for a user
  Future<List<UserAchievement>> checkAllAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final unlockedAchievements = <UserAchievement>[];
    
    try {
      // Get user's profile for level check
      final profileData = await SupabaseService.profiles
          .select('level')
          .eq('id', userId)
          .single();
      
      final userLevel = profileData['level'] as int;
      
      // Check level-based achievements
      final levelAchievements = await checkLevelAchievements(userLevel);
      unlockedAchievements.addAll(levelAchievements);
      
      // Count completed quests for quest achievement check
      final questsResponse = await SupabaseService.quests
          .select('count')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .execute();
          
      final completedQuestsCount = questsResponse.count ?? 0;
      
      // Check quest-based achievements
      final questAchievements = await checkQuestAchievements(completedQuestsCount);
      unlockedAchievements.addAll(questAchievements);
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check all achievements', e);
      return [];
    }
  }
  
  // Debug function to unlock all achievements for testing
  Future<List<UserAchievement>> unlockTestAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get all achievements
      final response = await SupabaseService.achievements.select();
      
      final List<Map<String, dynamic>> typedData =
          (response as List).map((item) => item as Map<String, dynamic>).toList();
      
      final achievements = typedData.map((json) => Achievement.fromJson(json)).toList();
      
      // Unlock each achievement
      final unlockedAchievements = <UserAchievement>[];
      for (final achievement in achievements) {
        final userAchievement = await unlockAchievement(achievement);
        if (userAchievement != null) {
          unlockedAchievements.add(userAchievement);
        }
      }
      
      return unlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to unlock test achievements', e);
      return [];
    }
  }

  // Debug function to force-check all achievements and return newly unlocked ones
  Future<List<UserAchievement>> forceCheckAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final result = <UserAchievement>[];
    
    try {
      log('Force-checking all achievements');
      
      // Get all achievements
      final achievementsResponse = await SupabaseService.achievements.select();
      final List<Map<String, dynamic>> achievementsData =
          (achievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
      
      final allAchievements = achievementsData.map((json) => Achievement.fromJson(json)).toList();
      
      log('Found ${allAchievements.length} total achievements to check');
      
      // Get user's profile data
      final profileData = await SupabaseService.profiles
          .select()
          .eq('id', userId)
          .single();
      
      final userLevel = profileData['level'] as int;
      log('User level: $userLevel');
      
      // Get completed quests count
      final questsResponse = await SupabaseService.quests
          .select('count')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .execute();
          
      final completedQuestsCount = questsResponse.count ?? 0;
      log('Completed quests count: $completedQuestsCount');
      
      // Get already unlocked achievements
      final userAchievementsResponse = await SupabaseService.userAchievements
          .select('achievement_id')
          .eq('user_id', userId);
          
      final unlockedAchievementIds = (userAchievementsResponse as List)
          .map((item) => (item as Map<String, dynamic>)['achievement_id'] as String)
          .toSet();
          
      log('Already unlocked achievements: ${unlockedAchievementIds.length}');
      
      // Check each achievement if it should be unlocked
      for (final achievement in allAchievements) {
        // Skip if already unlocked
        if (unlockedAchievementIds.contains(achievement.id)) {
          continue;
        }
        
        bool shouldUnlock = false;
        
        // Check if it's a level achievement
        if (achievement.category == AchievementCategory.level && 
            userLevel >= achievement.requiredLevel) {
          shouldUnlock = true;
          log('Level achievement eligible: ${achievement.title}');
        }
        
        // Check if it's a quest achievement with criteria
        if (achievement.category == AchievementCategory.quest && 
            achievement.criteria != null) {
          final requiredQuests = achievement.criteria!['completed_quests'] as int?;
          if (requiredQuests != null && completedQuestsCount >= requiredQuests) {
            shouldUnlock = true;
            log('Quest achievement eligible: ${achievement.title} (completed: $completedQuestsCount, required: $requiredQuests)');
          }
        }
        
        // Unlock if eligible
        if (shouldUnlock) {
          final userAchievement = await unlockAchievement(achievement);
          if (userAchievement != null) {
            result.add(userAchievement);
          }
        }
      }
      
      log('Newly unlocked achievements: ${result.length}');
      return result;
    } catch (e) {
      ErrorHandler.logError('Force-checking achievements failed', e);
      return [];
    }
  }
}
