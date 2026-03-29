import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/circles_painter.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';

/// Tutorial screen for Trail Making Test (TMT)
/// Uses 3 circles instead of 6 and provides detailed instructions
class TMTTutorial extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;
  final CircleMode mode;
  const TMTTutorial({
    super.key,
    required this.onComplete,
    this.onAbort,
    this.mode = CircleMode.numbersOnly,
  });

  @override
  ConsumerState<TMTTutorial> createState() => _TMTTutorialState();
}

class _TMTTutorialState extends ConsumerState<TMTTutorial> with TickerProviderStateMixin {
  late CirclesWithNumbers circlesGenerator;
  List<Offset> drawnPoints = [];
  List<String> circlesEntered = [];
  List<String> _lastFeedbackSequence = [];
  Set<String> _allTouchedCircles = {};
  bool tutorialComplete = false;
  bool _firstConnectionMade = false;
  Function(String, bool)? _feedbackTrigger;
  VoidCallback? _clearDrawingCallback;
  String? lastCorrectCircle;
  late AnimationController _fingerAnimationController;

  @override
  void initState() {
    super.initState();
    circlesGenerator = CirclesWithNumbers(
      numberOfCircles: 4,
      mode: widget.mode,
    );
    _fingerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    // Animate with a pause between loops
    _animateWithPause();
  }

