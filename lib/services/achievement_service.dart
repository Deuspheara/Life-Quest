import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/models/quests.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

// Provider for all achievements
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  try {
    final response = await SupabaseService.achievements
        .select()
        .order('required_level', ascending: true);

    // Convert response to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> data =
        (response as List).map((item) => item as Map<String, dynamic>).toList();

    return data.map((json) => Achievement.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch achievements', e);
    return [];
  }
});

// Provider for user's achievements with status
final userAchievementsWithStatusProvider = FutureProvider<List<AchievementWithStatus>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    // Get all achievements
    final allAchievements = await ref.watch(achievementsProvider.future);
    
    // Get user's unlocked achievements
    final userAchievementsResponse = await SupabaseService.userAchievements
        .select('achievement_id, unlocked_at, progress')
        .eq('user_id', userId);
    
    final List<Map<String, dynamic>> userAchievementsData =
        (userAchievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
    
    // Create a map of achievement_id -> UserAchievement data
    final Map<String, Map<String, dynamic>> unlockedMap = {};
    for (var item in userAchievementsData) {
      unlockedMap[item['achievement_id']] = item;
    }
    
    // Combine all achievements with unlocked status
    return allAchievements.map((achievement) {
      final isUnlocked = unlockedMap.containsKey(achievement.id);
      final unlockedData = unlockedMap[achievement.id];
      
      return AchievementWithStatus(
        achievement: achievement,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.parse(unlockedData!['unlocked_at']) : null,
        progress: isUnlocked 
            ? (unlockedData!['progress'] ?? 1.0).toDouble() 
            : 0.0,
      );
    }).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch user achievements', e);
    return [];
  }
});

// Provider for just the user's unlocked achievements
final userAchievementsProvider = FutureProvider<List<UserAchievement>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    // Get user's unlocked achievements
    final userAchievementsResponse = await SupabaseService.userAchievements
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);
    
    final List<Map<String, dynamic>> userAchievementsData =
        (userAchievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
    
    // Convert to UserAchievement objects
    return userAchievementsData.map((json) => UserAchievement.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch user achievements', e);
    return [];
  }
});

class AchievementService {
  // Check if a user has a specific achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    try {
      final response = await SupabaseService.userAchievements
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .limit(1)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      ErrorHandler.logError('Failed to check achievement', e);
      return false;
    }
  }

  // Update achievement progress
  Future<void> updateAchievementProgress(
    String userId, 
    String achievementId, 
    double progress
  ) async {
    try {
      // Check if user already has this achievement
      final existingAchievement = await SupabaseService.userAchievements
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();
      
      if (existingAchievement != null) {
        // Update progress if it's higher than current
        final currentProgress = (existingAchievement['progress'] ?? 0.0).toDouble();
        if (progress > currentProgress) {
          await SupabaseService.userAchievements
              .update({'progress': progress})
              .eq('user_id', userId)
              .eq('achievement_id', achievementId);
        }
      } else if (progress > 0) {
        // Create new progress entry if progress is greater than 0
        await SupabaseService.userAchievements.insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'achievement_id': achievementId,
          'progress': progress,
          // Only set unlocked_at if fully completed
          if (progress >= 1.0) 'unlocked_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      ErrorHandler.logError('Failed to update achievement progress', e);
    }
  }

  // Award an achievement to a user (instantly complete)
  Future<Achievement?> awardAchievement(String userId, String achievementId) async {
    try {
      // Check if already awarded
      final hasAlready = await hasAchievement(userId, achievementId);
      if (hasAlready) return null;
      
      // Get achievement details
      final achievementResponse = await SupabaseService.achievements
          .select()
          .eq('id', achievementId)
          .single();
      
      final achievement = Achievement.fromJson(achievementResponse);
      
      // Award achievement
      await SupabaseService.userAchievements.insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
        'progress': 1.0,
      });
      
      // Return the awarded achievement
      return achievement;
    } catch (e) {
      ErrorHandler.logError('Failed to award achievement', e);
      return null;
    }
  }

// Add this helper method to the AchievementService class
String _getCriteriaString(dynamic criteria) {
  if (criteria == null) return '';
  if (criteria is String) return criteria;
  if (criteria is Map && criteria.containsKey('requirement')) {
    return criteria['requirement'] as String? ?? '';
  }
  return '';
}

