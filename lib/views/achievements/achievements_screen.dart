import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/views/achievements/achievement_detail_screen.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsWithStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          // Split into unlocked and locked achievements
          final unlockedAchievements = achievements
              .where((a) => a.isUnlocked)
              .toList();
              
          final lockedAchievements = achievements
              .where((a) => !a.isUnlocked)
              .toList();
              
          // Calculate progress percentage
          final totalAchievements = achievements.length;
          final progressPercentage = totalAchievements > 0
              ? unlockedAchievements.length / totalAchievements
              : 0.0;

          return CustomScrollView(
            slivers: [
              // Header with progress summary
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.7),
                        AppColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProgressStat(
                            '${unlockedAchievements.length}/$totalAchievements',
                            'Achievements',
                          ),
                          _buildProgressStat(
                            '${(progressPercentage * 100).toInt()}%',
                            'Completed',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressPercentage,
                          backgroundColor: Colors.white30,
                          color: Colors.white,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Unlocked Achievements Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Unlocked Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${unlockedAchievements.length}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // If no unlocked achievements, show a message
              if (unlockedAchievements.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32.0,
                        horizontal: 16.0,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: AppColors.lightGrey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No achievements unlocked yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mediumText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete quests to earn achievements!',
                            style: TextStyle(
                              color: AppColors.mediumText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievementWithStatus = unlockedAchievements[index];
                      return _AchievementCard(
                        achievementWithStatus: achievementWithStatus,
                        onTap: () => _navigateToDetail(context, achievementWithStatus),
                      );
                    },
                    childCount: unlockedAchievements.length,
                  ),
                ),

              // Locked Achievements Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Locked Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lockedAchievements.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievementWithStatus = lockedAchievements[index];
                    return _AchievementCard(
                      achievementWithStatus: achievementWithStatus,
                      onTap: () => _navigateToDetail(context, achievementWithStatus),
                    );
                  },
                  childCount: lockedAchievements.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: AppColors.mediumText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userAchievementsWithStatusProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, AchievementWithStatus achievementWithStatus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementDetailScreen(
          achievement: achievementWithStatus.achievement,
          isUnlocked: achievementWithStatus.isUnlocked,
          unlockedAt: achievementWithStatus.unlockedAt,
          progress: achievementWithStatus.progress,
        ),
      ),
    );
  }

  Widget _buildProgressStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementWithStatus achievementWithStatus;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.achievementWithStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = achievementWithStatus.achievement;
    final isUnlocked = achievementWithStatus.isUnlocked;
    final progress = achievementWithStatus.progress;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnlocked
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement.color.withOpacity(0.2)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    achievement.isSecret && !isUnlocked
                        ? Icons.lock
                        : Icons.emoji_events,
                    color: isUnlocked
                        ? achievement.color
                        : Colors.grey,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.isSecret && !isUnlocked
                          ? 'Secret Achievement'
                          : achievement.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? AppColors.darkText
                            : AppColors.mediumText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.isSecret && !isUnlocked
                          ? 'Complete special challenges to unlock'
                          : achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked
                            ? AppColors.mediumText
                            : AppColors.lightText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Progress bar or reward for locked achievements
                    if (!isUnlocked && !achievement.isSecret && progress > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      achievement.color,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: achievement.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                    // Level requirement or unlock date
                    if (!isUnlocked && !achievement.isSecret)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 14,
                              color: AppColors.mediumText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Required Level: ${achievement.requiredLevel}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${achievement.experienceReward} XP',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Chevron icon
              const Icon(
                Icons.chevron_right,
                color: AppColors.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}