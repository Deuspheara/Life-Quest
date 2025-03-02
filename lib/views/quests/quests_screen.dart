import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/views/quests/quest_details_screen.dart';
import 'package:life_quest/views/widgets/quest_card.dart';

import '../../models/quests.dart';
import '../../services/quest_services.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuestService _questService = QuestService();
  bool _isGeneratingQuest = false;
  List<String> _interestAreas = ['productivity', 'health', 'learning'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateQuest() async {
    setState(() {
      _isGeneratingQuest = true;
    });

    try {
      await _questService.generateQuest(_interestAreas);
      ref.invalidate(questsProvider); // Refresh quests list
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
    final questsAsync = ref.watch(questsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active quests tab
          questsAsync.when(
            data: (quests) {
              final activeQuests = quests
                  .where((q) => q.status == QuestStatus.active)
                  .toList();

              if (activeQuests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.explore_outlined,
                        size: 64,
                        color: AppColors.lightGrey,
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
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingQuest ? null : _generateQuest,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Generate quest button
                    if (activeQuests.length < 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingQuest ? null : _generateQuest,
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

                    // Quests list
                    Expanded(
                      child: ListView.builder(
                        itemCount: activeQuests.length,
                        itemBuilder: (context, index) {
                          final quest = activeQuests[index];
                          return Padding(
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => Center(
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

          // Completed quests tab
          questsAsync.when(
            data: (quests) {
              final completedQuests = quests
                  .where((q) => q.status == QuestStatus.completed)
                  .toList();

              if (completedQuests.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: AppColors.lightGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No completed quests yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mediumText,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete your active quests to see them here',
                        style: TextStyle(
                          color: AppColors.mediumText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: completedQuests.length,
                  itemBuilder: (context, index) {
                    final quest = completedQuests[index];
                    return Padding(
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
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => Center(
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
        ],
      ),
    );
  }
}