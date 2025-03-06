import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/constants/app_strings.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/achievement_service.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  // The current selected category tab
  String _selectedCategory = 'all';
  
  // Animation controller for manual animations
  late AnimationController _animationController;
  
  // Available categories
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.dashboard},
    {'id': 'quest', 'name': 'Quests', 'icon': Icons.check_circle},
    {'id': 'level', 'name': 'Levels', 'icon': Icons.trending_up},
    {'id': 'special', 'name': 'Special', 'icon': Icons.auto_awesome},
  ];

  @override
  void initState() {
    super.initState();
    // Init animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    
    // Track screen view in analytics
    AnalyticsService.trackScreenView('achievements_screen');
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get achievements data from providers
    final achievementsAsync = ref.watch(achievementsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.achievements),
        backgroundColor: AppColors.primary,
      ),
      body: userAchievementsAsync.when(
        data: (userAchievements) {
          return achievementsAsync.when(
            data: (allAchievements) {
              // Extract achievement IDs that the user has unlocked
              final unlockedIds = userAchievements
                  .map((ua) => ua.achievementId)
                  .toSet();

              // Filter achievements by the selected category (if not 'all')
              final filteredAchievements = _selectedCategory == 'all'
                  ? allAchievements
                  : allAchievements.where((a) => a.category == _selectedCategory).toList();
                  
              // Filter achievements into unlocked and locked
              final unlockedAchievements = filteredAchievements
                  .where((a) => unlockedIds.contains(a.id))
                  .toList();
              
              final lockedAchievements = filteredAchievements
                  .where((a) => !unlockedIds.contains(a.id))
                  .toList();

              // Calculate total points earned from unlocked achievements
              int totalPoints = 0;
              for (final achievement in unlockedAchievements) {
                totalPoints += achievement.points;
              }

              return Column(
                children: [
                  // Category tabs
                  _buildCategoryTabs(),
                  
                  // Main content
                  Expanded(
                    child: _buildAchievementsContent(
                      unlockedAchievements,
                      lockedAchievements,
                      totalPoints,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsContent(
    List<Achievement> unlockedAchievements,
    List<Achievement> lockedAchievements,
    int totalPoints,
  ) {
    return CustomScrollView(
      slivers: [
        // Header with progress summary
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut)
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        '$totalPoints',
                        'Points',
                      ),
                      _buildProgressStat(
                        '${(unlockedAchievements.isEmpty && lockedAchievements.isEmpty) ? 0 : 
                            (unlockedAchievements.length / (unlockedAchievements.length + lockedAchievements.length) * 100).toInt()}%',
                        'Completed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: unlockedAchievements.isEmpty && lockedAchievements.isEmpty
                          ? 0.0
                          : unlockedAchievements.length /
                              (unlockedAchievements.length + lockedAchievements.length),
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Unlocked Achievements Section
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOut)
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Unlocked Achievements (${unlockedAchievements.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        unlockedAchievements.isEmpty
            ? SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeOut)
                    ),
                  ),
                  child: _buildEmptyState(
                    'You haven\'t unlocked any achievements yet',
                    'Complete quests and keep leveling up to earn achievements!',
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievement = unlockedAchievements[index];
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.3 + (index * 0.05).clamp(0.0, 0.7), 
                            0.8 + (index * 0.05).clamp(0.0, 0.2), 
                            curve: Curves.easeOut
                          ),
                        ),
                      ),
                      child: _AchievementCard(
                        achievement: achievement,
                        isUnlocked: true,
                      ),
                    );
                  },
                  childCount: unlockedAchievements.length,
                ),
              ),

        // Locked Achievements Section
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOut)
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
              child: Text(
                'Locked Achievements (${lockedAchievements.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        lockedAchievements.isEmpty
            ? SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut)
                    ),
                  ),
                  child: _buildEmptyState(
                    'No more achievements to unlock in this category',
                    'You\'ve unlocked all available achievements! Check other categories.',
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievement = lockedAchievements[index];
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.5 + (index * 0.03).clamp(0.0, 0.5), 
                            0.9 + (index * 0.01).clamp(0.0, 0.1), 
                            curve: Curves.easeOut
                          ),
                        ),
                      ),
                      child: _AchievementCard(
                        achievement: achievement,
                        isUnlocked: false,
                      ),
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

  Widget _buildEmptyState(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppColors.mediumText,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.mediumText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
          ElevatedButton(
            onPressed: () {
              ref.invalidate(achievementsProvider);
              ref.invalidate(userAchievementsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
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
    final Color badgeColor = AchievementService.getAchievementColor(achievement.badgeColor);
    final IconData iconData = AchievementService.getAchievementIcon(achievement.id);

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
                    ? badgeColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? badgeColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  achievement.isSecret && !isUnlocked
                      ? Icons.lock
                      : iconData,
                  color: isUnlocked
                      ? badgeColor
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
                      child: Row(
                        children: [
                          Text(
                            'Required Level: ${achievement.requiredLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: badgeColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${achievement.points} points',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Reward/badge indicator for unlocked achievements
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${achievement.points}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
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