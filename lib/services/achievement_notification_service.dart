import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/views/achievements/achievement_detail_screen.dart';

class AchievementNotificationService {
  // Show a popup notification for an unlocked achievement
  static void showAchievementUnlocked(
    BuildContext context, 
    Achievement achievement,
  ) {
    // Overlay entry to show the notification
    OverlayEntry? entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                // Close the notification
                entry?.remove();
                
                // Navigate to achievement details
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AchievementDetailScreen(
                      achievement: achievement,
                      isUnlocked: true,
                    ),
                  ),
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Achievement Unlocked!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '+${achievement.experienceReward} XP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => entry?.remove(),
                    ),
                  ],
                ),
              ).animate()
                .slideY(
                  begin: 1.0, 
                  end: 0.0, 
                  duration: 500.ms,
                  curve: Curves.easeOutQuint,
                )
                .fadeIn(duration: 400.ms),
            ),
          ),
        ),
      ),
    );
    
    // Show the notification
    Overlay.of(context).insert(entry);
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry?.mounted ?? false) {
        entry?.remove();
      }
    });
  }
  
  // Show multiple achievements unlocked
  static void showMultipleAchievementsUnlocked(
    BuildContext context, 
    List<Achievement> achievements,
  ) {
    if (achievements.isEmpty) return;
    
    // If only one achievement, use the single notification
    if (achievements.length == 1) {
      showAchievementUnlocked(context, achievements.first);
      return;
    }
    
    // Show a notification for multiple achievements
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
            ),
            const SizedBox(width: 8),
            const Text('Achievements Unlocked!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text(achievement.title),
                subtitle: Text('+${achievement.experienceReward} XP'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AchievementDetailScreen(
                        achievement: achievement,
                        isUnlocked: true,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to achievements screen
              // TODO: Add navigation to achievements screen
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }
}