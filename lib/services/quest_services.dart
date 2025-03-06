import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/achievement.dart';
import '../models/quests.dart';
import 'achievement_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

final questsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.quests
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    ErrorHandler.logInfo('Fetched quests: $response');
    // Ensure the response is a List and convert to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> typedData =
    (response as List).map((item) => item as Map<String, dynamic>).toList();

    // Invalidate user profile after fetching quests
    ref.invalidate(currentUserProfileProvider);

    return typedData.map((json) => Quest.fromJson(json)).toList();
  } catch (e) {
    ErrorHandler.logError('Failed to fetch quests', e);
    return [];
  }
});


class QuestService {
  // Fetch quests for current user
  Future<List<Quest>> getUserQuests() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      ErrorHandler.logInfo('Fetching quests for user: $userId');
      final response = await SupabaseService.quests
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      ErrorHandler.logInfo('Fetched quests: $response');

      // Ensure response is a List and each item is a Map
// Ensure the response is a List and convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> typedData =
      (response as List).map((item) => item as Map<String, dynamic>).toList();
      return typedData.map((json) => Quest.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to fetch quests', e);
      return [];
    }
  }
  // Generate a new quest using Supabase Edge Functions (AI-based)
  Future<Quest> generateQuest(List<String> interestAreas) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user found');

    try {
      // Call the Supabase Edge Function for AI quest generation
      final response = await SupabaseService.client.functions.invoke(
        'quests-generator',
        body: {
          'user_id': userId,
          'interest_areas': interestAreas,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to generate quest: ${response.data}');
      }

      // Create the quest in the database
      final questData = response.data as Map<String, dynamic>;
      log('Generated quest: $questData');
      final quest = Quest(
        id: const Uuid().v4(),
        userId: userId,
        title: questData['title'],
        description: questData['description'],
        difficulty: QuestDifficultyExtension.fromString(questData['difficulty']),
        experiencePoints: questData['experience_points'],
        status: QuestStatus.active,
        steps: List<String>.from(questData['steps']),
        completedSteps: [],
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );

      // Save to database
      await createQuest(quest);

      return quest;
    } catch (e) {
      ErrorHandler.logError('Quest generation failed', e);
      rethrow;
    }
  }

  // Create a new quest
  Future<void> createQuest(Quest quest) async {
    try {
      await SupabaseService.quests.insert(quest.toJson());
    } catch (e) {
      ErrorHandler.logError('Quest creation failed', e);
      rethrow;
    }
  }

  // Update a quest
  Future<void> updateQuest(Quest quest) async {
    try {
      await SupabaseService.quests
          .update(quest.toJson())
          .eq('id', quest.id);
    } catch (e) {
      ErrorHandler.logError('Quest update failed', e);
      rethrow;
    }
  }

  Future<void> completeQuestStep(String questId, int stepIndex, {BuildContext? context}) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) throw Exception('No authenticated user found');

  try {
    // Fetch the current quest with explicit single row handling
    final response = await SupabaseService.quests
        .select()
        .eq('id', questId)
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('Quest not found');
    }

    ErrorHandler.logInfo('Fetched quest: $response');

    final quest = Quest.fromJson(response);

    // Update the completed steps
    if (!quest.completedSteps.contains(stepIndex)) {
      final updatedCompletedSteps = [...quest.completedSteps, stepIndex];

      await SupabaseService.quests
          .update({'completed_steps': updatedCompletedSteps})
          .eq('id', questId)
          .eq('user_id', userId);

      // Check if all steps are completed
      if (updatedCompletedSteps.length == quest.steps.length) {
        await SupabaseService.quests
            .update({
          'status': QuestStatus.completed.name,
          'completed_at': DateTime.now().toIso8601String()
        })
            .eq('id', questId)
            .eq('user_id', userId);

        // Update user experience points
        await _addExperiencePoints(quest.experiencePoints, context: context);
        
        // Check for quest-related achievements
        if (context != null) {
          final achievementService = AchievementService();
          final unlockedAchievements = 
              await achievementService.checkQuestCompletionAchievements();
          
          // Show dialog for each unlocked achievement
          if (unlockedAchievements.isNotEmpty) {
            for (final achievement in unlockedAchievements) {
              // Add a short delay between each dialog
              await Future.delayed(const Duration(milliseconds: 500));
              if (context.mounted) {
                AchievementService.showAchievementDialog(context, achievement);
              }
            }
          }
        }
        
        // Track analytics for quest completion
        AnalyticsService.trackQuestCompleted(
          quest.id, 
          quest.title, 
          quest.experiencePoints
        );
      }
    }
  } catch (e) {
    ErrorHandler.logError('Quest step completion failed', e);
    rethrow;
  }
}

 
// Then modify the _addExperiencePoints method in your QuestService class
// to check for achievements when a user levels up or completes a quest

Future<void> _addExperiencePoints(int points, {BuildContext? context}) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    // Get current profile
    final data = await SupabaseService.profiles
        .select('level, experience')
        .eq('id', userId)
        .single();

    int currentLevel = data['level'];
    int currentExp = data['experience'];
    int newExp = currentExp + points;

    // Simple leveling formula: level up every 100 * current_level XP
    int expNeededForNextLevel = 100 * currentLevel;
    int newLevel = currentLevel;

    while (newExp >= expNeededForNextLevel) {
      newExp -= expNeededForNextLevel;
      newLevel++;
      expNeededForNextLevel = 100 * newLevel;
    }

    // Update the profile
    await SupabaseService.profiles
        .update({
      'level': newLevel,
      'experience': newExp,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', userId);

    // If leveled up, check for new achievements
    if (newLevel > currentLevel) {
      final achievementService = AchievementService();
      final List<Achievement> unlockedAchievements = 
          await achievementService.checkLevelAchievements(newLevel);
      
      // Show dialog for each unlocked achievement if context is provided
      if (context != null && unlockedAchievements.isNotEmpty) {
        for (final achievement in unlockedAchievements) {
          // Add a short delay between each dialog
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            AchievementService.showAchievementDialog(context, achievement);
          }
        }
      }
      
      // Track analytics
      AnalyticsService.trackLevelUp(newLevel, currentExp + points);
    }
  } catch (e) {
    ErrorHandler.logError('Failed to add experience points', e);
  }
}

}