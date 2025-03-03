import 'package:flutter/material.dart';

/// A custom painter that creates a confetti animation effect
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  ConfettiPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final paint = Paint()..color = color;
    
    for (int i = 0; i < 100; i++) {
      final x = (random % (i + 1) * 937) % size.width;
      final y = progress * size.height - 
          (random % (i + 1) * 443) % (size.height * 0.5);
      final particleSize = (random % (i + 1) * 331) % 10 + 2.0;
      
      if (y > 0 && y < size.height) {
        canvas.drawCircle(Offset(x, y), particleSize / 2, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => 
      progress != oldDelegate.progress;
}

/// Widget that displays the confetti animation
class ConfettiWidget extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const ConfettiWidget({
    Key? key,
    required this.animation,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            progress: animation.value,
            color: color,
          ),
          child: Container(),
        );
      },
    );
  }
}
