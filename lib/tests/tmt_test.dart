import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'dart:math';

final tmtTest = TestDefinition(
  id: 'TMT',
  title: 'Trail Making Test',
  icon: Icons.draw,
  build: (context, run) => TMTTest(run: run),
);

class TMTTest extends StatefulWidget {
  final TestRunContext run;
  const TMTTest({super.key, required this.run});

  @override
  State<TMTTest> createState() => _TMTTest();
}

class _TMTTest extends State<TMTTest> {
  late CirclesWithNumbers circlesGenerator;
  List<Offset> drawnPoints = [];
  List<int> circlesEntered = [];
  List<int> _lastFeedbackSequence = []; // Track which circles already got feedback
  Set<int> _allTouchedCircles = {}; // Track ALL circles touched (for wrong circle feedback)
  String feedbackMessage = 'Draw through circles in order';
  bool testComplete = false;
  Function(int, bool)? _feedbackTrigger; // Callback to child widget state
  VoidCallback? _clearDrawingCallback; // Callback to clear child's drawing
  
  // New: Track the last correctly entered circle to validate stroke starts
  int? lastCorrectCircle;

  @override
  void initState() {
    super.initState();
    circlesGenerator = CirclesWithNumbers(numberOfCircles: 6);
  }

  void onCircleEntered(int circleNumber, bool isCorrect) {
    // This is called when parent detects a new circle
    // Trigger feedback in the child widget
    _feedbackTrigger?.call(circleNumber, isCorrect);
  }

  void onDrawingUpdated(List<Offset> points) {
    setState(() {
      drawnPoints = points;
      var result = _getCircleSequenceFromPath(points);
      List<int> newSequence = result['sequence'] as List<int>;
      bool isContinuous = result['isContinuous'] as bool;
      
      // Also detect ALL touched circles (including out-of-sequence ones) for wrong feedback
      Set<int> allTouched = _getAllTouchedCircles(points);
      
      // Trigger feedback for NEW circles in the valid sequence
      for (int i = _lastFeedbackSequence.length; i < newSequence.length; i++) {
        final circleNum = newSequence[i];
        final isCorrect = true; // These are from the valid sequence, so always correct
        onCircleEntered(circleNum, isCorrect);
      }
      
      // Trigger feedback for NEW circles touched (but not in valid sequence) = WRONG/out-of-order
      for (int circleNum in allTouched) {
        if (!_allTouchedCircles.contains(circleNum)) {
          // This circle was just touched
          // Check if it's part of the valid sequence
          if (!newSequence.contains(circleNum)) {
            // Not in valid sequence = WRONG circle
            onCircleEntered(circleNum, false);
          }
        }
      }
      
      _lastFeedbackSequence = newSequence;
      _allTouchedCircles = allTouched;
      circlesEntered = newSequence; // Update the authoritative valid sequence
      
      // Update the last correct circle entered
      if (circlesEntered.isNotEmpty) {
        lastCorrectCircle = circlesEntered.last;
      }
      
      if (circlesEntered.isNotEmpty) {
        // Check if sequence is correct and complete
        bool isCorrectSequence = true;
        for (int i = 0; i < circlesEntered.length; i++) {
          if (circlesEntered[i] != i + 1) {
            isCorrectSequence = false;
            break;
          }
        }
        
        if (isCorrectSequence && circlesEntered.length == circlesGenerator.numberOfCircles && isContinuous) {
          feedbackMessage = 'Perfect! Continuous line through all circles!';
          testComplete = true;
        } else if (!isContinuous && circlesEntered.isNotEmpty) {
          feedbackMessage = 'You must draw a continuous line!';
        } else if (!isCorrectSequence) {
          // Wrong order
          int nextExpected = circlesEntered.length + 1;
          feedbackMessage = 'Next, touch circle $nextExpected';
        } else {
          // Correct sequence so far
          int nextExpected = circlesEntered.length + 1;
          feedbackMessage = 'Next, touch circle $nextExpected';
        }
      } else {
        feedbackMessage = 'Draw through circles in order: 1 → 2 → 3';
      }      
    });
  }

