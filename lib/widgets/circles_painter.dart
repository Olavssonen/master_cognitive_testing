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

  /// Generate fixed circles in a diamond formation for tutorial testing.
  /// For 4 circles, creates a diamond pattern centered on screen.
  /// [horizontalSpacing] controls the horizontal distance from center (in pixels)
  /// [verticalSpacing] controls the vertical distance from center (in pixels)
  void generateFixedCircles4Tutorial(
    double width,
    double height, {
    double horizontalSpacing = 200.0,
    double verticalSpacing = 200.0,
  }) {
    circles = [];

    if (numberOfCircles == 4) {
      // Calculate center of the drawing area
      final centerX = width / 2;
      final centerY = height / 2;

      // Diamond formation: top, right, bottom, left
      final positions = [
        Offset(centerX, centerY - verticalSpacing),        // Top
        Offset(centerX + horizontalSpacing, centerY),      // Right
        Offset(centerX, centerY + verticalSpacing),        // Bottom
        Offset(centerX - horizontalSpacing, centerY),      // Left
      ];

      for (int i = 0; i < numberOfCircles && i < positions.length; i++) {
        circles.add(
          Circle(
            center: positions[i],
            radius: circleRadius,
            label: _getLabel(i + 1),
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
  final AnimationController? fingerAnimationController;
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
    this.fingerAnimationController,
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

    // Draw animated finger guide from circle 1 to circle 2
    if (circles.isNotEmpty && circles.length >= 2 && fingerAnimationController != null && !testComplete && fingerAnimationController!.isAnimating) {
      _drawAnimatedFinger(canvas, circles[0].center, circles[1].center, fingerAnimationController!.value);
    }
  }

  /// Draw an animated icon (Icons.touch_app) moving along a path with fade out at end
  void _drawAnimatedFinger(Canvas canvas, Offset start, Offset end, double progress) {
    // Interpolate position along the path
    final currentPos = Offset.lerp(start, end, progress)!;
    
    // Calculate fade out: starts at 1.0, fades to 0.0 as progress goes to 1.0
    // Use a non-linear fade for smoother effect (start fading at 70% progress)
    final fadeStart = 0.7;
    double opacity = 1.0;
    if (progress >= fadeStart) {
      opacity = 1.0 - ((progress - fadeStart) / (1.0 - fadeStart));
    }

    // Draw the Icons.touch_app icon using TextPainter
    final iconTextPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.touch_app.codePoint),
        style: TextStyle(
          color: AppColors.accent.withValues(alpha: opacity),
          fontSize: 70,
          fontFamily: Icons.touch_app.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    iconTextPainter.layout();
    
    // Draw icon centered at currentPos with a slight shadow for visibility
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(currentPos, 24, shadowPaint);
    
    // Draw the icon
    final iconOffset = currentPos - Offset(iconTextPainter.width / 2, iconTextPainter.height / 2);
    iconTextPainter.paint(canvas, iconOffset);
  }

  @override
  bool shouldRepaint(DrawAreaPainter oldDelegate) {
    if (activePulseController != null && oldDelegate.activePulseController != null) {
      if (activePulseController!.value != oldDelegate.activePulseController!.value) {
        return true;
      }
    }
    if (fingerAnimationController != null && oldDelegate.fingerAnimationController != null) {
      if (fingerAnimationController!.value != oldDelegate.fingerAnimationController!.value) {
        return true;
      }
    }
    return true;
  }
}

