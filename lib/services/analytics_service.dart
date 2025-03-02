import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:life_quest/utils/error_handler.dart';

class AnalyticsService {
  // Common analytics events
  static Future<void> trackQuestCreation(String questId, String questTitle, String questDifficulty) async {
    await trackEvent('quest_created', properties: {
      'quest_id': questId,
      'quest_title': questTitle,
      'difficulty': questDifficulty,
    });
  }

  static Future<void> trackQuestCompleted(String questId, String questTitle, int experienceGained) async {
    await trackEvent('quest_completed', properties: {
      'quest_id': questId,
      'quest_title': questTitle,
      'experience_gained': experienceGained,
    });
  }

  static Future<void> trackLevelUp(int newLevel, int totalExperience) async {
    await trackEvent('level_up', properties: {
      'new_level': newLevel,
      'total_experience': totalExperience,
    });
  }

  static Future<void> trackAchievementUnlocked(String achievementId, String achievementTitle) async {
    await trackEvent('achievement_unlocked', properties: {
      'achievement_id': achievementId,
      'achievement_title': achievementTitle,
    });
  }

  // Core analytics methods
  static Future<void> identifyUser(String userId, {Map<String, Object>? traits}) async {
    try {
      await Posthog().identify(
        userId: userId,
        userProperties: traits,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to identify user in analytics', e);
    }
  }

  static Future<void> trackEvent(String eventName, {Map<String, Object>? properties}) async {
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to track event in analytics', e);
    }
  }

  static Future<void> trackScreenView(String screenName, {Map<String, Object>? properties}) async {
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to track screen view in analytics', e);
    }
  }

  static Future<void> resetUser() async {
    try {
      await Posthog().reset();
    } catch (e) {
      ErrorHandler.logError('Failed to reset user in analytics', e);
    }
  }

  static Future<void> optOut(bool optOut) async {
    try {
      if (optOut) {
        await Posthog().disable();
      } else {
        await Posthog().enable();
      }
    } catch (e) {
      ErrorHandler.logError('Failed to set opt out in analytics', e);
    }
  }
}