  void _animateWithPause() {
    _fingerAnimationController.forward().then((_) {
      if (mounted && !_firstConnectionMade) {
        // Add 500ms pause after animation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_firstConnectionMade) {
            _fingerAnimationController.reset();
            _animateWithPause();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fingerAnimationController.dispose();
    super.dispose();
  }

  void onCircleEntered(String circleLabel, bool isCorrect) {
    _feedbackTrigger?.call(circleLabel, isCorrect);
  }

  void onDrawingUpdated(List<Offset> points) {
    setState(() {
      drawnPoints = points;
      var result = _getCircleSequenceFromPath(points);
      List<String> newSequence = result['sequence'] as List<String>;
      bool isContinuous = result['isContinuous'] as bool;

      Set<String> allTouched = _getAllTouchedCircles(points);

      for (int i = _lastFeedbackSequence.length; i < newSequence.length; i++) {
        final circleLabel = newSequence[i];
        onCircleEntered(circleLabel, true);
      }

      for (String circleLabel in allTouched) {
        if (!_allTouchedCircles.contains(circleLabel)) {
          if (!newSequence.contains(circleLabel)) {
            onCircleEntered(circleLabel, false);
          }
        }
      }

      _lastFeedbackSequence = newSequence;
      _allTouchedCircles = allTouched;
      circlesEntered = newSequence;

      if (circlesEntered.isNotEmpty) {
        lastCorrectCircle = circlesEntered.last;
      }

      // Stop animation once user has successfully connected circles 1 and 2
      if (circlesEntered.length >= 2 && !_firstConnectionMade) {
        _firstConnectionMade = true;
        _fingerAnimationController.stop();
      }

      if (circlesEntered.isNotEmpty) {
        bool isCorrectSequence = _isCorrectSequence(circlesEntered);

        if (isCorrectSequence && circlesEntered.length == 4 && isContinuous) {
          tutorialComplete = true;
        }
      }
    });
  }


  String _getExpectedLabel(int index) {
    // Index is 0-based
    if (widget.mode == CircleMode.numbersOnly) {
      return (index + 1).toString();
    } else {
      // Mixed mode: 1, A, 2, B, 3, C
      if (index.isEven) {
        return ((index ~/ 2) + 1).toString();
      } else {
        return String.fromCharCode(65 + (index ~/ 2));
      }
    }
  }

  bool _isCorrectSequence(List<String> sequence) {
    for (int i = 0; i < sequence.length; i++) {
      if (sequence[i] != _getExpectedLabel(i)) {
        return false;
      }
    }
    return true;
  }

  Set<String> _getAllTouchedCircles(List<Offset> points) {
    Set<String> touched = {};

    for (final point in points) {
      if (point.dx == -1) continue;

      for (final circle in circlesGenerator.circles) {
        if ((point - circle.center).distance <= circle.radius) {
          touched.add(circle.label);
          break;
        }
      }
    }

    return touched;
  }

  Map<String, dynamic> _getCircleSequenceFromPath(List<Offset> points) {
    List<String> sequence = [];
    String? currentCircle;
    int strokeCount = 0;

    final List<Map<String, dynamic>> entries = [];

    for (int idx = 0; idx < points.length; idx++) {
      final point = points[idx];
      if (point.dx == -1) {
        currentCircle = null;
        strokeCount++;
        continue;
      }

      String? pointCircle;
      for (final circle in circlesGenerator.circles) {
        if ((point - circle.center).distance <= circle.radius) {
          pointCircle = circle.label;
          break;
        }
      }

      if (pointCircle != null && pointCircle != currentCircle) {
        currentCircle = pointCircle;
        entries.add({'label': pointCircle, 'idx': idx, 'stroke': strokeCount});
      }
    }

    bool betweenHasOutsideNoLift(int start, int end, Circle a, Circle b) {
      if (start >= end) return false;
      for (int k = start; k <= end && k < points.length; k++) {
        final p = points[k];
        if (p.dx == -1) return false;
        final outsideA = (p - a.center).distance > a.radius;
        final outsideB = (p - b.center).distance > b.radius;
        if (outsideA && outsideB) return true;
      }
      return false;
    }

    if (entries.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    final firstLabel = circlesGenerator.circles[0].label;
    final firstEntry = entries.firstWhere((e) => e['label'] == firstLabel, orElse: () => {});
    if (firstEntry.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    sequence.add(firstLabel);
    int prevMatchedIdx = firstEntry['idx']!;

    for (int targetIdx = 1; targetIdx < circlesGenerator.circles.length; targetIdx++) {
      final targetLabel = circlesGenerator.circles[targetIdx].label;
      final prevLabel = circlesGenerator.circles[targetIdx - 1].label;
      bool matched = false;

      for (int i = 0; i < entries.length; i++) {
        final ea = entries[i];
        if (ea['label'] != prevLabel) continue;
        final idxA = ea['idx']!;
        if (idxA < prevMatchedIdx) continue;

        for (int j = i + 1; j < entries.length; j++) {
          final eb = entries[j];
          if (eb['label'] != targetLabel) continue;
          final idxB = eb['idx']!;
          final strokeA = ea['stroke']!;
          final strokeB = eb['stroke']!;
          if (strokeA != strokeB) continue;

          final circleA = circlesGenerator.circles[targetIdx - 1];
          final circleB = circlesGenerator.circles[targetIdx];

          if (betweenHasOutsideNoLift(idxA, idxB, circleA, circleB)) {
            sequence.add(targetLabel);
            prevMatchedIdx = idxB;
            matched = true;
            break;
          }
        }

        if (matched) break;
      }

      if (!matched) break;
    }

    final isContinuous = sequence.length == circlesGenerator.circles.length;

    return {'sequence': sequence, 'isContinuous': isContinuous};
  }

  void _clearDrawing() {
    setState(() {
      drawnPoints.clear();
      circlesEntered.clear();
      _lastFeedbackSequence.clear();
      _allTouchedCircles.clear();
      lastCorrectCircle = null;
      tutorialComplete = false;
      _firstConnectionMade = false;
    });
    _clearDrawingCallback?.call();
    // Restart animation when drawing is cleared
    _fingerAnimationController.reset();
    _animateWithPause();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return TestShell(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
                final height = (constraints.maxHeight.isFinite && constraints.maxHeight > 200)
                    ? constraints.maxHeight
                    : 300.0;

              if (circlesGenerator.circles.isEmpty) {
                circlesGenerator.generateFixedCircles4Tutorial(width, height);
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
                  testComplete: tutorialComplete,
                  lastCorrectCircle: lastCorrectCircle,
                  fingerAnimationController: _fingerAnimationController,
                );
              }),
            ),
          ),
          BottomButtonBar(
            actionButtons: [
              BottomButton(
                label: strings.retry,
                onPressed: _clearDrawing,
                type: BottomButtonType.outlined,
                icon: Icons.refresh,
              ),
              BottomButton(
                label: strings.done,
                onPressed: tutorialComplete ? widget.onComplete : () {},
                enabled: tutorialComplete,
                type: BottomButtonType.filled,
                icon: Icons.check_circle,
              ),
            ],
            colorSet: tutorialComplete 
              ? BottomBarColorSet.secondary 
              : BottomBarColorSet.primary,
            onAbort: widget.onAbort,
            useRow: true,
          ),
        ],
      ),
    );
  }
}

