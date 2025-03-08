import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/views/achievements/achievement_detail_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

// Added Spacing constants for consistent UI
class Spacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  bool _showRecentUnlock = false;
  AchievementWithStatus? _recentUnlocked;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // Check for recently unlocked achievements
    Future.delayed(Duration.zero, () {
      final achievementsAsync = ref.read(userAchievementsWithStatusProvider);
      achievementsAsync.whenData((achievements) {
        final recentUnlocked = achievements
            .where((a) => a.isUnlocked && a.unlockedAt != null)
            .toList()
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

        if (recentUnlocked.isNotEmpty) {
          // Consider any achievement unlocked in the last 24 hours as "recent"
          final mostRecent = recentUnlocked.first;
          final now = DateTime.now();
          if (mostRecent.unlockedAt != null &&
              now.difference(mostRecent.unlockedAt!).inHours < 24) {
            setState(() {
              _recentUnlocked = mostRecent;
              _showRecentUnlock = true;
            });

            // Play confetti effect
            _confettiController.play();

            // Auto-hide the popup after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showRecentUnlock = false;
                });
              }
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(userAchievementsWithStatusProvider);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                centerTitle: true, // Add this to ensure title is centered when collapsed
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true, // Add this to center the title
                  titlePadding: EdgeInsets.only(bottom: 14), // Remove left/right padding
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppColors.primary.withBlue(200),
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),

                    // Achievement stats
                    Positioned(
                      top: statusBarHeight + 50,
                      left: 16,
                      right: 16,
                      child: achievementsAsync.when(
                        data: (achievements) {
                          final unlockedCount = achievements.where((a) => a.isUnlocked).length;
                          final totalCount = achievements.length;
                          final progressPercent = totalCount > 0
                              ? (unlockedCount / totalCount * 100).toInt()
                              : 0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Progress bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$unlockedCount/$totalCount Unlocked',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '$progressPercent%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: totalCount > 0 ? unlockedCount / totalCount : 0,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Recent unlocks if any
                              if (unlockedCount > 0)
                                Text(
                                  'Keep it up! Earn more achievements by completing quests and reaching milestones.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                            ],
                          ).animate().fadeIn(delay: 200.ms);
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        error: (_, __) => Container(),
                      ),
                    ),

                    // Decorative elements (subtle trophy icons)
                    Positioned(
                      right: -20,
                      top: statusBarHeight + 5,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.emoji_events,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About Achievements'),
                        content: const Text(
                            'Achievements are special rewards you earn by completing quests and reaching milestones in Life Quest.\n\n'
                                'Unlocking achievements earns you bonus XP and special recognition. Some achievements are secret - discover them by exploring the app!'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12), // More pill-shaped
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey.shade600,
                padding: const EdgeInsets.all(6), // Tighter padding
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero, // Remove default padding
                indicatorSize: TabBarIndicatorSize.tab,
                onTap: (_) => HapticFeedback.lightImpact(),
                tabs: const [
                  Tab(
                    height: 48, // Fixed height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open, size: 16),
                        SizedBox(width: Spacing.xs),
                        Text(
                          'UNLOCKED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48, // Fixed height
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16),
                        SizedBox(width: Spacing.xs),
                        Text(
                          'LOCKED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              color: Colors.grey.shade100,
            ),
            pinned: true,
          ),
          ];
        },
        body: Stack(
          children: [
            // Tab content
            achievementsAsync.when(
              data: (achievements) {
                // Split into unlocked and locked achievements
                final unlockedAchievements = achievements
                    .where((a) => a.isUnlocked)
                    .toList();

                final lockedAchievements = achievements
                    .where((a) => !a.isUnlocked)
                    .toList();

                return Container(
                  color: Colors.grey.shade50,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Unlocked achievements tab
                      unlockedAchievements.isEmpty
                          ? _buildEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'No Achievements Yet',
                          message: 'Complete quests to earn your first achievement!'
                      ).animate().fadeIn(duration: 200.ms)
                          : _buildAchievementGrid(unlockedAchievements, true),

                      // Locked achievements tab
                      lockedAchievements.isEmpty
                          ? _buildEmptyState(
                          icon: Icons.verified_outlined,
                          title: 'All Achievements Unlocked!',
                          message: 'Incredible! You\'ve unlocked everything!'
                      ).animate().fadeIn(duration: 200.ms)
                          : _buildAchievementGrid(lockedAchievements, false),
                    ],
                  ),
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animations/trophy_loading.json',
                      width: 120,
                      height: 120,
                      frameRate: FrameRate(60),
                    ),
                    const SizedBox(height: Spacing.s),
                    const Text(
                      'Loading achievements...',
                      style: TextStyle(
                        color: AppColors.mediumText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                    const SizedBox(height: Spacing.m),
                    const Text(
                      'Failed to load achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.m),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(userAchievementsWithStatusProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

            // Confetti effect for recent achievements
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: const [
                  Color.fromARGB(255, 155, 255, 159),
                  Color.fromRGBO(159, 212, 255, 1),
                  Color.fromARGB(255, 255, 121, 121),
                  Color.fromARGB(255, 255, 211, 144),
                  Color.fromARGB(255, 239, 145, 255),
                  Color.fromARGB(255, 255, 228, 148),
                ],
              ),
            ),

            // Recent achievement popup
            if (_showRecentUnlock && _recentUnlocked != null)
              Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: Spacing.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showRecentUnlock = false;
                    });
                    _navigateToDetail(context, _recentUnlocked!);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.m, vertical: Spacing.m),
                    child: Row(
                      children: [
                        // Trophy container with animated gradient
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade200,
                                Colors.amber.shade100,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative circles
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Trophy icon
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 34,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: Spacing.m),
                        
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Congratulatory text
                              Row(
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'NEW ACHIEVEMENT!',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: Spacing.xs + 2),
                              
                              // Achievement title with improved typography
                              Text(
                                _recentUnlocked!.achievement.title,
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              // XP reward text
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+${_recentUnlocked!.achievement.experienceReward} XP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // View button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setState(() {
                                  _showRecentUnlock = false;
                                });
                                _navigateToDetail(context, _recentUnlocked!);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'VIEW',
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.amber.shade800,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate()
            .slideY(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementGrid(List<AchievementWithStatus> achievements, bool isUnlocked) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.m),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78, // Adjusted to accommodate more content
        crossAxisSpacing: Spacing.m,
        mainAxisSpacing: Spacing.m,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement, index);
      },
    );
  }
