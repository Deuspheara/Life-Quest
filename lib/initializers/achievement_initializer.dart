import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

/// This class is responsible for initializing achievement data in the database.
/// It's designed to be run once during app initialization or during database setup.
class AchievementInitializer {
  
  /// Checks if achievements need to be initialized and populates the database if needed
  Future<void> initializeAchievements() async {
    try {
      // First, check if the database schema is up to date
      await _ensureSchemaIsUpToDate();
      
      // Check if achievements already exist
      final response = await SupabaseService.achievements.select().limit(1);
      
      // Only initialize if no achievements exist
      if (response == null || (response as List).isEmpty) {
        await _createInitialAchievements();
      } else {
        // Check if we need to ensure all categories are represented
        await _ensureAllCategoriesExist();
      }
    } catch (e) {
      ErrorHandler.logError('Failed to initialize achievements', e);
    }
  }
  
  /// Ensures that the achievements table has all required columns
  Future<void> _ensureSchemaIsUpToDate() async {
    try {
      // Run the schema check function
      await SupabaseService.client.rpc('check_achievements_schema');
      ErrorHandler.logInfo('Schema check completed successfully');
    } catch (e) {
      // If the function doesn't exist or fails, log but continue
      ErrorHandler.logError('Schema check failed - using simplified model', e);
    }
  }
  
  // Ensure all achievement categories have at least one achievement
  Future<void> _ensureAllCategoriesExist() async {
    try {
      // Check existing categories
      final response = await SupabaseService.achievements
          .select('category')
          .order('category');
      
      // Extract unique categories
      final List<String> existingCategories = [];
      for (var item in response) {
        final category = item['category'] as String?;
        if (category != null && !existingCategories.contains(category)) {
          existingCategories.add(category);
        }
      }
      
      // Check which categories we need to add
      final allCategories = ['quest', 'level', 'streak', 'special'];
      final missingCategories = allCategories
          .where((c) => !existingCategories.contains(c))
          .toList();
      
      // Add missing categories
      for (var category in missingCategories) {
        await _addDefaultAchievementForCategory(category);
      }
    } catch (e) {
      ErrorHandler.logError('Failed to ensure all categories exist', e);
    }
  }
  
  // Add a default achievement for a category
  Future<void> _addDefaultAchievementForCategory(String category) async {
    try {
      // Create a simplified achievement that works with the minimum required columns
      final id = const Uuid().v4();
      final String title;
      final String description;
      final int requiredLevel;
      final bool isSecret;
      
      switch (category) {
        case 'quest':
          title = 'First Quest';
          description = 'Complete your first quest';
          requiredLevel = 1;
          isSecret = false;
          break;
        case 'level':
          title = 'Level Up';
          description = 'Reach level 2';
          requiredLevel = 2;
          isSecret = false;
          break;
        case 'streak':
          title = 'Getting Started';
          description = 'Complete quests for 3 days in a row';
          requiredLevel = 1;
          isSecret = false;
          break;
        case 'special':
          title = 'Hidden Gem';
          description = 'Discover a secret feature';
          requiredLevel = 1;
          isSecret = true;
          break;
        default:
          title = 'Achievement';
          description = 'Generic achievement';
          requiredLevel = 1;
          isSecret = false;
      }
      
      // Basic achievement data that should work with any schema
      final Map<String, dynamic> achievementData = {
        'id': id,
        'title': title,
        'description': description,
        'icon_path': 'assets/images/achievements/${category}_default.png',
        'required_level': requiredLevel,
        'is_secret': isSecret,
      };
      
      // Try to add extended fields - these will only be added if the columns exist
      try {
        achievementData['category'] = category;
      } catch (_) {}
      
      await SupabaseService.achievements.insert(achievementData);
      ErrorHandler.logInfo('Added default achievement for category: $category');
    } catch (e) {
      ErrorHandler.logError('Failed to add default achievement for category: $category', e);
    }
  }
  
  /// Creates the initial set of achievements in the database
  Future<void> _createInitialAchievements() async {
    try {
      // Create simple achievement data that should work with any schema version
      final questAchievement = {
        'id': const Uuid().v4(),
        'title': 'First Steps',
        'description': 'Complete your first quest',
        'icon_path': 'assets/images/achievements/first_quest.png',
        'required_level': 1,
        'is_secret': false,
        'category': 'quest',
        'points': 10,
        'criteria': {'completed_quests': 1},
      };
      
      final levelAchievement = {
        'id': const Uuid().v4(),
        'title': 'Level 5',
        'description': 'Reach level 5',
        'icon_path': 'assets/images/achievements/level_5.png',
        'required_level': 5,
        'is_secret': false,
        'category': 'level',
        'points': 25,
      };
      
      final streakAchievement = {
        'id': const Uuid().v4(),
        'title': 'Week Streak',
        'description': 'Complete quests for 7 days in a row',
        'icon_path': 'assets/images/achievements/streak_7.png',
        'required_level': 1,
        'is_secret': false,
        'category': 'streak',
        'points': 30,
        'criteria': {'streak_days': 7},
      };
      
      final secretAchievement = {
        'id': const Uuid().v4(),
        'title': 'Epic Challenge',
        'description': 'Complete an epic difficulty quest',
        'icon_path': 'assets/images/achievements/epic_quest.png',
        'required_level': 1,
        'is_secret': true,
        'category': 'special',
        'points': 50,
        'criteria': {'completed_epic_quest': true},
      };
      
      // Insert achievements - handle errors individually
      try {
        await SupabaseService.achievements.insert(questAchievement);
        ErrorHandler.logInfo('Added quest achievement');
      } catch (e) {
        ErrorHandler.logError('Failed to add quest achievement', e);
      }
      
      try {
        await SupabaseService.achievements.insert(levelAchievement);
        ErrorHandler.logInfo('Added level achievement');
      } catch (e) {
        ErrorHandler.logError('Failed to add level achievement', e);
      }
      
      try {
        await SupabaseService.achievements.insert(streakAchievement);
        ErrorHandler.logInfo('Added streak achievement');
      } catch (e) {
        ErrorHandler.logError('Failed to add streak achievement', e);
      }
      
      try {
        await SupabaseService.achievements.insert(secretAchievement);
        ErrorHandler.logInfo('Added secret achievement');
      } catch (e) {
        ErrorHandler.logError('Failed to add secret achievement', e);
      }
      
      ErrorHandler.logInfo('Achievement initialization complete');
    } catch (e) {
      ErrorHandler.logError('Failed to create initial achievements', e);
      rethrow;
    }
  }
}
