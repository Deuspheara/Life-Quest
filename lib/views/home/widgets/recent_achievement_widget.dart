import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/views/achievements/achievement_detail_screen.dart';
import 'package:life_quest/views/achievements/achievements_screen.dart';

class RecentAchievementsWidget extends ConsumerWidget {
  const RecentAchievementsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsWithStatusProvider);
    
    return achievementsAsync.when(
      data: (achievements) {
        // Get only unlocked achievements, sorted by most recent
        final unlockedAchievements = achievements
            .where((a) => a.isUnlocked)
            .toList();
            
        if (unlockedAchievements.isEmpty) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Complete quests to earn achievements!',
                  style: TextStyle(
                    color: AppColors.mediumText,
                  ),
                ),
              ),
            ),
          );
        }
        
        // Show the most recent 3 achievements
        return Column(
          children: [
            ...unlockedAchievements.take(3).map((achievement) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AchievementDetailScreen(
                        achievement: achievement.achievement,
                        isUnlocked: true,
                        unlockedAt: achievement.unlockedAt,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Achievement icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: achievement.achievement.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: achievement.achievement.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Achievement details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.achievement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              achievement.achievement.description,
                              style: const TextStyle(
                                color: AppColors.mediumText,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // XP reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${achievement.achievement.experienceReward}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            
            // "See All" button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All Achievements'),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const _LoadingAchievements(),
      error: (_, __) => const _ErrorAchievements(),
    );
  }
}

// Loading state widget
class _LoadingAchievements extends StatelessWidget {
  const _LoadingAchievements();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// Error state widget
class _ErrorAchievements extends StatelessWidget {
  const _ErrorAchievements();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Failed to load achievements',
            style: TextStyle(color: AppColors.mediumText),
          ),
        ),
      ),
    );
  }
}