Widget _buildAchievementCard(AchievementWithStatus achievementWithStatus, int index) {
  final achievement = achievementWithStatus.achievement;
  final isUnlocked = achievementWithStatus.isUnlocked;
  final progress = achievementWithStatus.progress;
  final isSecret = achievement.isSecret && !isUnlocked;
  final color = isUnlocked ? achievement.color : Colors.grey.shade400;

  // Animation delay based on index
  final delay = (index % 10) * 30;
  
  return Hero(
    tag: 'achievement-${achievement.id}',
    child: Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context, achievementWithStatus),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top colored section (simplified)
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon with white background
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSecret
                          ? const Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 32,
                            )
                          : Icon(
                              _getIconData(achievement.iconPath),
                              color: isUnlocked ? color : Colors.grey.shade400,
                              size: 32,
                            ),
                      ),
                    ),
                    
                    // Simple star for unlocked (smaller, cleaner)
                    if (isUnlocked)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content area with clean spacing
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Title with cleaner typography
                  Text(
                    isSecret && !isUnlocked ? 'Secret Achievement' : achievement.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.grey.shade800 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Simplified XP display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: isUnlocked ? Colors.amber : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.xpReward} XP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.amber.shade700 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Simplified status display
                  if (!isUnlocked && !isSecret && progress > 0)
                    // Cleaner progress circle
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isUnlocked)
                    // Simple completed text
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                        letterSpacing: 0.5,
                      ),
                    )
                  else if (isSecret)
                    // Secret indicator
                    Text(
                      'HIDDEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: Duration(milliseconds: delay),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: 400.ms,
      delay: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
    ),
  );
}
  IconData _getIconData(String iconPath) {
    // Extract icon name from icon:name format
    final iconName = iconPath.replaceFirst('icon:', '');

    // Map of icon names to IconData
    final Map<String, IconData> iconMap = {
      'star': Icons.star,
      'trophy': Icons.emoji_events,
      'medal': Icons.military_tech,
      'flag': Icons.flag,
      'target': Icons.track_changes,
      'fire': Icons.local_fire_department,
      'heart': Icons.favorite,
      'book': Icons.menu_book,
      'run': Icons.directions_run,
      'calendar': Icons.calendar_today,
      'streak': Icons.bolt,
      'quest': Icons.explore,
      'level': Icons.trending_up,
      'crown': Icons.workspace_premium,
    };

    // Return the corresponding IconData or a default one
    return iconMap[iconName] ?? Icons.emoji_events;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: Spacing.l),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: Spacing.s),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to quests screen
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.l,
                  vertical: Spacing.s + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.explore, size: 18),
              label: const Text('COMPLETE QUESTS'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, AchievementWithStatus achievementWithStatus) {
    // Add haptic feedback for better tactile experience
    HapticFeedback.mediumImpact();

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
}

// SliverPersistentHeader delegate for the tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  _SliverTabBarDelegate(this.tabBar, {required this.color});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        boxShadow: overlapsContent
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || color != oldDelegate.color;
  }
}

// Extension to add colors to Achievement model
extension AchievementColors on Achievement {
  Color get color {
    // Map achievement types to colors
    if (this.iconPath.contains('star')) return Colors.amber;
    if (this.iconPath.contains('trophy')) return Colors.orange;
    if (this.iconPath.contains('medal')) return Colors.blue;
    if (this.iconPath.contains('fire')) return Colors.red;
    if (this.iconPath.contains('heart')) return Colors.pink;
    if (this.iconPath.contains('crown')) return Colors.purple;

    // Default color based on required level
    if (this.requiredLevel >= 20) return Colors.purple;
    if (this.requiredLevel >= 15) return Colors.indigo;
    if (this.requiredLevel >= 10) return Colors.blue;
    if (this.requiredLevel >= 5) return Colors.green;
    return AppColors.primary;
  }

  // Added XP reward based on required level (could be fetched from real data)
  int get xpReward {
    return this.requiredLevel * 20;
  }
}