import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';

class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Main card content
        Container(
          margin: const EdgeInsets.only(top: 40),
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
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(
                begin: 0.5,
                end: 0,
                curve: Curves.easeOutQuad,
              ),
              const SizedBox(height: 16),
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mediumText,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 24),
              
              // Confetti animation placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.celebration,
                    color: Colors.amber,
                    size: 24,
                  ),
                ],
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).fadeIn(
                delay: 800.ms,
              ).moveY(
                begin: 0,
                end: -10,
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ).then().moveY(
                begin: -10,
                end: 0,
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms).scale(
                delay: 900.ms,
                duration: 300.ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
            ],
          ),
        ),
        
        // Trophy/achievement icon overlay
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 48,
          ),
        ).animate().scale(
          duration: 500.ms,
          curve: Curves.elasticOut,
        ),
      ],
    );
  }
}

// Updated method to show the achievement dialog
void showAchievementUnlockedDialog(BuildContext context, Achievement achievement) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AchievementUnlockedDialog(achievement: achievement);
    },
  );
  
  // Play a sound effect (optional, would require adding audio package)
  // AudioService.playSound('achievement_unlocked.mp3');
}