import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/views/achievements/achievements_screen.dart';

class RecentAchievementsWidget extends ConsumerWidget {
  const RecentAchievementsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAchievementsAsync = ref.watch(userAchievementsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return userAchievementsAsync.when(
      data: (userAchievements) {
        return achievementsAsync.when(
          data: (allAchievements) {
            // Get unlocked achievement IDs
            final unlockedIds = userAchievements
                .map((ua) => ua.achievementId)
                .toSet();

            // Map for quick achievement lookup by ID
            final Map<String, Achievement> achievementMap = {
              for (var a in allAchievements) a.id: a
            };
            
            // Sort user achievements by unlock date (most recent first)
            final sortedUserAchievements = List.of(userAchievements)
              ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
            
            // Get recent achievements, ensuring they exist in the achievements map
            final recentAchievements = sortedUserAchievements
                .where((ua) => achievementMap.containsKey(ua.achievementId))
                .take(3) // Only take the 3 most recent ones
                .map((ua) => achievementMap[ua.achievementId]!)
                .toList();

            return _buildRecentAchievements(context, recentAchievements, unlockedIds.length, achievementMap);
          },
          loading: () => const _LoadingAchievements(),
          error: (_, __) => const _ErrorAchievements(),
        );
      },
      loading: () => const _LoadingAchievements(),
      error: (_, __) => const _ErrorAchievements(),
    );
  }

  Widget _buildRecentAchievements(
    BuildContext context, 
    List<Achievement> recentAchievements,
    int totalUnlocked,
    Map<String, Achievement> achievementMap,
  ) {
    if (recentAchievements.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppColors.lightGrey,
                ),
                SizedBox(height: 12),
                Text(
                  'No achievements yet',
                  style: TextStyle(
                    color: AppColors.mediumText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete quests to earn achievements!',
                  style: TextStyle(
                    color: AppColors.mediumText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate total points
    int totalPoints = 0;
    for (final achievement in recentAchievements) {
      totalPoints += achievement.points;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Achievements',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalUnlocked total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Achievement list
            ...recentAchievements.map((achievement) => _buildAchievementItem(achievement)),
                //.animate(interval: 100.ms)
                //.fadeIn(duration: 300.ms)
                //.slideX(
                //  begin: 0.1,
                //  end: 0,
                //  curve: Curves.easeOutQuad,
                //),
            
            const Divider(height: 24),
            
            // See all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPoints points earned recently',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('See All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    final Color badgeColor = AchievementService.getAchievementColor(achievement.badgeColor);
    final IconData iconData = AchievementService.getAchievementIcon(achievement.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: badgeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Achievement text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withOpacity(0.4)),
            ),
            child: Text(
              '+${achievement.points}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
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