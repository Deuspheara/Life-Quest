import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/quests.dart';
import '../../services/quest_services.dart';

class QuestDetailsScreen extends ConsumerStatefulWidget {
  final Quest quest;

  const QuestDetailsScreen({
    Key? key,
    required this.quest,
  }) : super(key: key);

  @override
  ConsumerState<QuestDetailsScreen> createState() => _QuestDetailsScreenState();
}

class _QuestDetailsScreenState extends ConsumerState<QuestDetailsScreen> {
  final QuestService _questService = QuestService();
  bool _isLoading = false;
  late Quest _quest;
  int? _loadingStepIndex;
  int? _lastCompletedStepIndex;

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;

    // Track screen view in analytics
    AnalyticsService.trackScreenView('quest_details', properties: {
      'quest_id': _quest.id,
      'quest_title': _quest.title,
      'quest_difficulty': _quest.difficulty.name,
    });
  }

  Future<void> _completeStep(int stepIndex) async {
    setState(() {
      _isLoading = true;
      _loadingStepIndex = stepIndex;
    });

    try {
      await _questService.completeQuestStep(_quest.id, stepIndex);

      // Refresh quest data
      final updatedQuests = await _questService.getUserQuests();
      final updatedQuest = updatedQuests.firstWhere((q) => q.id == _quest.id);

      setState(() {
        _quest = updatedQuest;
        _lastCompletedStepIndex = stepIndex;
      });

      // Track step completion in analytics
      AnalyticsService.trackEvent('quest_step_completed', properties: {
        'quest_id': _quest.id,
        'step_index': stepIndex,
        'is_quest_completed': _quest.status == QuestStatus.completed,
      });

      // Wait for animation to finish before showing completion dialog
      if (_quest.status == QuestStatus.completed && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        _showCompletionDialog();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete step: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _loadingStepIndex = null;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Congratulations! You\'ve completed "${_quest.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_quest.experiencePoints} XP',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_quest.difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.medium:
        return Colors.blue;
      case QuestDifficulty.hard:
        return Colors.orange;
      case QuestDifficulty.epic:
        return Colors.purple;
    }
  }

  String _getDifficultyText() {
    switch (_quest.difficulty) {
      case QuestDifficulty.easy:
        return 'Easy';
      case QuestDifficulty.medium:
        return 'Medium';
      case QuestDifficulty.hard:
        return 'Hard';
      case QuestDifficulty.epic:
        return 'Epic';
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest title and difficulty
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _quest.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.diamond_outlined,
                        size: 16,
                        color: difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: difficultyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _quest.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
            ),
            const SizedBox(height: 16),

            // Quest status and due date
            if (_quest.status == QuestStatus.active)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(_quest.dueDate),
                            style: TextStyle(
                              color: _quest.isOverdue
                                  ? Colors.red
                                  : AppColors.mediumText,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Reward',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_quest.experiencePoints} XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_quest.status == QuestStatus.completed)
              Card(
                margin: const EdgeInsets.only(top: 8),
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quest Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            if (_quest.completedAt != null)
                              Text(
                                'Completed on ${_formatDate(_quest.completedAt!)}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${_quest.experiencePoints}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(_quest.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _quest.progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _quest.status == QuestStatus.completed
                      ? Colors.green
                      : AppColors.primary,
                ),
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 32),

            // Quest steps
            const Text(
              'Quest Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Steps list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quest.steps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final isCompleted = _quest.completedSteps.contains(index);
                final isLoading = _isLoading && _loadingStepIndex == index;
                final wasJustCompleted = _lastCompletedStepIndex == index;
                
                // Create the list item with animation if it was just completed
                Widget listItem = Card(
                  margin: EdgeInsets.zero,
                  color: isCompleted ? Colors.green.shade50 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCompleted
                        ? BorderSide(color: Colors.green.shade200)
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? Colors.green
                          : Colors.grey.shade200,
                      foregroundColor: isCompleted
                          ? Colors.white
                          : AppColors.mediumText,
                      child: isCompleted
                          ? const Icon(Icons.check)
                          : Text('${index + 1}'),
                    ),
                    title: Text(
                      _quest.steps[index],
                      style: TextStyle(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? AppColors.mediumText
                            : AppColors.darkText,
                        fontWeight: isCompleted
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    trailing: _quest.status == QuestStatus.active && !isCompleted
                        ? ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _completeStep(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? Colors.grey.shade400
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 10,
                              ),
                              minimumSize: const Size(100, 36),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Complete',
                                    style: TextStyle(fontSize: 14),
                                  ),
                          )
                        : null,
                  ),
                );
                
                // Add animations for newly completed items
                if (wasJustCompleted) {
                  return listItem
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(
                      begin: 0.05, 
                      end: 0, 
                      curve: Curves.easeOut,
                      duration: 400.ms,
                    )
                    .scale(
                      begin: const Offset(0.98, 0.98),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                    );
                }
                
                return listItem;
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays < 0) {
      return '${-difference.inDays} days ago';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays} days';
    } else {
      // Format as month/day/year
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}