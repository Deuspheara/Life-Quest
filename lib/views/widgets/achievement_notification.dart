import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/views/achievements/achievement_details_screen.dart';

class AchievementNotification extends StatelessWidget {
  final UserAchievement userAchievement;
  final VoidCallback? onDismiss;

  const AchievementNotification({
    Key? key,
    required this.userAchievement,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievement = userAchievement.achievement;
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // Dismiss the notification
          if (onDismiss != null) {
            onDismiss!();
          }
          
          // Navigate to achievement details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AchievementDetailsScreen(
                userAchievement: userAchievement,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: achievement.category.color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      achievement.category.color.withOpacity(0.7),
                      achievement.category.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    achievement.category.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 2.seconds,
                  color: Colors.white.withOpacity(0.5),
                )
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                ),
                
              const SizedBox(width: 16),
              
              // Achievement text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Achievement Unlocked!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 300.ms,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: achievement.category.color,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 300.ms,
                      delay: 200.ms,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 400.ms)
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 300.ms,
                      delay: 400.ms,
                    ),
                  ],
                ),
              ),
              
              // Close button
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.black45,
                ),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Static method to show the notification as an overlay
  static void show(BuildContext context, UserAchievement userAchievement) {
      final overlay = Overlay.of(context);

      // Initialize overlayEntry with a default value
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: AchievementNotification(
            userAchievement: userAchievement,
            onDismiss: () {
              // Remove the overlay entry after a slight delay for animation
              Future.delayed(const Duration(milliseconds: 200), () {
                overlayEntry?.remove();
              });
            },
          ).animate().slideY(
            begin: -1,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutBack,
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (overlayEntry?.mounted ?? false) {
          overlayEntry?.remove();
        }
      });
  }


}
