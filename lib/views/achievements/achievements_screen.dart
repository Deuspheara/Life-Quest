import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/services/quest_services.dart';
import 'package:life_quest/views/widgets/achievement_badge.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);
    final completedQuestsCountAsync = ref.watch(completedQuestsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userAchievementsProvider);
          ref.invalidate(achievementsProvider);
          await ref.read(userAchievementsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header with achievement progress summary
            SliverToBoxAdapter(
              child: _buildProgressHeader(
                context, 
                userAchievementsAsync, 
                achievementsAsync, 
                completedQuestsCountAsync,
              ),
            ),

            // Badge Showcase
            SliverToBoxAdapter(
              child: _buildBadgeShowcase(userAchievementsAsync),
            ),
            
            // Achievement Categories
            _buildAchievementCategories(userAchievementsAsync, achievementsAsync),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressHeader(
    BuildContext context,
    AsyncValue<List<UserAchievement>> userAchievementsAsync,
    AsyncValue<List<Achievement>> achievementsAsync,
    AsyncValue<int> completedQuestsCountAsync,
  ) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              userAchievementsAsync.when(
                data: (userAchievements) => achievementsAsync.when(
                  data: (achievements) => Text(
                    '${userAchievements.length}/${achievements.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  userAchievementsAsync.maybeWhen(
                    data: (userAchievements) => userAchievements.length.toString(),
                    orElse: () => '0',
                  ),
                  'Unlocked',
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  completedQuestsCountAsync.maybeWhen(
                    data: (count) => count.toString(),
                    orElse: () => '0',
                  ),
                  'Quests Completed',
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  userAchievementsAsync.maybeWhen(
                    data: (userAchievements) => 
                        userAchievements.where((a) => a.achievement.isSecret).length.toString(),
                    orElse: () => '0',
                  ),
                  'Secret Badges',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          userAchievementsAsync.when(
            data: (userAchievements) => achievementsAsync.when(
              data: (achievements) {
                final progress = achievements.isEmpty 
                    ? 0.0 
                    : userAchievements.length / achievements.length;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: Colors.white,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Colors.white70,
                minHeight: 10,
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const LinearProgressIndicator(
              backgroundColor: Colors.white24,
              color: Colors.white70,
              minHeight: 10,
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShowcase(AsyncValue<List<UserAchievement>> userAchievementsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Your Badges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          userAchievementsAsync.when(
            data: (userAchievements) {
              if (userAchievements.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'Complete quests to earn badges',
                      style: TextStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              
              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: userAchievements.length,
                  itemBuilder: (context, index) {
                    final userAchievement = userAchievements[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: AchievementBadge(
                        userAchievement: userAchievement,
                        size: 80,
                        showLabel: true,
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                      effects: [
                        // Apply a subtle shine effect only to new achievements
                        if (userAchievement.isNew)
                          ShimmerEffect(
                            duration: 3.seconds, 
                            delay: 1.seconds,
                            color: Colors.white.withOpacity(0.3),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Center(
              child: Text('Failed to load achievements'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategories(
    AsyncValue<List<UserAchievement>> userAchievementsAsync,
    AsyncValue<List<Achievement>> achievementsAsync,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: achievementsAsync.when(
          data: (allAchievements) {
            // Group achievements by category
            final Map<AchievementCategory, List<Achievement>> categorizedAchievements = {};
            
            for (final achievement in allAchievements) {
              final category = achievement.category;
              if (!categorizedAchievements.containsKey(category)) {
                categorizedAchievements[category] = [];
              }
              categorizedAchievements[category]!.add(achievement);
            }
            
            return userAchievementsAsync.when(
              data: (userAchievements) {
                // Create a set of unlocked achievement IDs for quick lookup
                final unlockedAchievementIds = 
                    userAchievements.map((ua) => ua.achievement.id).toSet();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categorizedAchievements.entries.map((entry) {
                    final category = entry.key;
                    final achievements = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: achievements.map((achievement) {
                              final isUnlocked = unlockedAchievementIds.contains(achievement.id);
                              return _AchievementCard(
                                achievement: achievement,
                                isUnlocked: isUnlocked,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Failed to load achievements'),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const Center(
            child: Text('Failed to load achievements'),
          ),
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
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnlocked
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement icon with a more polished appearance
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isUnlocked 
                    ? [
                        achievement.category.color.withOpacity(0.7), 
                        achievement.category.color,
                      ]
                    : [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isUnlocked ? [
                  BoxShadow(
                    color: achievement.category.color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: Center(
                child: Icon(
                  achievement.isSecret && !isUnlocked
                      ? Icons.lock
                      : achievement.category.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // Achievement details with proper constraints
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  if (!isUnlocked && !achievement.isSecret)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Required Level: ${achievement.requiredLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Progress indicator for locked achievements
            if (!isUnlocked && !achievement.isSecret)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}