  /// Returns ALL circles touched in chronological order (including out-of-sequence)
  Set<int> _getAllTouchedCircles(List<Offset> points) {
    Set<int> touched = {};
    
    for (final point in points) {
      if (point.dx == -1) continue; // Skip stroke separators
      
      for (final circle in circlesGenerator.circles) {
        if ((point - circle.center).distance <= circle.radius) {
          touched.add(circle.number);
          break;
        }
      }
    }
    
    return touched;
  }

  /// Returns the sequence of circles entered in order, checking for continuity
  Map<String, dynamic> _getCircleSequenceFromPath(List<Offset> points) {
    List<int> sequence = [];
    int? currentCircle;
    int strokeCount = 0;

    // Record all circle entry events in chronological order
    final List<Map<String, int>> entries = [];

    for (int idx = 0; idx < points.length; idx++) {
      final point = points[idx];
      if (point.dx == -1) {
        currentCircle = null;
        strokeCount++;
        continue;
      }

      int? pointCircle;
      for (final circle in circlesGenerator.circles) {
        if ((point - circle.center).distance <= circle.radius) {
          pointCircle = circle.number;
          break;
        }
      }

      if (pointCircle != null && pointCircle != currentCircle) {
        currentCircle = pointCircle;
        entries.add({'num': pointCircle, 'idx': idx, 'stroke': strokeCount});
      }
    }

    // Helper: check points between indices for at least one point outside both circles and no stroke separator
    bool betweenHasOutsideNoLift(int start, int end, Circle a, Circle b) {
      if (start >= end) return false;
      for (int k = start; k <= end && k < points.length; k++) {
        final p = points[k];
        if (p.dx == -1) return false; // lift
        final outsideA = (p - a.center).distance > a.radius;
        final outsideB = (p - b.center).distance > b.radius;
        if (outsideA && outsideB) return true;
      }
      return false;
    }

    // Now attempt to match sequence 1..N using entry events.
    if (entries.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    // find an entry for circle 1
    final firstEntry1 = entries.firstWhere((e) => e['num'] == 1, orElse: () => {});
    if (firstEntry1.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    sequence.add(1);
    int prevMatchedIdx = firstEntry1['idx']!;

    for (int target = 2; target <= circlesGenerator.numberOfCircles; target++) {
      bool matched = false;

      // try each possible entry for (target-1) that occurs >= prevMatchedIdx
      for (int i = 0; i < entries.length; i++) {
        final ea = entries[i];
        if (ea['num'] != target - 1) continue;
        final idxA = ea['idx']!;
        if (idxA < prevMatchedIdx) continue;

        // find a later entry for target
        for (int j = i + 1; j < entries.length; j++) {
          final eb = entries[j];
          if (eb['num'] != target) continue;
          final idxB = eb['idx']!;
          final strokeA = ea['stroke']!;
          final strokeB = eb['stroke']!;
          if (strokeA != strokeB) continue; // require same stroke for this pair

          final circleA = circlesGenerator.circles.firstWhere((c) => c.number == target - 1);
          final circleB = circlesGenerator.circles.firstWhere((c) => c.number == target);

          if (betweenHasOutsideNoLift(idxA, idxB, circleA, circleB)) {
            // matched this pair
            sequence.add(target);
            prevMatchedIdx = idxB;
            matched = true;
            break;
          }
        }

        if (matched) break;
      }

      if (!matched) break;
    }

    // isContinuous true if full sequence matched (each pair continuous as checked)
    final isContinuous = sequence.length == circlesGenerator.numberOfCircles;

    return {'sequence': sequence, 'isContinuous': isContinuous};
  }

  void _clearDrawing() {
    setState(() {
      drawnPoints.clear();
      circlesEntered.clear();
      _lastFeedbackSequence.clear();
      _allTouchedCircles.clear();
      lastCorrectCircle = null;
      feedbackMessage = 'Draw through circles in order: 1 → 2 → 3';
      testComplete = false;
    });
    // Clear the drawn points in the child widget
    _clearDrawingCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Trail Making Test',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
              final height = (constraints.maxHeight.isFinite && constraints.maxHeight > 200)
                  ? constraints.maxHeight
                  : 400.0;

              if (circlesGenerator.circles.isEmpty) {
                circlesGenerator.generateCircles(width, height);
              }

              return DrawAreaWithCircles(
                onDrawingUpdated: onDrawingUpdated,
                onCircleEntered: onCircleEntered,
                setFeedbackCallback: (callback) {
                  _feedbackTrigger = callback;
                },
                setClearCallback: (callback) {
                  _clearDrawingCallback = callback;
                },
                circles: circlesGenerator.circles,
                drawnPoints: drawnPoints,
                width: width,
                height: height,
                circlesEntered: circlesEntered,
                testComplete: testComplete,
                lastCorrectCircle: lastCorrectCircle,
              );
            }),
            const SizedBox(height: 16),
            Text(
              feedbackMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: testComplete ? AppColors.grey900 : AppColors.grey800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _clearDrawing,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: testComplete
                      ? () {
                          widget.run.complete(
                            TestResult(
                              testId: 'tmt',
                              summary: {
                                'completed': testComplete,
                                'circlesOrder': circlesEntered,
                              },
                            ),
                          );
                        }
                      : null,
                  child: const Text('Finish'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => widget.run.abort('User aborted'),
              child: const Text('Abort'),
            ),
          ],
        ),
      ),
    );
  }
}