// Then update the achievement checking code
Future<List<Achievement>> checkQuestAchievements(String userId) async {
  final List<Achievement> newlyUnlocked = [];
  
  try {
    // Get completed quests count
    final questsResponse = await SupabaseService.quests
        .select('id, difficulty')
        .eq('user_id', userId)
        .eq('status', QuestStatus.completed.name);
    
    final List<Map<String, dynamic>> completedQuests =
        (questsResponse as List).map((item) => item as Map<String, dynamic>).toList();
    
    // Count by difficulty
    final int totalCompleted = completedQuests.length;
    final int easyCompleted = completedQuests.where((q) => 
        q['difficulty'] == QuestDifficulty.easy.name).length;
    final int mediumCompleted = completedQuests.where((q) => 
        q['difficulty'] == QuestDifficulty.medium.name).length;
    final int hardCompleted = completedQuests.where((q) => 
        q['difficulty'] == QuestDifficulty.hard.name).length;
    final int epicCompleted = completedQuests.where((q) => 
        q['difficulty'] == QuestDifficulty.epic.name).length;
    
    // Get all achievements
    final achievementsResponse = await SupabaseService.achievements
        .select()
        .eq('category', 'quest');
    
    final List<Map<String, dynamic>> questAchievements =
        (achievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
    
    // Check each achievement
    for (final achievementData in questAchievements) {
      final achievement = Achievement.fromJson(achievementData);
      final criteriaString = _getCriteriaString(achievement.criteria);
      
      // Skip if already awarded
      final hasAlready = await hasAchievement(userId, achievement.id);
      if (hasAlready) continue;
      
      bool shouldAward = false;
      double progress = 0.0;
      
      // Evaluate criteria using the string
      if (criteriaString.contains('total_quests:')) {
        final requiredCount = int.parse(
            criteriaString.split('total_quests:')[1].trim().split(' ')[0]);
        progress = totalCompleted / requiredCount;
        shouldAward = totalCompleted >= requiredCount;
      } 
      else if (criteriaString.contains('easy_quests:')) {
        final requiredCount = int.parse(
            criteriaString.split('easy_quests:')[1].trim().split(' ')[0]);
        progress = easyCompleted / requiredCount;
        shouldAward = easyCompleted >= requiredCount;
      }
      else if (criteriaString.contains('medium_quests:')) {
        final requiredCount = int.parse(
            criteriaString.split('medium_quests:')[1].trim().split(' ')[0]);
        progress = mediumCompleted / requiredCount;
        shouldAward = mediumCompleted >= requiredCount;
      }
      else if (criteriaString.contains('hard_quests:')) {
        final requiredCount = int.parse(
            criteriaString.split('hard_quests:')[1].trim().split(' ')[0]);
        progress = hardCompleted / requiredCount;
        shouldAward = hardCompleted >= requiredCount;
      }
      else if (criteriaString.contains('epic_quests:')) {
        final requiredCount = int.parse(
            criteriaString.split('epic_quests:')[1].trim().split(' ')[0]);
        progress = epicCompleted / requiredCount;
        shouldAward = epicCompleted >= requiredCount;
      }
      
      // Update progress
      await updateAchievementProgress(userId, achievement.id, progress);
      
      // Award if criteria met
      if (shouldAward) {
        await awardAchievement(userId, achievement.id);
        newlyUnlocked.add(achievement);
      }
    }
    
    return newlyUnlocked;
  } catch (e) {
    ErrorHandler.logError('Failed to check quest achievements', e);
    return [];
  }
}
  // Check user's level-based achievements
  Future<List<Achievement>> checkLevelAchievements(String userId, int userLevel) async {
    final List<Achievement> newlyUnlocked = [];
    
    try {
      // Get level achievements
      final achievementsResponse = await SupabaseService.achievements
          .select()
          .eq('category', 'level');
      
      final List<Map<String, dynamic>> levelAchievements =
          (achievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
      
      // Check each achievement
      for (final achievementData in levelAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Check if level requirement is met
      // In checkLevelAchievements method:
        if (userLevel >= achievement.requiredLevel) {
          ErrorHandler.logInfo('User level $userLevel meets requirement ${achievement.requiredLevel}');
          final awarded = await awardAchievement(userId, achievement.id);
          if (awarded != null) {
            ErrorHandler.logInfo('Awarded achievement: ${awarded.title}');
            newlyUnlocked.add(awarded);
          }
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      ErrorHandler.logError('Failed to check level achievements', e);
      return [];
    }
  }
}