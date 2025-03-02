import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/views/achievements/achievements_screen.dart';
import 'package:life_quest/views/quests/quests_screen.dart';
import 'package:life_quest/views/settings/settings_screen.dart';
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
  List<String> _interestAreas = ['productivity', 'health', 'learning'];
  bool _isGeneratingQuest = false;

  Future<void> _generateQuest() async {
    setState(() {
      _isGeneratingQuest = true;
    });

    try {
      await _questService.generateQuest(_interestAreas);
      ref.invalidate(questsProvider); // Refresh quests list
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

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final questsAsync = ref.watch(questsProvider);

    return Scaffold(
      body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(questsProvider);
            await ref.read(questsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar
              // App Bar - Improved FlexibleSpace implementation
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                titleSpacing: 16.0,
                // Clear title from app bar
                title: null,

                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.3,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  // Move title to be part of the FlexibleSpaceBar for better control
                  title: const Text(
                    'Life Quest',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      // Ensure visibility against background
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2.0,
                          color: Color.fromARGB(80, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Improved gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withBlue(200),
                            ],
                          ),
                        ),
                      ),
                      // User profile content - better positioned to avoid overlap
                      Positioned(
                        bottom: 56, // Move up to avoid overlap with title
                        left: 0,
                        right: 0,
                        child: userProfileAsync.when(
                          data: (userProfile) {
                            if (userProfile == null) {
                              return const SizedBox.shrink();
                            }
                            return Animate(
                              effects: [
                                FadeEffect(duration: 300.ms),
                                MoveEffect(
                                  begin: const Offset(0, 20),
                                  end: Offset.zero,
                                  duration: 300.ms,
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    // Profile avatar
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white30,
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
                                          const SizedBox(height: 4),
                                          // Level indicator with improved contrast
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius: BorderRadius.circular(12),
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
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Experience progress bar
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
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          error: (_, __) => const Center(
                            child: Text(
                              'Failed to load profile',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      // Add a subtle gradient overlay at the bottom for better title readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
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
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // Navigate to notifications screen
                    },
                  ),
                ],
              ),

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

                      // Placeholder for achievements
                      const Card(
                        child: SizedBox(
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