class Circle {
  final Offset center;
  final double radius;
  final int number;

  Circle({
    required this.center,
    required this.radius,
    required this.number,
  });

  bool contains(Offset point) {
    return (point - center).distance <= radius;
  }
}

class CirclesWithNumbers {
  final int numberOfCircles;
  List<Circle> circles = [];
  final Random random = Random();
  static const double circleRadius = 30.0; // Fixed circle size

  CirclesWithNumbers({required this.numberOfCircles});

  /// Generate circles positioned within [width] x [height]. Ensures circles do not
  /// overlap closer than [minDistance].
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
            number: circles.length + 1,
          ),
        );
      }
    }
  }
}

class DrawAreaWithCircles extends StatefulWidget {
  final Function(List<Offset>) onDrawingUpdated;
  final Function(int, bool)? onCircleEntered; // (circleNumber, isCorrect)
  final Function(Function(int, bool))? setFeedbackCallback; // Pass state callback to parent
  final Function(VoidCallback)? setClearCallback; // Pass clear callback to parent
  final List<Circle> circles;
  final List<Offset> drawnPoints;
  final double width;
  final double height;
  final List<int> circlesEntered; // Correctly entered circles
  final bool testComplete; // Whether test is complete
  final int? lastCorrectCircle; // Last correctly entered circle number

  const DrawAreaWithCircles({
    required this.onDrawingUpdated,
    this.onCircleEntered,
    this.setFeedbackCallback,
    this.setClearCallback,
    required this.circles,
    required this.drawnPoints,
    required this.width,
    required this.height,
    required this.circlesEntered,
    required this.testComplete,
    this.lastCorrectCircle,
  });

  @override
  State<DrawAreaWithCircles> createState() => _DrawAreaWithCirclesState();
}

