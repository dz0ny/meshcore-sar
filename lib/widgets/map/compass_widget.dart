import 'dart:math';
import 'package:flutter/material.dart';
import 'compass/compass_math.dart';

class CompassWidget extends StatelessWidget {
  final double heading;
  final bool hasHeading;

  const CompassWidget({
    super.key,
    required this.heading,
    required this.hasHeading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotate the rose opposite the heading under the fixed needle.
            Transform.rotate(
              angle: compassRoseRotationRadians(heading),
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _CompassRosePainter(),
              ),
            ),
            // Fixed needle pointing up (since map rotates)
            Icon(
              Icons.navigation,
              color: hasHeading ? Colors.red : Colors.grey,
              size: 28,
            ),
            // Heading text
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasHeading ? '${heading.round()}°' : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    canvas.drawCircle(center, radius, paint);

    // Draw cardinal direction markers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2; // Start from North (top)
      final x = center.dx + radius * 0.7 * cos(angle);
      final y = center.dy + radius * 0.7 * sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
