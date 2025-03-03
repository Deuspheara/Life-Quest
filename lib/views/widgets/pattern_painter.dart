import 'package:flutter/material.dart';

/// A custom painter that creates a dot pattern background
class PatternPainter extends CustomPainter {
  final Color color;
  final double patternSize;
  
  PatternPainter({required this.color, this.patternSize = 20});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    for (double x = 0; x < size.width; x += patternSize * 2) {
      for (double y = 0; y < size.height; y += patternSize * 2) {
        // Draw a small circle at each point
        canvas.drawCircle(
          Offset(x, y),
          patternSize / 10,
          paint,
        );
        
        // Draw a small circle offset to create a pattern
        canvas.drawCircle(
          Offset(x + patternSize, y + patternSize),
          patternSize / 10,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) => 
    color != oldDelegate.color || patternSize != oldDelegate.patternSize;
}
