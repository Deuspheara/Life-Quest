import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';

// Custom painter to draw light rays like in Duolingo
class LightRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.8;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    // Draw rays of light
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * (3.14159 / 180);
      final startPoint = Offset(
        center.dx + radius * 0.3 * cos(angle),
        center.dy + radius * 0.3 * sin(angle),
      );
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AchievementDetailScreen extends ConsumerStatefulWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;

  const AchievementDetailScreen({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0.0,
  }) : super(key: key);

  @override
  ConsumerState<AchievementDetailScreen> createState() => _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends ConsumerState<AchievementDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Use XP value directly
    final int xpValue = widget.achievement.experienceReward;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFEDB58), // Bright yellow
              Color(0xFFFFD700), // Gold
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // No status bar customization
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Light ray decoration
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: CustomPaint(
                        painter: LightRaysPainter(),
                      ),
                    ),
                    
                    // Large percentage display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$xpValue",
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "XP",
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Achievement icon in place of mascot
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: widget.achievement.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconData(widget.achievement.iconPath),
                        color: Colors.white,
                        size: 40,
                      ),
                    ).animate().scale(
                      delay: 200.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Main achievement text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "You're ${widget.isUnlocked ? 'rocking' : 'working on'} your ${widget.achievement.category} achievement!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513), // Brown text like Duolingo
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Details text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8B4513),
                          ),
                          children: [
                            const TextSpan(text: "You "),
                            TextSpan(
                              text: widget.isUnlocked ? "completed " : "need to complete ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: widget.achievement.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: widget.isUnlocked ? " and won " : " to win ",
                            ),
                            TextSpan(
                              text: "$xpValue XP",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: "!",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Share button
                    Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing achievement...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, color: Color(0xFF8B4513)),
                        label: const Text(
                          "SHARE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    
                    // Close button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "CLOSE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFBF00), // Amber
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bottom indicator line like in the image
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert icon string to IconData (keeping from original code)
  IconData _getIconData(String iconPath) {
    // Extract icon name from icon:name format
    if (iconPath.startsWith('icon:')) {
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

      return iconMap[iconName] ?? Icons.emoji_events;
    }

    return Icons.emoji_events;
  }
}