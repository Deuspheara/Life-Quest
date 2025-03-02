import 'package:flutter/material.dart';
import 'package:life_quest/constants/app_colors.dart';

class LevelProgress extends StatelessWidget {
  final double progress;
  final int currentExp;
  final int targetExp;

  const LevelProgress({
    Key? key,
    required this.progress,
    required this.currentExp,
    required this.targetExp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        // XP counter
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$currentExp / $targetExp XP',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}