class DrawAreaWithCircles extends StatefulWidget {
  final Function(List<Offset>) onDrawingUpdated;
  final Function(String, bool)? onCircleEntered;
  final Function(Function(String, bool))? setFeedbackCallback;
  final Function(VoidCallback)? setClearCallback;
  final List<Circle> circles;
  final List<Offset> drawnPoints;
  final double width;
  final double height;
  final List<String> circlesEntered;
  final bool testComplete;
  final String? lastCorrectCircle;
  final AnimationController? fingerAnimationController;

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
    this.fingerAnimationController,
  });

  @override
  State<DrawAreaWithCircles> createState() => _DrawAreaWithCirclesState();
}

class _DrawAreaWithCirclesState extends State<DrawAreaWithCircles> with TickerProviderStateMixin {
  late List<Offset> points;
  final Map<String, AnimationController> _feedbackControllers = {};
  final Map<String, bool> _feedbackType = {};
  final Set<String> _lastSeenCircles = {};
  bool isDrawingAllowed = false;
  late AnimationController _activePulseController;

  @override
  void initState() {
    super.initState();
    points = [];
    widget.setFeedbackCallback?.call(_triggerFeedback);
    widget.setClearCallback?.call(_clearPoints);

    _activePulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _activePulseController.repeat();
  }

  @override
  void dispose() {
    for (final controller in _feedbackControllers.values) {
      controller.dispose();
    }
    _activePulseController.dispose();
    super.dispose();
  }

