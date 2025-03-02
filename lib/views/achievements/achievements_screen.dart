import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a placeholder for real achievement data
    // In a real implementation, this would come from a provider
    final unlockedAchievements = [
      Achievement(
        id: '1',
        title: 'First Steps',
        description: 'Complete your first quest',
        iconPath: 'assets/images/achievements/first_quest.png',
        requiredLevel: 1,
      ),
      Achievement(
        id: '2',
        title: 'Level Up',
        description: 'Reach level 5 for the first time',
        iconPath: 'assets/images/achievements/level_5.png',
        requiredLevel: 5,
      ),
    ];

    final lockedAchievements = [
      Achievement(
        id: '3',
        title: 'Quest Master',
        description: 'Complete 10 quests',
        iconPath: 'assets/images/achievements/quest_master.png',
        requiredLevel: 10,
      ),
      Achievement(
        id: '4',
        title: 'Streak Warrior',
        description: 'Complete quests for 7 days in a row',
        iconPath: 'assets/images/achievements/streak.png',
        requiredLevel: 1,
      ),
      Achievement(
        id: '5',
        title: 'Epic Challenge',
        description: 'Complete an epic difficulty quest',
        iconPath: 'assets/images/achievements/epic_quest.png',
        requiredLevel: 15,
        isSecret: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: CustomScrollView(
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
                        '${unlockedAchievements.length}/${unlockedAchievements.length + lockedAchievements.length}',
                        'Achievements',
                      ),
                      _buildProgressStat(
                        '${(unlockedAchievements.length / (unlockedAchievements.length + lockedAchievements.length) * 100).toInt()}%',
                        'Completed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: unlockedAchievements.length / (unlockedAchievements.length + lockedAchievements.length),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Unlocked Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final achievement = unlockedAchievements[index];
                return _AchievementCard(
                  achievement: achievement,
                  isUnlocked: true,
                );
              },
              childCount: unlockedAchievements.length,
            ),
          ),

          // Locked Achievements Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
              child: Text(
                'Locked Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final achievement = lockedAchievements[index];
                return _AchievementCard(
                  achievement: achievement,
                  isUnlocked: false,
                );
              },
              childCount: lockedAchievements.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
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
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnlocked
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade300),
      ),
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
                    ? Colors.amber.shade100
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  achievement.isSecret && !isUnlocked
                      ? Icons.lock
                      : Icons.emoji_events,
                  color: isUnlocked
                      ? Colors.amber
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
                  ),
                  if (!isUnlocked && !achievement.isSecret)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Required Level: ${achievement.requiredLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}