class _DrawAreaWithCirclesState extends State<DrawAreaWithCircles>
    with TickerProviderStateMixin {
  late List<Offset> points;
  final Map<int, AnimationController> _feedbackControllers = {};
  final Map<int, bool> _feedbackType = {}; // true = correct, false = wrong
  final Set<int> _lastSeenCircles = {};
  bool isDrawingAllowed = false; // Lock: only allow drawing after touching correct circle
  late AnimationController _activePulseController; // Pulse animation for active circle

  @override
  void initState() {
    super.initState();
    points = [];
    // Pass the feedback trigger callback to parent
    widget.setFeedbackCallback?.call(_triggerFeedback);
    // Pass the clear callback to parent
    widget.setClearCallback?.call(_clearPoints);
    
    // Create continuous pulse animation for the active circle
    _activePulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _activePulseController.repeat(); // Loop continuously
  }

  @override
  void dispose() {
    for (final controller in _feedbackControllers.values) {
      controller.dispose();
    }
    _activePulseController.dispose();
    super.dispose();
  }

  void _triggerFeedback(int circleNumber, bool isCorrect) {
    late final AnimationController controller;
    
    // Create animation controller if it doesn't exist
    if (!_feedbackControllers.containsKey(circleNumber)) {
      controller = AnimationController(
        duration: Duration(milliseconds: isCorrect ? 200 : 175),
        vsync: this,
      );
      // Don't use setState listener - the CustomPaint.repaint parameter will handle efficient repainting
      _feedbackControllers[circleNumber] = controller;
    } else {
      controller = _feedbackControllers[circleNumber]!;
      // Only reset if not currently animating - this prevents interrupting active animations
      if (!controller.isAnimating) {
        controller.reset();
      } else {
        // If already animating, don't trigger again - let current animation complete
        return;
      }
    }
    
    _feedbackType[circleNumber] = isCorrect;
    
    // Trigger animation - forward then reverse
    controller.forward().then((_) {
      if (mounted && _feedbackControllers.containsKey(circleNumber)) {
        controller.reverse();
      }
    });
    
    // Trigger haptic feedback
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _checkForNewCircles() {
    // This will be called after parent widget's onDrawingUpdated
    // The parent will call onCircleEntered to trigger feedback here
  }

  void _clearPoints() {
    setState(() {
      points.clear();
      isDrawingAllowed = false;
      // Reset all animation controllers to their initial state
      for (final controller in _feedbackControllers.values) {
        controller.stop();
        controller.reset();
      }
      _feedbackControllers.clear();
      _feedbackType.clear();
      _lastSeenCircles.clear();
    });
  }

  /// Check if a point is within a specific circle
  bool _isPointInCircle(Offset point, int circleNumber) {
    Circle? circle;
    try {
      circle = widget.circles.firstWhere((c) => c.number == circleNumber);
    } catch (e) {
      return false;
    }
    return (point - circle.center).distance <= circle.radius;
  }

  /// Check if a point is within the canvas bounds
  bool _isPointInBounds(Offset point) {
    return point.dx >= 0 && 
           point.dx <= widget.width && 
           point.dy >= 0 && 
           point.dy <= widget.height;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.testComplete ? null : (details) {
        setState(() {
          final startPoint = details.localPosition;
          
          // Determine which circle the user needs to touch to enable drawing
          int requiredCircle;
          if (widget.circlesEntered.isEmpty) {
            // No circles entered yet, user must start at circle 1
            requiredCircle = 1;
          } else {
            // User must restart from the last correct circle they reached
            requiredCircle = widget.lastCorrectCircle ?? widget.circlesEntered.last;
          }
          
          // Check if the touch is in the required circle
          if (_isPointInCircle(startPoint, requiredCircle)) {
            // Correct! Enable drawing and add the starting point
            isDrawingAllowed = true;
            _activePulseController.stop(); // Stop pulsing when drawing starts
            points.add(startPoint);
            widget.onDrawingUpdated(points);
            _checkForNewCircles();
          } else {
            // Wrong circle! Provide haptic feedback
            HapticFeedback.heavyImpact();
            // Don't enable drawing, don't add any points
          }
        });
      },
      onPanUpdate: widget.testComplete ? null : (details) {
        setState(() {
          // Only allow drawing if they started in the correct circle and point is within bounds
          if (isDrawingAllowed && _isPointInBounds(details.localPosition)) {
            points.add(details.localPosition);
            widget.onDrawingUpdated(points);
            _checkForNewCircles();
          }
        });
      },
      onPanEnd: (_) {
        setState(() {
          // Disable drawing until they touch the correct circle again
          isDrawingAllowed = false;
          // Add stroke separator to indicate a lift
          points.add(Offset(-1, -1));
          // Resume pulsing animation when finger is lifted
          if (!_activePulseController.isAnimating) {
            _activePulseController.repeat();
          }
        });
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300, width: 2),
          color: AppColors.grey100,
        ),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _activePulseController,
              ..._feedbackControllers.values,
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: DrawAreaPainter(
                  points: points,
                  circles: widget.circles,
                  feedbackControllers: _feedbackControllers,
                  feedbackType: _feedbackType,
                  circlesEntered: widget.circlesEntered,
                  activePulseController: _activePulseController,
                  requiredCircle: widget.circlesEntered.isEmpty 
                      ? 1 
                      : (widget.lastCorrectCircle ?? widget.circlesEntered.last),
                  testComplete: widget.testComplete,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

class DrawAreaPainter extends CustomPainter {
  final List<Offset> points;
  final List<Circle> circles;
  final Map<int, AnimationController> feedbackControllers;
  final Map<int, bool> feedbackType; // true = correct, false = wrong
  final List<int> circlesEntered;
  final AnimationController? activePulseController; // Pulse animation for active circle
  final int requiredCircle; // The circle number the user must touch
  final bool testComplete; // Whether test is complete

  DrawAreaPainter({
    required this.points,
    required this.circles,
    this.feedbackControllers = const {},
    this.feedbackType = const {},
    this.circlesEntered = const [],
    this.activePulseController,
    this.requiredCircle = 1,
    this.testComplete = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw circles
    for (final circle in circles) {
      // Check if this circle has been correctly entered
      bool isEntered = circlesEntered.contains(circle.number);
      
      // Check if this circle has active feedback animation
      double scale = 1.0;
      Color circleColor = isEntered 
          ? AppColors.grey900.withValues(alpha: 0.2)  // Nearly transparent for entered circles
          : AppColors.grey900.withValues(alpha: 0.7);

      if (feedbackControllers.containsKey(circle.number)) {
        final controller = feedbackControllers[circle.number]!;
        if (controller.isAnimating) {
          final isCorrect = feedbackType[circle.number] ?? true;
          
          if (isCorrect) {
            // Correct: scale up and brighten
            scale = 1.0 + (controller.value * 0.1);
            circleColor = AppColors.grey700.withValues(alpha: 0.8);
          } else {
            // Wrong: shrink and darken/tint red
            scale = 1.0 - (controller.value * 0.1);
            // Blend towards a reddish tint for wrong feedback
            circleColor = Color.lerp(
              AppColors.grey900.withValues(alpha: 0.7),
              const Color.fromARGB(230, 204, 0, 0),
              controller.value * 0.6,
            )!;
          }
        }
      }

      final scaledRadius = circle.radius * scale;

      // Apply pulse effect if this is the required circle and test is not complete
      if (circle.number == requiredCircle && !testComplete && activePulseController != null && activePulseController!.isAnimating) {
        // Create pulsing border/glow effect
        final pulseValue = activePulseController!.value;
        
        // Pulsing border - grows and shrinks
        final borderWidth = 2.0 + (pulseValue * 3.0);
        final borderPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.8 - (pulseValue * 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(circle.center, scaledRadius + (pulseValue * 8.0), borderPaint);
        
        // Pulsing color tint - brighten and dim
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

      // Number text (scale with circle)
      final textPainter = TextPainter(
        text: TextSpan(
          text: circle.number.toString(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Center text on scaled circle
      final textOffset = circle.center - 
          Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }

    // Draw the user's drawing
    final paint = Paint()
      ..color = AppColors.grey900
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx != -1 && points[i + 1].dx != -1) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawAreaPainter oldDelegate) {
    // Repaint if pulse controller value changed or any other property changed
    if (activePulseController != null && oldDelegate.activePulseController != null) {
      if (activePulseController!.value != oldDelegate.activePulseController!.value) {
        return true;
      }
    }
    return true;
  }
}