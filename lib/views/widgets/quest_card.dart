import 'package:flutter/material.dart';
import 'package:life_quest/constants/app_colors.dart';

import '../../models/quests.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;

  const QuestCard({
    Key? key,
    required this.quest,
    this.onTap,
  }) : super(key: key);

  Color _getDifficultyColor() {
    switch (quest.difficulty) {
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
    switch (quest.difficulty) {
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and difficulty badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          size: 14,
                          color: difficultyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDifficultyText(),
                          style: TextStyle(
                            fontSize: 12,
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
                quest.description,
                style: const TextStyle(
                  color: AppColors.mediumText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Progress bar and stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(quest.progress * 100).toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 12,
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
                            '+${quest.experiencePoints} XP',
                            style: const TextStyle(
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: quest.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        quest.isOverdue
                            ? Colors.red
                            : AppColors.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),

                  // Due date
                  if (quest.status == QuestStatus.active)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Due: ${_formatDate(quest.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: quest.isOverdue
                              ? Colors.red
                              : AppColors.mediumText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
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
      // Format as month/day
      return '${date.month}/${date.day}';
    }
  }
}