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

  /// Generate circles using the original TMT test positions (normalized coordinates).
  /// Positions are based on the standard TMT-A/B test layout.
  /// Only applicable for numbersOnly mode in the main test.
  void generateFixedCirclesTMT(double width, double height) {
    circles = [];

    // Original TMT test positions (normalized 0-1 coordinates)
    final tmtPositions = <String, Map<String, double>>{
      "1": {"x": 0.7208, "y": 0.5370},
      "2": {"x": 0.4910, "y": 0.6539},
      "3": {"x": 0.7914, "y": 0.7097},
      "4": {"x": 0.7655, "y": 0.3315},
      "5": {"x": 0.4220, "y": 0.3552},
      "6": {"x": 0.6078, "y": 0.4388},
      "7": {"x": 0.4102, "y": 0.5327},
      "8": {"x": 0.2651, "y": 0.6891},
      "9": {"x": 0.3161, "y": 0.8030},
      "10": {"x": 0.3922, "y": 0.6776},
      "11": {"x": 0.6651, "y": 0.8303},
      "12": {"x": 0.1545, "y": 0.8667},
      "13": {"x": 0.2416, "y": 0.4430},
      "14": {"x": 0.1294, "y": 0.5703},
      "15": {"x": 0.0776, "y": 0.0642},
      "16": {"x": 0.2416, "y": 0.2200},
      "17": {"x": 0.5349, "y": 0.0448},
      "18": {"x": 0.4973, "y": 0.2497},
      "19": {"x": 0.8008, "y": 0.1333},
      "20": {"x": 0.6322, "y": 0.1224},
      "21": {"x": 0.8831, "y": 0.0448},
      "22": {"x": 0.8996, "y": 0.3255},
      "23": {"x": 0.9357, "y": 0.8612},
      "24": {"x": 0.8573, "y": 0.5182},
      "25": {"x": 0.8267, "y": 0.8315},
    };

    // Generate circles based on numberOfCircles (up to 25)
    for (int i = 1; i <= numberOfCircles && i <= 25; i++) {
      final posKey = i.toString();
      final pos = tmtPositions[posKey];

      if (pos != null) {
        final screenX = pos["x"]! * width;
        final screenY = pos["y"]! * height;

        circles.add(
          Circle(
            center: Offset(screenX, screenY),
            radius: circleRadius,
            label: _getLabel(i),
          ),
        );
      }
    }
  }

  /// Generate circles using the mixed TMT test positions (normalized coordinates).
  /// Positions are based on the standard TMT-B test layout with mixed numbers and letters.
  /// For mixed mode in the main test.
  void generateFixedCirclesMixed(double width, double height) {
    circles = [];

    // Mixed TMT test positions (normalized 0-1 coordinates)
    // Contains both number positions (1-13) and letter positions (A-L)
    final mixedPositions = <String, Map<String, double>>{
      // Numbers (1-13)
      "1": {"x": 0.4918, "y": 0.4188},
      "2": {"x": 0.2533, "y": 0.7618},
      "3": {"x": 0.4267, "y": 0.2939},
      "4": {"x": 0.5451, "y": 0.1606},
      "5": {"x": 0.7820, "y": 0.4648},
      "6": {"x": 0.4118, "y": 0.7727},
      "7": {"x": 0.2878, "y": 0.3945},
      "8": {"x": 0.1302, "y": 0.1121},
      "9": {"x": 0.2949, "y": 0.1133},
      "10": {"x": 0.9231, "y": 0.0703},
      "11": {"x": 0.8769, "y": 0.9139},
      "12": {"x": 0.0580, "y": 0.5618},
      "13": {"x": 0.0651, "y": 0.0497},
      // Letters (A-L)
      "A": {"x": 0.6745, "y": 0.6867},
      "B": {"x": 0.4275, "y": 0.1794},
      "C": {"x": 0.6392, "y": 0.5358},
      "D": {"x": 0.8016, "y": 0.1261},
      "E": {"x": 0.8031, "y": 0.8418},
      "F": {"x": 0.1584, "y": 0.8533},
      "G": {"x": 0.1663, "y": 0.6067},
      "H": {"x": 0.1765, "y": 0.4788},
      "I": {"x": 0.6518, "y": 0.1188},
      "J": {"x": 0.8180, "y": 0.6994},
      "K": {"x": 0.0620, "y": 0.8988},
      "L": {"x": 0.1200, "y": 0.7848},
    };

    // Generate circles for mixed mode
    // Interleave numbers and letters: 1, A, 2, B, 3, C, etc.
    List<String> circleKeys = [];
    for (int i = 1; i <= 13; i++) {
      circleKeys.add(i.toString());
      final letterChar = String.fromCharCode(64 + i); // A=65, B=66, etc.
      if (i <= 12) {
        // Only add letters A-L (12 letters total)
        circleKeys.add(letterChar);
      }
    }

    final keysToUse = circleKeys.take(numberOfCircles).toList();

    // Fit the validated paper layout into a safe drawing area with one uniform
    // scale factor so all relative placements are preserved.
    final rawOffsets = <Offset>[];
    for (final key in keysToUse) {
      final pos = mixedPositions[key];
      if (pos != null) {
        rawOffsets.add(Offset(pos["x"]! * width, pos["y"]! * height));
      }
    }

    if (rawOffsets.isEmpty) {
      return;
    }

    final minRawX = rawOffsets.map((p) => p.dx).reduce(min);
    final maxRawX = rawOffsets.map((p) => p.dx).reduce(max);
    final minRawY = rawOffsets.map((p) => p.dy).reduce(min);
    final maxRawY = rawOffsets.map((p) => p.dy).reduce(max);

    final rawWidth = max(1.0, maxRawX - minRawX);
    final rawHeight = max(1.0, maxRawY - minRawY);

    final leftPadding = circleRadius + 8.0;
    final rightPadding = circleRadius + 8.0;
    final topPadding = max(circleRadius + 8.0, 78.0);
    final bottomPadding = circleRadius + 8.0;

    final safeWidth = max(1.0, width - leftPadding - rightPadding);
    final safeHeight = max(1.0, height - topPadding - bottomPadding);

    final fitScale = min(safeWidth / rawWidth, safeHeight / rawHeight);
    final scale = min(1.0, fitScale);

    final scaledWidth = rawWidth * scale;
    final scaledHeight = rawHeight * scale;
    final offsetX = leftPadding + (safeWidth - scaledWidth) / 2 - minRawX * scale;
    final offsetY = topPadding + (safeHeight - scaledHeight) / 2 - minRawY * scale;

    for (final key in keysToUse) {
      final pos = mixedPositions[key];

      if (pos != null) {
        final rawX = pos["x"]! * width;
        final rawY = pos["y"]! * height;
        final screenX = (rawX * scale) + offsetX;
        final screenY = (rawY * scale) + offsetY;

        circles.add(
          Circle(
            center: Offset(screenX, screenY),
            radius: circleRadius,
            label: key,
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
  final String? startLabel; // Label for first circle (e.g., "Start")
  final String? stopLabel; // Label for last circle (e.g., "Stop")

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
    this.startLabel,
    this.stopLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw animated finger path line FIRST (underneath circles)
    if (circles.isNotEmpty && fingerAnimationController != null && !testComplete && fingerAnimationController!.isAnimating) {
      // Always animate from the first circle through all remaining ones
      // This keeps the animation consistent and unaffected by user drawing progress
      int startIndex = 0;
      if (startIndex < circles.length) {
        _drawAnimatedFingerLine(canvas, circles, startIndex, fingerAnimationController!.value);
      }
    }
    
    // Draw circles
    for (final circle in circles) {
      // Check if this circle has been correctly entered
      bool isEntered = circlesEntered.contains(circle.label);

      // Check if this circle has active feedback animation
      double scale = 1.0;
      Color circleColor = isEntered
          ? AppColors.grey900.withValues(alpha: 0.2) // Nearly transparent for entered
          : AppColors.accent.withValues(alpha: 0.7);

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
      
      // Draw start/stop labels above first and last circles
      if (circles.isNotEmpty) {
        if (circle == circles.first && startLabel != null) {
          final labelPainter = TextPainter(
            text: TextSpan(
              text: startLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          labelPainter.layout();
          final labelOffset = circle.center -
              Offset(labelPainter.width / 2, labelPainter.height + 35);
          labelPainter.paint(canvas, labelOffset);
        }
        if (circle == circles.last && stopLabel != null) {
          final labelPainter = TextPainter(
            text: TextSpan(
              text: stopLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          labelPainter.layout();
          final labelOffset = circle.center -
              Offset(labelPainter.width / 2, labelPainter.height + 35);
          labelPainter.paint(canvas, labelOffset);
        }
      }
    }

    // Draw the user's drawing
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx != -1 && points[i + 1].dx != -1) {
        // Determine if this line segment is correct
        final isCorrectSegment = correctLineSegments.contains(i) && correctLineSegments.contains(i + 1);
        
        final lineColor = isCorrectSegment 
            ? AppColors.accent   // Correct: primary color
            : AppColors.grey300; // Incorrect: light grey
        
        final paint = Paint()
          ..color = lineColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw animated finger guide showing path through all remaining circles
    if (circles.isNotEmpty && fingerAnimationController != null && !testComplete && fingerAnimationController!.isAnimating) {
      // Always animate from the first circle through all remaining ones
      // This keeps the animation consistent and unaffected by user drawing progress
      int startIndex = 0;
      if (startIndex < circles.length) {
        _drawAnimatedFingerPath(canvas, circles, startIndex, fingerAnimationController!.value);
      }
    }
  }

  /// Draw an animated line following the finger path
  void _drawAnimatedFingerLine(Canvas canvas, List<Circle> circles, int startIndex, double overallProgress) {
    if (startIndex >= circles.length) return;
    
    // Build path waypoints from startIndex through all remaining circles
    List<Offset> waypoints = [circles[startIndex].center];
    for (int i = startIndex + 1; i < circles.length; i++) {
      waypoints.add(circles[i].center);
    }
    
    if (waypoints.length < 1) return;
    
    // Calculate total distance for the entire path
    double totalDistance = 0;
    List<double> segmentDistances = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      double segmentDist = (waypoints[i + 1] - waypoints[i]).distance;
      segmentDistances.add(segmentDist);
      totalDistance += segmentDist;
    }
    
    if (totalDistance <= 0) return;
    
    // Calculate how far along the path we should be
    double distanceToCover = totalDistance * overallProgress;
    
    // Draw line from start to current finger position
    final linePaint = Paint()
      ..color = AppColors.grey300
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    Offset currentPos = waypoints[0];
    double accumulatedDistance = 0;
    
    // Trace the path and draw segments
    for (int i = 0; i < segmentDistances.length; i++) {
      if (accumulatedDistance + segmentDistances[i] >= distanceToCover) {
        // We're in this segment - draw from waypoint to current position
        double segmentProgress = (distanceToCover - accumulatedDistance) / segmentDistances[i];
        currentPos = Offset.lerp(waypoints[i], waypoints[i + 1], segmentProgress)!;
        canvas.drawLine(waypoints[i], currentPos, linePaint);
        break;
      } else {
        // This segment is complete - draw the full segment
        canvas.drawLine(waypoints[i], waypoints[i + 1], linePaint);
        accumulatedDistance += segmentDistances[i];
      }
    }
  }

  /// Draw an animated icon (Icons.touch_app) moving along a complete path through circles
  void _drawAnimatedFingerPath(Canvas canvas, List<Circle> circles, int startIndex, double overallProgress) {
    if (startIndex >= circles.length) return;
    
    // Build path waypoints from startIndex through all remaining circles
    List<Offset> waypoints = [circles[startIndex].center];
    for (int i = startIndex + 1; i < circles.length; i++) {
      waypoints.add(circles[i].center);
    }
    
    if (waypoints.length < 2) return;
    
    // Calculate total distance for the entire path
    double totalDistance = 0;
    List<double> segmentDistances = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      double segmentDist = (waypoints[i + 1] - waypoints[i]).distance;
      segmentDistances.add(segmentDist);
      totalDistance += segmentDist;
    }
    
    if (totalDistance <= 0) return;
    
    // Calculate how far along the path we should be
    double distanceToCover = totalDistance * overallProgress;
    Offset currentPos = waypoints[0];
    
    // Find which segment we're in and interpolate position
    double accumulatedDistance = 0;
    for (int i = 0; i < segmentDistances.length; i++) {
      if (accumulatedDistance + segmentDistances[i] >= distanceToCover) {
        // We're in this segment
        double segmentProgress = (distanceToCover - accumulatedDistance) / segmentDistances[i];
        currentPos = Offset.lerp(waypoints[i], waypoints[i + 1], segmentProgress)!;
        break;
      }
      accumulatedDistance += segmentDistances[i];
    }
    
    // Calculate fade out: starts fading at 85% progress
    final fadeStart = 0.85;
    double opacity = 1.0;
    if (overallProgress >= fadeStart) {
      opacity = 1.0 - ((overallProgress - fadeStart) / (1.0 - fadeStart));
    }
    
    _drawFingerIcon(canvas, currentPos, opacity);
  }
  
  /// Helper method to draw the finger icon at a specific position
  void _drawFingerIcon(Canvas canvas, Offset position, double opacity) {
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
    
    // Draw icon centered at position with a slight shadow for visibility
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(position, 24, shadowPaint);
    
    // Draw the icon
    final iconOffset = position - Offset(iconTextPainter.width / 2, iconTextPainter.height / 2);
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

