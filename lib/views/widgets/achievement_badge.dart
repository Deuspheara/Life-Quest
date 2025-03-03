import 'package:flutter/material.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/achievement.dart';

class AchievementBadge extends StatelessWidget {
  final UserAchievement userAchievement;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const AchievementBadge({
    Key? key,
    required this.userAchievement,
    this.size = 60,
    this.showLabel = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievement = userAchievement.achievement;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getBadgeColor().withOpacity(0.7),
                  _getBadgeColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getBadgeColor().withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _getIconData(),
                color: Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Container(
                width: size * 1.5, // Wider than the badge
                constraints: BoxConstraints(maxWidth: size * 1.5),
                child: Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size * 0.16, // Responsive font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    final achievement = userAchievement.achievement;
    
    // Use specific badge color if provided
    if (achievement.badgeColor != null) {
      try {
        return Color(int.parse(achievement.badgeColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return achievement.category.color;
      }
    }
    
    // Otherwise use category color
    return achievement.category.color;
  }

  IconData _getIconData() {
    final achievement = userAchievement.achievement;
    
    // This would ideally use custom icons or images based on iconPath
    // For now, we'll just use a category-specific icon
    return achievement.category.icon;
  }
}
