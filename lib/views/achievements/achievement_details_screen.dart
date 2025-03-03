import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:life_quest/models/achievement.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:life_quest/views/widgets/achievement_badge.dart';
import 'package:life_quest/views/widgets/confetti_painter.dart';
import 'package:life_quest/views/widgets/enhanced_detail_card.dart';
import 'package:life_quest/views/widgets/pattern_painter.dart';
import 'package:life_quest/views/widgets/stat_card.dart';
import 'package:share_plus/share_plus.dart';

class AchievementDetailsScreen extends StatefulWidget {
  final UserAchievement userAchievement;
  
  const AchievementDetailsScreen({
    Key? key,
    required this.userAchievement,
  }) : super(key: key);
  
  @override
  State<AchievementDetailsScreen> createState() => _AchievementDetailsScreenState();
}

class _AchievementDetailsScreenState extends State<AchievementDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Run confetti if achievement was unlocked recently
    final unlockedRecently = DateTime.now().difference(widget.userAchievement.unlockedAt).inHours < 1;
    if (unlockedRecently || widget.userAchievement.isNew) {
      _confettiController.forward();
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final achievement = widget.userAchievement.achievement;
    final dateFormat = DateFormat.yMMMd().add_jm();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Fancy app bar with full bleed image/gradient background
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            pinned: true,
            stretch: true,
            backgroundColor: achievement.category.color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          achievement.category.color,
                          _getBadgeColor(achievement),
                        ],
                      ),
                    ),
                  ),
                  
                  // Pattern overlay
                  CustomPaint(
                    painter: PatternPainter(
                      color: Colors.white.withOpacity(0.05),
                      patternSize: 20,
                    ),
                  ),
                  
                  // Confetti animation
                  if (_confettiController.isAnimating || widget.userAchievement.isNew)
                    ConfettiWidget(
                      animation: _confettiController,
                      color: widget.userAchievement.achievement.category.color,
                    ),
                  
                  // Achievement content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48), // Space for the app bar
                      
                      // Achievement badge
                      Hero(
                        tag: 'achievement_${widget.userAchievement.id}',
                        child: AchievementBadge(
                          userAchievement: widget.userAchievement,
                          size: 120,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Achievement title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          achievement.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(
                        duration: 500.ms,
                        delay: 300.ms,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Achievement description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          achievement.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(
                        duration: 500.ms,
                        delay: 600.ms,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Achievement details and stats
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat cards
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStatCards(achievement, dateFormat),
                  ),
                  
                  const Divider(),
                  
                  // Achievement details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this Achievement',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Detail cards
                        EnhancedDetailCard(
                          icon: Icons.calendar_today,
                          title: 'Unlocked On',
                          value: dateFormat.format(widget.userAchievement.unlockedAt),
                          color: Colors.blue,
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        EnhancedDetailCard(
                          icon: Icons.star,
                          title: 'Points Earned',
                          value: '${achievement.points} XP',
                          color: Colors.amber,
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        EnhancedDetailCard(
                          icon: achievement.category.icon,
                          title: 'Category',
                          value: achievement.category.displayName,
                          color: achievement.category.color,
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        EnhancedDetailCard(
                          icon: Icons.diamond,
                          title: 'Rarity',
                          value: _getRarityText(achievement),
                          color: _getRarityColor(achievement),
                          isDarkMode: isDarkMode,
                        ),
                        
                        if (achievement.criteria != null) ...[
                          const SizedBox(height: 12),
                          EnhancedDetailCard(
                            icon: Icons.check_circle_outline,
                            title: 'Requirements',
                            value: _formatRequirements(achievement.criteria!),
                            color: Colors.green,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievement tips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: achievement.category.color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pro Tip',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: achievement.category.color,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getTipForAchievement(achievement),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Share button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareAchievement(context, achievement),
                        icon: const Icon(Icons.share),
                        label: const Text('Share Achievement'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: achievement.category.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }
  
  Widget _buildStatCards(Achievement achievement, DateFormat dateFormat) {
    return Row(
      children: [
        // Points stat card
        Expanded(
          child: StatCard(
            value: '${achievement.points}',
            label: 'XP Points',
            icon: Icons.star,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        
        // Rarity stat card
        Expanded(
          child: StatCard(
            value: _getRarityShortText(achievement),
            label: 'Rarity',
            icon: Icons.diamond,
            color: _getRarityColor(achievement),
          ),
        ),
        const SizedBox(width: 12),
        
        // Days ago stat card
        Expanded(
          child: StatCard(
            value: _getDaysAgo(widget.userAchievement.unlockedAt),
            label: 'Days Ago',
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
  
  Color _getRarityColor(Achievement achievement) {
    if (achievement.isSecret) {
      return Colors.purple;
    } else if (achievement.requiredLevel >= 20) {
      return Colors.deepOrange;
    } else if (achievement.requiredLevel >= 10) {
      return Colors.teal;
    } else if (achievement.requiredLevel >= 5) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
  
  String _getRarityText(Achievement achievement) {
    if (achievement.isSecret) {
      return 'Secret Achievement';
    } else if (achievement.requiredLevel >= 20) {
      return 'Epic';
    } else if (achievement.requiredLevel >= 10) {
      return 'Rare';
    } else if (achievement.requiredLevel >= 5) {
      return 'Uncommon';
    } else {
      return 'Common';
    }
  }
  
  String _getRarityShortText(Achievement achievement) {
    if (achievement.isSecret) {
      return 'Secret';
    } else if (achievement.requiredLevel >= 20) {
      return 'Epic';
    } else if (achievement.requiredLevel >= 10) {
      return 'Rare';
    } else if (achievement.requiredLevel >= 5) {
      return 'Uncommon';
    } else {
      return 'Common';
    }
  }
  
  String _getDaysAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days';
  }
  
  String _formatRequirements(Map<String, dynamic> criteria) {
    if (criteria.containsKey('completed_quests')) {
      return 'Complete ${criteria['completed_quests']} quests';
    } else if (criteria.containsKey('streak_days')) {
      return 'Maintain a ${criteria['streak_days']}-day streak';
    } else if (criteria.containsKey('completed_epic_quest')) {
      return 'Complete an epic difficulty quest';
    }
    return 'Custom requirement';
  }
  
  Color _getBadgeColor(Achievement achievement) {
    if (achievement.badgeColor != null) {
      try {
        return Color(int.parse(achievement.badgeColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return achievement.category.color;
      }
    }
    return achievement.category.color;
  }
  
  String _getTipForAchievement(Achievement achievement) {
    switch (achievement.category) {
      case AchievementCategory.quest:
        return 'Complete daily quests to unlock more quest achievements and earn additional XP points!';
      case AchievementCategory.level:
        return 'Gain experience points by completing quests and unlocking other achievements to level up faster!';
      case AchievementCategory.streak:
        return 'Log in daily and complete at least one quest each day to maintain your streak and unlock special rewards!';
      case AchievementCategory.special:
        return 'Explore all features of the app and complete challenges to discover secret achievements!';
    }
  }
  
  Future<void> _shareAchievement(BuildContext context, Achievement achievement) async {
    try {
      final shareText = 'I just earned the "${achievement.title}" achievement in Life Quest! '
          '${achievement.description} #LifeQuest #Achievement';
      
      await Share.share(shareText);
    } catch (e) {
      ErrorHandler.logError('Failed to share achievement', e);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share achievement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
