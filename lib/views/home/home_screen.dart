import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/services/achievement_service.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/views/achievements/achievement_details_screen.dart';
import 'package:life_quest/views/achievements/achievements_screen.dart';
import 'package:life_quest/views/quests/quests_screen.dart';
import 'package:life_quest/views/settings/profile_edit_screen.dart';
import 'package:life_quest/views/settings/settings_screen.dart';
import 'package:life_quest/views/widgets/achievement_badge.dart';
import 'package:life_quest/views/widgets/achievement_notification.dart';
import 'package:life_quest/views/widgets/level_progress.dart';
import 'package:life_quest/views/widgets/quest_card.dart';

import '../../models/quests.dart';
import '../../services/quest_services.dart';
import '../quests/quest_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final QuestService _questService = QuestService();
  final AchievementService _achievementService = AchievementService();
  List<String> _interestAreas = ['productivity', 'health', 'learning'];
  bool _isGeneratingQuest = false;
  bool _isCheckingAchievements = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _generateQuest() async {
    setState(() {
      _isGeneratingQuest = true;
    });

    try {
      await _questService.generateQuest(_interestAreas);
      ref.invalidate(questsProvider); // Refresh quests list
      ref.invalidate(currentUserProfileProvider); // Refresh user profile

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New quest generated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate quest: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingQuest = false;
      });
    }
  }

  Future<void> _checkAchievements() async {
    setState(() {
      _isCheckingAchievements = true;
    });

    try {
      // Use the more robust force check method
      final achievements = await _achievementService.forceCheckAchievements();
      
      // Refresh the achievements in the UI
      ref.invalidate(userAchievementsProvider);
      
      if (achievements.isNotEmpty) {
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked ${achievements.length} achievement${achievements.length == 1 ? '' : 's'}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Show achievement notification for the first unlocked achievement
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && achievements.isNotEmpty) {
            AchievementNotification.show(context, achievements.first);
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new achievements to unlock'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking achievements: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isCheckingAchievements = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Check for new achievements when the home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAchievements();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final questsAsync = ref.watch(questsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Fixed top bar and user profile section
          _buildFixedTopBar(userProfileAsync),

          // Main scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(questsProvider);
                ref.invalidate(userAchievementsProvider);
                await ref.read(questsProvider.future);
                await ref.read(userAchievementsProvider.future);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Main content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active quests section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Active Quests',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const QuestsScreen(),
                                    ),
                                  );
                                },
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Quests list
                          questsAsync.when(
                            data: (quests) {
                              // Filter for active quests only
                              final activeQuests = quests
                                  .where((q) => q.status == QuestStatus.active)
                                  .toList();

                              if (activeQuests.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.explore_outlined,
                                          size: 48,
                                          color: AppColors.mediumText,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No active quests',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mediumText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Generate a new quest to start your journey!',
                                          style: TextStyle(
                                            color: AppColors.mediumText,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _isGeneratingQuest
                                              ? null
                                              : _generateQuest,
                                          icon: _isGeneratingQuest
                                              ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                              : const Icon(Icons.add),
                                          label: const Text('Generate Quest'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 300.ms);
                              }

                              // Show active quests
                              return Column(
                                children: [
                                  ...activeQuests.take(3).map((quest) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: QuestCard(
                                      quest: quest,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => QuestDetailsScreen(
                                              quest: quest,
                                            ),
                                          ),
                                        ).then((_) {
                                          // Refresh quests when coming back from details
                                          ref.invalidate(questsProvider);
                                        });
                                      },
                                    ),
                                  )),

                                  // Generate quest button
                                  if (activeQuests.length < 5)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: ElevatedButton.icon(
                                        onPressed: _isGeneratingQuest
                                            ? null
                                            : _generateQuest,
                                        icon: _isGeneratingQuest
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Icon(Icons.add),
                                        label: const Text('Generate New Quest'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(double.infinity, 48),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load quests',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.invalidate(questsProvider);
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Achievements section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Achievements',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Achievements display
                          _buildAchievementsSection(userAchievementsAsync),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    AsyncValue<List<dynamic>> userAchievementsAsync,
  ) {
    return userAchievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No achievements yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete quests to earn achievements!',
                    style: TextStyle(
                      color: AppColors.mediumText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCheckingAchievements ? null : _checkAchievements,
                    child: _isCheckingAchievements
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Check Achievements'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Achievement badges in a horizontal scrollable list
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AchievementDetailsScreen(
                            userAchievement: achievement,
                          ),
                        ),
                      ),
                      child: AchievementBadge(
                        userAchievement: achievement,
                        size: 80,
                        showLabel: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Button to check for more achievements
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: _isCheckingAchievements ? null : _checkAchievements,
                icon: _isCheckingAchievements
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Check for new achievements'),
              ),
            ),
          ],
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Error loading achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userAchievementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedTopBar(AsyncValue<dynamic> userProfileAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar with actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Life Quest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2.0,
                            color: Color.fromARGB(80, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      // Navigate to notifications screen
                    },
                  ),
                ],
              ),
            ),

            // User profile section
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: userProfileAsync.when(
                data: (userProfile) {
                  if (userProfile == null) {
                    return const SizedBox.shrink();
                  }
                  return Animate(
                    effects: [
                      FadeEffect(duration: 300.ms),
                      MoveEffect(
                        begin: const Offset(0, 10),
                        end: Offset.zero,
                        duration: 300.ms,
                      ),
                    ],
                    child: Card(
                      elevation: 0,
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Profile avatar with improved design - Now clickable!
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileEditScreen(),
                                  ),
                                ).then((_) {
                                  // Refresh profile when returning
                                  ref.invalidate(currentUserProfileProvider);
                                });
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white30, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: userProfile.avatarUrl != null
                                        ? CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(userProfile.avatarUrl!),
                                          )
                                        : CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            child: Text(
                                              userProfile.displayName.isNotEmpty
                                                  ? userProfile.displayName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                  
                                  // Edit indicator
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            // User info with clearer visual hierarchy
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProfile.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3.0,
                                          color: Color.fromARGB(90, 0, 0, 0),
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Level indicator with improved contrast
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.amber.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Level ${userProfile.level}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${userProfile.experience} / ${userProfile.experienceForNextLevel} XP',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Experience progress bar with improved visuals
                                  LevelProgress(
                                    progress: userProfile.levelProgress,
                                    currentExp: userProfile.experience,
                                    targetExp: userProfile.experienceForNextLevel,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                error: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Failed to load profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}