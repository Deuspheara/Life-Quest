import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';

class AchievementManager {
  final AchievementService _achievementService = AchievementService();
  
  // Check all types of achievements in one call
  Future<List<Achievement>> checkAllAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    List<Achievement> newlyUnlockedAchievements = [];
    
    try {
      // Get user profile for level
      final data = await SupabaseService.profiles
          .select('level')
          .eq('id', userId)
          .single();
      
      final int userLevel = data['level'];
      
      // Check level-based achievements
      final levelAchievements = 
          await _achievementService.checkLevelAchievements(userId, userLevel);
      
      // Check quest-based achievements
      final questAchievements = 
          await _achievementService.checkQuestAchievements(userId);
      
      // Combine all newly unlocked achievements
      newlyUnlockedAchievements.addAll(levelAchievements);
      newlyUnlockedAchievements.addAll(questAchievements);
      
      return newlyUnlockedAchievements;
    } catch (e) {
      ErrorHandler.logError('Failed to check all achievements', e);
      return [];
    }
  }
  
  // This would be called when the app starts
  Future<void> checkStartupAchievements() async {
    try {
      await checkAllAchievements();
    } catch (e) {
      ErrorHandler.logError('Failed to check startup achievements', e);
    }
  }
  
  // Check for streak-based achievements
  Future<List<Achievement>> checkStreakAchievements(int streakDays) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get streak achievements
      final achievementsResponse = await SupabaseService.achievements
          .select()
          .eq('category', 'streak');
      
      final List<Map<String, dynamic>> streakAchievements =
          (achievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
      
      List<Achievement> newlyUnlocked = [];
      
      // Check each achievement
      for (final achievementData in streakAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Parse criteria to get required streak
        final criteria = achievement.criteria;
        if (criteria.contains('streak_days:')) {
          final requiredStreak = int.parse(
              criteria.split('streak_days:')[1].trim().split(' ')[0]);
              
          // Calculate progress
          final progress = streakDays / requiredStreak;
          
          // Update progress
          await _achievementService.updateAchievementProgress(
            userId, 
            achievement.id, 
            progress.clamp(0.0, 1.0),
          );
          
          // Award if streak is achieved
          if (streakDays >= requiredStreak) {
            final awarded = await _achievementService.awardAchievement(
              userId, 
              achievement.id,
            );
            
            if (awarded != null) {
              newlyUnlocked.add(awarded);
            }
          }
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      ErrorHandler.logError('Failed to check streak achievements', e);
      return [];
    }
  }
  
  // Check achievements related to profile completeness
  Future<List<Achievement>> checkProfileAchievements() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get user profile data
      final data = await SupabaseService.profiles
          .select()
          .eq('id', userId)
          .single();
      
      final hasAvatar = data['avatar_url'] != null;
      final hasUsername = data['username'] != null && data['username'].toString().isNotEmpty;
      final hasDisplayName = data['display_name'] != null && data['display_name'].toString().isNotEmpty;
      
      // Count profile completeness (simple version)
      int completedItems = 0;
      if (hasAvatar) completedItems++;
      if (hasUsername) completedItems++;
      if (hasDisplayName) completedItems++;
      
      // Calculate progress (0-1.0)
      final progress = completedItems / 3;
      
      // Get profile achievements
      final achievementsResponse = await SupabaseService.achievements
          .select()
          .eq('category', 'profile');
      
      final List<Map<String, dynamic>> profileAchievements =
          (achievementsResponse as List).map((item) => item as Map<String, dynamic>).toList();
      
      List<Achievement> newlyUnlocked = [];
      
      // Check each achievement
      for (final achievementData in profileAchievements) {
        final achievement = Achievement.fromJson(achievementData);
        
        // Update progress
        await _achievementService.updateAchievementProgress(
          userId, 
          achievement.id, 
          progress,
        );
        
        // Award if profile is complete
        if (progress >= 1.0) {
          final awarded = await _achievementService.awardAchievement(
            userId, 
            achievement.id,
          );
          
          if (awarded != null) {
            newlyUnlocked.add(awarded);
          }
        }
      }
      
      return newlyUnlocked;
    } catch (e) {
      ErrorHandler.logError('Failed to check profile achievements', e);
      return [];
    }
  }
}