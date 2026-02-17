import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_master_app/theme/app_theme.dart';

/// Represents a single circle with a center position, radius, and label
class Circle {
  final Offset center;
  final double radius;
  final String label; // Can be number or mixed (1, 2, A, B, etc)

  Circle({
    required this.center,
    required this.radius,
    required this.label,
  });

  bool contains(Offset point) {
    return (point - center).distance <= radius;
  }
}

enum CircleMode {
  numbersOnly, // 1, 2, 3, ...
  mixed, // 1, A, 2, B, 3, C, ...
}

/// Generates labeled circles positioned randomly within a given space
class CirclesWithNumbers {
  final int numberOfCircles;
  final CircleMode mode;
  List<Circle> circles = [];
  final Random random = Random();
  final double circleRadius;

  CirclesWithNumbers({
    required this.numberOfCircles,
    this.mode = CircleMode.numbersOnly,
    this.circleRadius = 30.0,
  });

  /// Get the label for a given position (1-indexed)
  String _getLabel(int position) {
    if (mode == CircleMode.numbersOnly) {
      return position.toString();
    } else {
      // Mixed mode: 1, A, 2, B, 3, C, etc.
      if (position.isOdd) {
        // Odd positions are numbers: 1, 2, 3, ...
        return ((position + 1) ~/ 2).toString();
      } else {
        // Even positions are letters: A, B, C, ...
        final letterIndex = position ~/ 2 - 1;
        return String.fromCharCode(65 + letterIndex); // A=65 in ASCII
      }
    }
  }

  /// Generate circles positioned within [width] x [height].
  void generateCircles(double width, double height) {
    circles = [];
    final minDistance = max(130.0, circleRadius * 3.5);
    int generationAttempts = 0;

    while (circles.length < numberOfCircles && generationAttempts < 50) {
      generationAttempts++;
      Offset position;
      bool validPosition = false;
      int positionAttempts = 0;

      do {
        position = Offset(
          circleRadius + random.nextDouble() * (width - 2 * circleRadius),
          circleRadius + random.nextDouble() * (height - 2 * circleRadius),
        );

        validPosition = circles.every((circle) {
          return (position - circle.center).distance >= minDistance;
        });
        positionAttempts++;
      } while (!validPosition && positionAttempts < 500);

      // Only add the circle if a valid position was found
      if (validPosition) {
        circles.add(
          Circle(
            center: position,
            radius: circleRadius,
            label: _getLabel(circles.length + 1),
          ),
        );
      }
    }
  }
}

/// Custom painter for the circles and drawn lines
class DrawAreaPainter extends CustomPainter {
  final List<Offset> points;
  final List<Circle> circles;
  final Map<String, AnimationController> feedbackControllers;
  final Map<String, bool> feedbackType; // true = correct, false = wrong
  final List<String> circlesEntered;
  final AnimationController? activePulseController;
  final String requiredCircle;
  final bool testComplete;
  final Set<int> correctLineSegments; // Indices of points that are part of correct line segments

  DrawAreaPainter({
    required this.points,
    required this.circles,
    this.feedbackControllers = const {},
    this.feedbackType = const {},
    this.circlesEntered = const [],
    this.activePulseController,
    this.requiredCircle = '1',
    this.testComplete = false,
    this.correctLineSegments = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw circles
    for (final circle in circles) {
      // Check if this circle has been correctly entered
      bool isEntered = circlesEntered.contains(circle.label);

      // Check if this circle has active feedback animation
      double scale = 1.0;
      Color circleColor = isEntered
          ? AppColors.grey900.withValues(alpha: 0.2) // Nearly transparent for entered
          : AppColors.grey900.withValues(alpha: 0.7);

      if (feedbackControllers.containsKey(circle.label)) {
        final controller = feedbackControllers[circle.label]!;
        if (controller.isAnimating) {
          final isCorrect = feedbackType[circle.label] ?? true;

          if (isCorrect) {
            // Correct: scale up and brighten
            scale = 1.0 + (controller.value * 0.1);
            circleColor = AppColors.grey700.withValues(alpha: 0.8);
          } else {
            // Wrong: shrink and darken/tint red
            scale = 1.0 - (controller.value * 0.1);
            circleColor = Color.lerp(
              AppColors.grey900.withValues(alpha: 0.7),
              const Color.fromARGB(230, 204, 0, 0),
              controller.value * 0.6,
            )!;
          }
        }
      }

      final scaledRadius = circle.radius * scale;

      // Apply pulse effect if this is the required circle
      if (circle.label == requiredCircle &&
          !testComplete &&
          activePulseController != null &&
          activePulseController!.isAnimating) {
        final pulseValue = activePulseController!.value;

        // Pulsing border
        final borderWidth = 2.0 + (pulseValue * 3.0);
        final borderPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.8 - (pulseValue * 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(
            circle.center, scaledRadius + (pulseValue * 8.0), borderPaint);

        // Pulsing color tint
        final originalColor = circleColor;
        final tintedColor = Color.lerp(
          originalColor,
          AppColors.accent.withValues(alpha: 0.3),
          (pulseValue * 0.5).clamp(0.0, 1.0),
        )!;
        circleColor = tintedColor;
      }

      // Circle fill
      final circlePaint = Paint()
        ..color = circleColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(circle.center, scaledRadius, circlePaint);

      // Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: circle.label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = circle.center -
          Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }

    // Draw the user's drawing
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx != -1 && points[i + 1].dx != -1) {
        // Determine if this line segment is correct
        final isCorrectSegment = correctLineSegments.contains(i) && correctLineSegments.contains(i + 1);
        
        final lineColor = isCorrectSegment 
            ? AppColors.grey900  // Correct: black
            : AppColors.grey300; // Incorrect: light grey
        
        final paint = Paint()
          ..color = lineColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawAreaPainter oldDelegate) {
    if (activePulseController != null && oldDelegate.activePulseController != null) {
      if (activePulseController!.value != oldDelegate.activePulseController!.value) {
        return true;
      }
    }
    return true;
  }
}

