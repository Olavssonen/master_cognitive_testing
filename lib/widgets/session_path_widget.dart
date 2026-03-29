import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/celebration_particles.dart';
import 'package:flutter_master_app/l10n/strings.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import '../theme/app_theme.dart';

/// Helper function to get localized test title
String getLocalizedTestTitle(String testId, AppStrings strings) {
  switch (testId) {
    case 'Counter Test':
      return strings.counterTest;
    case 'Trykk 10 Test':
      return strings.tap10Test;
    case 'Mini-Cog Test':
      return strings.cogTest;
    case 'Trail Making Test':
      return strings.tmtTest;
    case 'Stroop Test':
      return strings.stroopTest;
    default:
      return testId;
  }
}

class SessionPathWidget extends ConsumerStatefulWidget {
  final int currentIndex;
  final int totalTests;
  final List<TestDefinition> testRegistry;
  final List<String> testPlan;
  
  /// Callback when animations complete
  final VoidCallback? onAnimationsComplete;

  const SessionPathWidget({
    super.key,
    required this.currentIndex,
    required this.totalTests,
    required this.testRegistry,
    required this.testPlan,
    this.onAnimationsComplete,
  });

  @override
  ConsumerState<SessionPathWidget> createState() => _SessionPathWidgetState();
}

class _SessionPathWidgetState extends ConsumerState<SessionPathWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _animationReachedSecondary = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // Add listener to call callback when animation reaches 0.9 (when icons turn secondary)
    _animation.addListener(() {
      if (_animation.value >= 0.90 && !_animationReachedSecondary) {
        _animationReachedSecondary = true;
        widget.onAnimationsComplete?.call();
      }
    });

    // Start animation on initial load
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SessionPathWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If currentIndex changed, trigger new animation
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationReachedSecondary = false;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            CustomPaint(
              painter: SessionPathPainter(
                currentIndex: widget.currentIndex,
                totalTests: widget.totalTests,
                animationProgress: _animation.value,
                testRegistry: widget.testRegistry,
                testPlan: widget.testPlan,
                strings: strings,
              ),
              size: Size.infinite,
            ),
            // Celebration particles overlay
            LayoutBuilder(
              builder: (context, constraints) {
                final positions = _calculatePositions(
                  Size(constraints.maxWidth, constraints.maxHeight),
                  widget.totalTests,
                );
                final isAnimatingToGoal =
                    widget.currentIndex >= widget.totalTests;

                return CelebrationParticlesWidget(
                  currentIndex: widget.currentIndex,
                  animationProgress: _animation.value,
                  positions: positions,
                  celebrateOnReachGoal: isAnimatingToGoal,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Calculate positions along the path - same logic as SessionPathPainter
  List<Offset> _calculatePositions(Size size, int totalTests) {
    final totalPoints = totalTests + 2;
    final List<Offset> positions = [];
    final double pointSpacing = (size.height - 320) / (totalPoints - 1);
    final double centerX = size.width / 2;
    final double maxWave = 240;

    for (int i = 0; i < totalPoints; i++) {
      final double y = 140 + (i * pointSpacing);

      double waveAmount;
      if (i == 0 || i == totalPoints - 1) {
        waveAmount = 0;
      } else {
        waveAmount = (i % 2 == 0) ? -maxWave : maxWave;
      }
      final double x = centerX + waveAmount;

      positions.add(Offset(x, y));
    }

    return positions;
  }
}

class SessionPathPainter extends CustomPainter {
  final int currentIndex;
  final int totalTests;
  final double animationProgress;
  final List<TestDefinition> testRegistry;
  final List<String> testPlan;
  final AppStrings strings;

  SessionPathPainter({
    required this.currentIndex,
    required this.totalTests,
    this.animationProgress = 0,
    required this.testRegistry,
    required this.testPlan,
    required this.strings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Total points: 1 start + totalTests + 1 goal
    final totalPoints = totalTests + 2;

    // Calculate positions along a winding path
    final List<Offset> positions = [];
    final double pointSpacing = (size.height - 320) / (totalPoints - 1);
    final double centerX = size.width / 2;
    final double maxWave = 240;

    for (int i = 0; i < totalPoints; i++) {
      final double y = 140 + (i * pointSpacing);

      // Create a snake pattern - first and last stay in center, middle ones go wide
      double waveAmount;
      if (i == 0 || i == totalPoints - 1) {
        waveAmount = 0; // First and last stay in center
      } else {
        waveAmount = (i % 2 == 0) ? -maxWave : maxWave;
      }
      final double x = centerX + waveAmount;

      positions.add(Offset(x, y));
    }

    // Draw the path line
    _drawPath(canvas, positions);

    // Draw animation fill on first load and subsequent transitions
    if (animationProgress > 0 && positions.length > 1) {
      _drawAnimationFill(canvas, positions, animationProgress, currentIndex);
    }

    // Draw the points
    _drawPoints(canvas, positions, animationProgress, size.width);

    // Draw rings on top to cover pipe overlap
    _drawPointRings(canvas, positions, animationProgress);
  }

  void _drawPointRings(
    Canvas canvas,
    List<Offset> positions, [
    double animationProgress = 0,
  ]) {
    const double pointRadius = 38;
    const double ringWidth = 8;
    final isAnimatingToGoal = currentIndex >= positions.length - 2;

    for (int i = 0; i < positions.length; i++) {
      // Completed stops are teal, or animation target after it's nearly complete
      final isCompleted =
          i <= currentIndex + 1 &&
          !(isAnimatingToGoal && i == positions.length - 1);
      final isAnimationTarget =
          i == currentIndex + 2 && animationProgress >= 0.90;
      final isGoalTarget =
          isAnimatingToGoal &&
          i == positions.length - 1 &&
          animationProgress >= 0.90;

      Color pointColor;
      if (isCompleted || isAnimationTarget || isGoalTarget) {
        pointColor = AppColors.tropicalTeal;
      } else {
        pointColor = AppColors.crayolaBlue;
      }

      // Draw outer ring on top with larger thickness
      final ringPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth;

      canvas.drawCircle(positions[i], pointRadius, ringPaint);
    }
  }

  void _drawAnimationFill(
    Canvas canvas,
    List<Offset> positions,
    double progress,
    int currentIndex,
  ) {
    // Check if animating to the final goal
    final isAnimatingToGoal = currentIndex >= positions.length - 2;

    if (isAnimatingToGoal) {
      // Draw all segments before the final one as complete
      for (int i = 0; i < positions.length - 2; i++) {
        _drawSegmentFilled(canvas, positions[i], positions[i + 1], 1.0);
      }
      // Animate only the final segment to the goal
      if (progress > 0.001) {
        _drawSegmentFilled(
          canvas,
          positions[positions.length - 2],
          positions[positions.length - 1],
          progress,
        );
      }
    } else {
      // Normal test transition logic
      // Draw all completed segments as teal (permanent)
      for (int i = 0; i <= currentIndex; i++) {
        if (i < positions.length - 1) {
          _drawSegmentFilled(canvas, positions[i], positions[i + 1], 1.0);
        }
      }

      // Animate the next segment if not at the end
      if (progress > 0.001 && currentIndex + 1 < positions.length - 1) {
        _drawSegmentFilled(
          canvas,
          positions[currentIndex + 1],
          positions[currentIndex + 2],
          progress,
        );
      }
    }
  }

  void _drawSegmentFilled(
    Canvas canvas,
    Offset startPos,
    Offset endPos,
    double progress,
  ) {
    if (progress < 0.001) return;

    final double midY = (startPos.dy + endPos.dy) / 2;
    final double controlX1 = startPos.dx;
    final double controlX2 = endPos.dx;

    // Build the path segment-by-segment up to the progress point
    final filledPath = Path();
    filledPath.moveTo(startPos.dx, startPos.dy);

    const int segments = 50;
    final int segmentCount = (segments * progress).ceil();

    for (int i = 0; i < segmentCount; i++) {
      // Calculate t value for this segment
      final double t = (i + 1) / segments;

      // Clamp t to progress
      final double clampedT = t > progress ? progress : t;

      // Calculate point on cubic Bezier curve
      final double oneMinusT = 1 - clampedT;
      final double x =
          oneMinusT * oneMinusT * oneMinusT * startPos.dx +
          3 * oneMinusT * oneMinusT * clampedT * controlX1 +
          3 * oneMinusT * clampedT * clampedT * controlX2 +
          clampedT * clampedT * clampedT * endPos.dx;

      final double y =
          oneMinusT * oneMinusT * oneMinusT * startPos.dy +
          3 * oneMinusT * oneMinusT * clampedT * midY +
          3 * oneMinusT * clampedT * clampedT * midY +
          clampedT * clampedT * clampedT * endPos.dy;

      filledPath.lineTo(x, y);
    }

    // Draw filled pipe with teal (single line with full pipe width)
    final fillPaint = Paint()
      ..color = AppColors.tropicalTeal
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(filledPath, fillPaint);
  }

  void _drawPath(Canvas canvas, List<Offset> positions) {
    final path = Path();
    path.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 1; i < positions.length; i++) {
      final prev = positions[i - 1];
      final curr = positions[i];

      // Create smooth curves between points
      final double midY = (prev.dy + curr.dy) / 2;
      final double controlX1 = prev.dx;
      final double controlX2 = curr.dx;

      path.cubicTo(controlX1, midY, controlX2, midY, curr.dx, curr.dy);
    }

    // Draw outer pipe (primary color)
    final outerPaint = Paint()
      ..color = AppColors.crayolaBlue
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, outerPaint);

    // Draw inner hollow (background color to create pipe effect)
    final innerPaint = Paint()
      ..color = AppColors.platinum
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, innerPaint);
  }

  void _drawPoints(
    Canvas canvas,
    List<Offset> positions,
    double animationProgress,
    double screenWidth,
  ) {
    const double pointRadius = 40;
    const double ringWidth = 8;
    final isAnimatingToGoal = currentIndex >= positions.length - 2;
    final double centerX = screenWidth / 2;

    for (int i = 0; i < positions.length; i++) {
      // Completed stops are inverted, animation target is not inverted (only after animation is nearly complete)
      final isCompleted =
          i <= currentIndex + 1 &&
          !(isAnimatingToGoal && i == positions.length - 1);
      final isAnimationTarget =
          i == currentIndex + 2 && animationProgress >= 0.90;
      final isGoalTarget =
          isAnimatingToGoal &&
          i == positions.length - 1 &&
          animationProgress >= 0.90;

      Color bgColor;
      Color iconColor;
      Color textColor;

      if (isCompleted) {
        // Inverted: teal bg, white icon, teal text
        bgColor = AppColors.tropicalTeal;
        iconColor = Colors.white;
        textColor = AppColors.tropicalTeal;
      } else if (isAnimationTarget || isGoalTarget) {
        // Not inverted: white bg, teal icon (and teal ring), teal text
        bgColor = Colors.white;
        iconColor = AppColors.tropicalTeal;
        textColor = AppColors.tropicalTeal;
      } else {
        bgColor = Colors.white;
        iconColor = AppColors.crayolaBlue;
        textColor = AppColors.crayolaBlue;
      }

      // Draw background circle (slightly larger to integrate with ring)
      final bgPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(positions[i], pointRadius - ringWidth + 2, bgPaint);

      // Get the test icon and title for this position
      IconData? iconData;
      String? testTitle;
      bool isStartOrEnd = (i == 0 || i == positions.length - 1);

      if (!isStartOrEnd && i - 1 < testPlan.length) {
        final testId = testPlan[i - 1];
        try {
          final testDef = testRegistry.firstWhere((t) => t.id == testId);
          iconData = testDef.icon;
          testTitle = getLocalizedTestTitle(testId, strings);
        } catch (e) {
          // Test not found
        }
      }

      // Draw icon and text if available
      if (iconData != null) {
        _drawIconWithText(
          canvas,
          positions[i],
          iconData,
          iconColor,
          testTitle,
          textColor,
          pointRadius - ringWidth + 4,
          centerX,
        );
      } else if (isStartOrEnd) {
        // Draw flag icon for start/end (increased size)
        _drawIcon(
          canvas,
          positions[i],
          Icons.flag_rounded,
          iconColor,
          pointRadius - ringWidth + 4,
        );
        
        // Draw start/end labels
        if (i == 0) {
          // Draw start label above the first icon
          _drawStartEndLabel(
            canvas,
            positions[i],
            strings.start,
            textColor,
            true,
          );
        } else if (i == positions.length - 1) {
          // Draw goal label below the last icon
          _drawStartEndLabel(
            canvas,
            positions[i],
            strings.clockGoalTime,
            textColor,
            false,
          );
        }
      }
    }
  }

  void _drawIcon(
    Canvas canvas,
    Offset position,
    IconData icon,
    Color color,
    double size,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawIconWithText(
    Canvas canvas,
    Offset position,
    IconData icon,
    Color iconColor,
    String? testTitle,
    Color textColor,
    double iconSize,
    double centerX,
  ) {
    // Draw the icon
    _drawIcon(
      canvas,
      position,
      icon,
      iconColor,
      iconSize * 0.6, // Make icon smaller to leave room for text
    );

    // Draw the test title text on the inside (towards center) of the icon
    if (testTitle != null && testTitle.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: testTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 200);
      
      const double ringRadius = 48; // pointRadius (40) + ringWidth (8)
      const double padding = 50; // Space between ring and text
      const double lineWidth = 3.5;
      const double lineGap = 10; // Space between line and icon/text
      
      // Determine text position based on icon position relative to center
      double textLeftX;
      
      if (position.dx < centerX) {
        // Icon on left side - place text to the right (towards center)
        textLeftX = position.dx + ringRadius + padding;
      } else if (position.dx > centerX) {
        // Icon on right side - place text to the left (towards center)
        textLeftX = position.dx - ringRadius - padding - textPainter.width;
      } else {
        // Icon at center - center the text
        textLeftX = position.dx - textPainter.width / 2;
      }
      
      final textY = position.dy - textPainter.height / 2;
      
      // Draw connecting line
      if (position.dx < centerX) {
        // Icon on left side - line from ring to text start
        final linePaint = Paint()
          ..color = textColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;
        
        canvas.drawLine(
          Offset(position.dx + ringRadius + lineGap, position.dy),
          Offset(textLeftX - lineGap, position.dy),
          linePaint,
        );
      } else if (position.dx > centerX) {
        // Icon on right side - line from ring to text end
        final linePaint = Paint()
          ..color = textColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;
        
        canvas.drawLine(
          Offset(position.dx - ringRadius - lineGap, position.dy),
          Offset(textLeftX + textPainter.width + lineGap, position.dy),
          linePaint,
        );
      }
      
      textPainter.paint(
        canvas,
        Offset(textLeftX, textY),
      );
    }
  }

  void _drawStartEndLabel(
    Canvas canvas,
    Offset position,
    String label,
    Color color,
    bool isAbove,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    const double ringRadius = 48; // pointRadius (40) + ringWidth (8)
    const double padding = 15; // Space between ring and label
    
    // Position label above or below the icon
    final labelY = isAbove 
        ? position.dy - ringRadius - padding - textPainter.height
        : position.dy + ringRadius + padding;
    
    final labelX = position.dx - textPainter.width / 2;
    
    textPainter.paint(
      canvas,
      Offset(labelX, labelY),
    );
  }

  @override
  bool shouldRepaint(SessionPathPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.totalTests != totalTests ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.testPlan != testPlan;
  }
}