  /// Calculate which point indices are part of correct line segments
  /// A checkpoint is from when user starts drawing to either:
  /// - Correct sequence continuation: 100% alpha (black)
  /// - Wrong or out-of-order circles: light grey
  Set<int> _getCorrectLineSegmentIndices() {
    Set<int> correctIndices = {};
    
    if (points.isEmpty) {
      return correctIndices;
    }

    // Current line being drawn - only mark as correct if it's touching circles or making progress
    int currentCheckpointStart = 0;
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].dx == -1) {
        currentCheckpointStart = i + 1;
        break;
      }
    }
    
    // Check if current line touches any circles
    bool currentLineTouchesCircles = false;
    if (currentCheckpointStart < points.length) {
      for (int i = currentCheckpointStart; i < points.length; i++) {
        final point = points[i];
        for (final circle in widget.circles) {
          if ((point - circle.center).distance <= circle.radius) {
            currentLineTouchesCircles = true;
            break;
          }
        }
        if (currentLineTouchesCircles) break;
      }
    }
    
    // Only mark current line as correct if it's touching circles (visual feedback while drawing within valid range)
    if (currentLineTouchesCircles && currentCheckpointStart < points.length) {
      for (int i = currentCheckpointStart; i < points.length; i++) {
        correctIndices.add(i);
      }
    }

    // For completed checkpoints (those that ended with a lift)
    List<List<int>> completedCheckpoints = [];
    List<int> currentCheckpoint = [];
    
    for (int i = 0; i < points.length; i++) {
      if (points[i].dx == -1) {
        if (currentCheckpoint.isNotEmpty) {
          completedCheckpoints.add(currentCheckpoint);
          currentCheckpoint = [];
        }
      } else {
        currentCheckpoint.add(i);
      }
    }
    
    // Evaluate each completed checkpoint sequentially
    // Build up the sequence as we evaluate, not using the final circlesEntered
    List<String> simulatedSequence = [];
    
    for (int checkpointIdx = 0; checkpointIdx < completedCheckpoints.length; checkpointIdx++) {
      final checkpoint = completedCheckpoints[checkpointIdx];
      if (checkpoint.isEmpty) continue;
      
      // Get the sequence of circles touched in this checkpoint (in order)
      List<String> touchedCircles = [];
      String? lastTouchedCircle;
      
      for (final idx in checkpoint) {
        final point = points[idx];
        
        for (final circle in widget.circles) {
          final distance = (point - circle.center).distance;
          
          if (distance <= circle.radius) {
            // Only add if different from the last touched circle
            if (circle.label != lastTouchedCircle) {
              touchedCircles.add(circle.label);
              lastTouchedCircle = circle.label;
            }
            break;
          }
        }
      }
      
      // Check if this checkpoint starts right after a lift (look back to see if there's a -1 marker before this checkpoint)
      bool startsAfterLift = false;
      if (checkpoint.isNotEmpty && checkpoint[0] > 0) {
        // Check if there's a -1 marker immediately before this checkpoint
        if (points[checkpoint[0] - 1].dx == -1) {
          startsAfterLift = true;
        }
      }
      
      // Check if this checkpoint is a valid next step
      bool isCheckpointCorrect = false;
      
      if (touchedCircles.isNotEmpty) {
        // Determine where the checkpoint should start
        String expectedStart = simulatedSequence.isEmpty 
            ? widget.circles[0].label  // First checkpoint starts at circle[0]
            : simulatedSequence.last;  // Subsequent checkpoints start where we left off
        
        // Check if checkpoint starts correctly
        if (touchedCircles[0] == expectedStart) {
          // It starts correctly, now check if it continues in sequence
          isCheckpointCorrect = true;
          int sequenceStartIndex = simulatedSequence.length;
          
          // If the first circle in touchedCircles is already in the sequence, skip it
          int touchedStartOffset = 0;
          if (simulatedSequence.isNotEmpty && touchedCircles[0] == simulatedSequence.last) {
            touchedStartOffset = 1; // Skip the overlap point
          }
          
          // Check if checkpoint made any progress (touched new circles beyond the start)
          if (touchedStartOffset >= touchedCircles.length) {
            // Only touched circles already in sequence, no progress made
            // This is OK if: 
            // 1. Checkpoint is very short (auto-split re-entry), OR
            // 2. It's a valid re-entry to the same circle without a real lift
            bool isVeryShortCheckpoint = checkpoint.length <= 5;
            isCheckpointCorrect = touchedCircles.isNotEmpty && !simulatedSequence.isEmpty && touchedCircles[0] == expectedStart && (isVeryShortCheckpoint || !startsAfterLift);
          } else {
            // Only validate that the line ENDS at the next expected circle
            // Allow crossing other circles in between
            int nextExpectedIndex = sequenceStartIndex + 1;
            
            // Check if within bounds
            if (nextExpectedIndex >= widget.circles.length) {
              isCheckpointCorrect = false;
            } else {
              String nextExpectedCircle = widget.circles[nextExpectedIndex].label;
              String lastTouchedCircle = touchedCircles.last;
              
              if (lastTouchedCircle == nextExpectedCircle) {
                // Line ends correctly! Add this circle to the sequence
                isCheckpointCorrect = true;
                simulatedSequence.add(nextExpectedCircle);
              } else {
                // Line ended at wrong circle
                isCheckpointCorrect = false;
              }
            }
          }
        }
      }
      
      // Mark entire checkpoint if it's correct
      if (isCheckpointCorrect) {
        for (final idx in checkpoint) {
          correctIndices.add(idx);
        }
      }
    }
    
    return correctIndices;
  }

  void _triggerFeedback(String circleLabel, bool isCorrect) {
    late final AnimationController controller;

    if (!_feedbackControllers.containsKey(circleLabel)) {
      controller = AnimationController(
        duration: Duration(milliseconds: isCorrect ? 200 : 175),
        vsync: this,
      );
      _feedbackControllers[circleLabel] = controller;
    } else {
      controller = _feedbackControllers[circleLabel]!;
      if (!controller.isAnimating) {
        controller.reset();
      } else {
        return;
      }
    }

    _feedbackType[circleLabel] = isCorrect;

    controller.forward().then((_) {
      if (mounted && _feedbackControllers.containsKey(circleLabel)) {
        controller.reverse();
      }
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _clearPoints() {
    setState(() {
      points.clear();
      isDrawingAllowed = false;
      for (final controller in _feedbackControllers.values) {
        controller.stop();
        controller.reset();
      }
      _feedbackControllers.clear();
      _feedbackType.clear();
      _lastSeenCircles.clear();
    });
  }

  bool _isPointInCircle(Offset point, String circleLabel) {
    Circle? circle;
    try {
      circle = widget.circles.firstWhere((c) => c.label == circleLabel);
    } catch (e) {
      return false;
    }
    return (point - circle.center).distance <= circle.radius;
  }

  bool _isPointInBounds(Offset point) {
    return point.dx >= 0 && point.dx <= widget.width && point.dy >= 0 && point.dy <= widget.height;
  }

  /// Get the circle that a point is in, if any
  Circle? _getPointCircle(Offset point) {
    for (final circle in widget.circles) {
      if ((point - circle.center).distance <= circle.radius) {
        return circle;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.testComplete
          ? null
          : (details) {
              setState(() {
                final startPoint = details.localPosition;

                String requiredCircle;
                if (widget.circlesEntered.isEmpty) {
                  requiredCircle = '1';
                } else {
                  requiredCircle = widget.lastCorrectCircle ?? widget.circlesEntered.last;
                }

                if (_isPointInCircle(startPoint, requiredCircle)) {
                  isDrawingAllowed = true;
                  _activePulseController.stop();
                  points.add(startPoint);
                  widget.onDrawingUpdated(points);
                } else {
                  HapticFeedback.heavyImpact();
                }
              });
            },
      onPanUpdate: widget.testComplete
          ? null
          : (details) {
              setState(() {
                // Only allow drawing if they started in the correct circle and point is within bounds
                if (isDrawingAllowed && _isPointInBounds(details.localPosition)) {
                  points.add(details.localPosition);
                  
                  // Check if we just entered a new circle
                  Circle? currentCircle = _getPointCircle(details.localPosition);
                  if (currentCircle != null && !_lastSeenCircles.contains(currentCircle.label)) {
                    // Entered a new circle for the first time in this stroke
                    _lastSeenCircles.add(currentCircle.label);
                    
                    // Check if this circle is the next expected one
                    // Current circlesEntered has length N, so next expected is at index N
                    int nextExpectedIndex = widget.circlesEntered.length;
                    
                    if (nextExpectedIndex < widget.circles.length &&
                        currentCircle.label == widget.circles[nextExpectedIndex].label) {
                      // Correct circle! Auto-split: add lift marker and immediately start new stroke
                      points.add(Offset(-1, -1)); // End current stroke
                      points.add(details.localPosition); // Start new stroke from this circle
                      _lastSeenCircles.clear(); // Reset for next stroke
                    }
                  }
                  
                  widget.onDrawingUpdated(points);
                }
              });
            },
      onPanEnd: (_) {
        setState(() {
          isDrawingAllowed = false;
          points.add(Offset(-1, -1));
          _lastSeenCircles.clear(); // Reset circle tracking for next stroke
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
              if (widget.fingerAnimationController != null) widget.fingerAnimationController!,
            ]),
            builder: (context, child) {
              final correctLineSegments = _getCorrectLineSegmentIndices();
              
              return CustomPaint(
                painter: DrawAreaPainter(
                  points: points,
                  circles: widget.circles,
                  feedbackControllers: _feedbackControllers,
                  feedbackType: _feedbackType,
                  circlesEntered: widget.circlesEntered,
                  activePulseController: _activePulseController,
                  fingerAnimationController: widget.fingerAnimationController,
                  requiredCircle: widget.circlesEntered.isEmpty
                      ? '1'
                      : (widget.lastCorrectCircle ?? widget.circlesEntered.last),
                  testComplete: widget.testComplete,
                  correctLineSegments: correctLineSegments,
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
