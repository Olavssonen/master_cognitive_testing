import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import '../theme/app_theme.dart';

class SessionPathWidget extends StatefulWidget {
  final int currentIndex;
  final int totalTests;
  final List<TestDefinition> testRegistry;
  final List<String> testPlan;

  const SessionPathWidget({
    Key? key,
    required this.currentIndex,
    required this.totalTests,
    required this.testRegistry,
    required this.testPlan,
  }) : super(key: key);

  @override
  State<SessionPathWidget> createState() => _SessionPathWidgetState();
}

class _SessionPathWidgetState extends State<SessionPathWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    // Start animation on initial load
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SessionPathWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If currentIndex changed, trigger new animation
    if (oldWidget.currentIndex != widget.currentIndex) {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: SessionPathPainter(
            currentIndex: widget.currentIndex,
            totalTests: widget.totalTests,
            animationProgress: _animation.value,
            testRegistry: widget.testRegistry,
            testPlan: widget.testPlan,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class SessionPathPainter extends CustomPainter {
  final int currentIndex;
  final int totalTests;
  final double animationProgress;
  final List<TestDefinition> testRegistry;
  final List<String> testPlan;

  SessionPathPainter({
    required this.currentIndex,
    required this.totalTests,
    this.animationProgress = 0,
    required this.testRegistry,
    required this.testPlan,
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
    _drawPoints(canvas, positions, animationProgress);
    
    // Draw rings on top to cover pipe overlap
    _drawPointRings(canvas, positions, animationProgress);
  }

  void _drawPointRings(Canvas canvas, List<Offset> positions, [double animationProgress = 0]) {
    const double pointRadius = 38;
    const double ringWidth = 8;
    final isAnimatingToGoal = currentIndex >= positions.length - 2;

    for (int i = 0; i < positions.length; i++) {
      // Completed stops are teal, or animation target after it's nearly complete
      final isCompleted = i <= currentIndex + 1 && !(isAnimatingToGoal && i == positions.length - 1);
      final isAnimationTarget = i == currentIndex + 2 && animationProgress >= 0.90;
      final isGoalTarget = isAnimatingToGoal && i == positions.length - 1 && animationProgress >= 0.90;

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

  void _drawAnimationFill(Canvas canvas, List<Offset> positions, double progress, int currentIndex) {
    // Check if animating to the final goal
    final isAnimatingToGoal = currentIndex >= positions.length - 2;
    
    if (isAnimatingToGoal) {
      // Draw all segments before the final one as complete
      for (int i = 0; i < positions.length - 2; i++) {
        _drawSegmentFilled(canvas, positions[i], positions[i + 1], 1.0);
      }
      // Animate only the final segment to the goal
      if (progress > 0.001) {
        _drawSegmentFilled(canvas, positions[positions.length - 2], positions[positions.length - 1], progress);
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
        _drawSegmentFilled(canvas, positions[currentIndex + 1], positions[currentIndex + 2], progress);
      }
    }
  }

  void _drawSegmentFilled(Canvas canvas, Offset startPos, Offset endPos, double progress) {
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
      final double x = oneMinusT * oneMinusT * oneMinusT * startPos.dx +
          3 * oneMinusT * oneMinusT * clampedT * controlX1 +
          3 * oneMinusT * clampedT * clampedT * controlX2 +
          clampedT * clampedT * clampedT * endPos.dx;
      
      final double y = oneMinusT * oneMinusT * oneMinusT * startPos.dy +
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
      
      path.cubicTo(
        controlX1,
        midY,
        controlX2,
        midY,
        curr.dx,
        curr.dy,
      );
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

  void _drawPoints(Canvas canvas, List<Offset> positions, [double animationProgress = 0]) {
    const double pointRadius = 40;
    const double ringWidth = 8;
    final isAnimatingToGoal = currentIndex >= positions.length - 2;

    for (int i = 0; i < positions.length; i++) {
      // Completed stops are inverted, animation target is not inverted (only after animation is nearly complete)
      final isCompleted = i <= currentIndex + 1 && !(isAnimatingToGoal && i == positions.length - 1);
      final isAnimationTarget = i == currentIndex + 2 && animationProgress >= 0.90;
      final isGoalTarget = isAnimatingToGoal && i == positions.length - 1 && animationProgress >= 0.90;

      Color bgColor;
      Color iconColor;
      
      if (isCompleted) {
        // Inverted: teal bg, white icon
        bgColor = AppColors.tropicalTeal;
        iconColor = Colors.white;
      } else if (isAnimationTarget || isGoalTarget) {
        // Not inverted: white bg, teal icon (and teal ring)
        bgColor = Colors.white;
        iconColor = AppColors.tropicalTeal;
      } else {
        bgColor = Colors.white;
        iconColor = AppColors.crayolaBlue;
      }

      // Draw background circle (slightly larger to integrate with ring)
      final bgPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(positions[i], pointRadius - ringWidth + 2, bgPaint);
      
      // Get the test icon for this position
      IconData? iconData;
      bool isStartOrEnd = (i == 0 || i == positions.length - 1);
      
      if (!isStartOrEnd && i - 1 < testPlan.length) {
        final testId = testPlan[i - 1];
        try {
          final testDef = testRegistry.firstWhere((t) => t.id == testId);
          iconData = testDef.icon;
        } catch (e) {
          // Test not found
        }
      }

      // Draw icon if available (increased size to fill space better)
      if (iconData != null) {
        _drawIcon(canvas, positions[i], iconData, iconColor, pointRadius - ringWidth + 4);
      } else if (isStartOrEnd) {
        // Draw flag icon for start/end (increased size)
        _drawIcon(canvas, positions[i], Icons.flag_rounded, iconColor, pointRadius - ringWidth + 4);
      }
    }
  }

  void _drawIcon(Canvas canvas, Offset position, IconData icon, Color color, double size) {
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

  @override
  bool shouldRepaint(SessionPathPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.totalTests != totalTests ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.testPlan != testPlan;
  }
}
