import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/circles_painter.dart';
import 'package:flutter_master_app/tutorials/tmt_tutorial.dart';

final tmtTest = TestDefinition(
  id: 'TMT',
  title: 'Trail Making Test',
  icon: Icons.draw,
  build: (context, run) => TMTTestFlowProgression(run: run),
);

/// Manages the progression: Numbers Tutorial → Numbers Test → Mixed Tutorial → Mixed Test
class TMTTestFlowProgression extends StatefulWidget {
  final TestRunContext run;
  const TMTTestFlowProgression({super.key, required this.run});

  @override
  State<TMTTestFlowProgression> createState() => _TMTTestFlowProgressionState();
}

class _TMTTestFlowProgressionState extends State<TMTTestFlowProgression> {
  int stage = 0; // 0: Numbers tut, 1: Numbers test, 2: Mixed tut, 3: Mixed test
  final Map<String, dynamic> stageResults = {}; // Store results from each stage

  void _saveTestResult(
      String stageName, List<String> circlesEntered, bool completed) {
    stageResults[stageName] = {
      'completed': completed,
      'circlesOrder': circlesEntered,
    };
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case 0:
        return TMTTutorial(
          mode: CircleMode.numbersOnly,
          onComplete: () {
            setState(() => stage = 1);
          },
          onAbort: () => widget.run.abort('User aborted'),
        );
      case 1:
        return TMTTest(
          run: widget.run,
          mode: CircleMode.numbersOnly,
          stageName: 'numbers_test',
          onTestResult: (circlesEntered, completed) {
            _saveTestResult('numbers_test', circlesEntered, completed);
          },
          onNextStage: () {
            setState(() => stage = 2);
          },
        );
      case 2:
        return TMTTutorial(
          mode: CircleMode.mixed,
          onComplete: () {
            setState(() => stage = 3);
          },
          onAbort: () => widget.run.abort('User aborted'),
        );
      case 3:
        return TMTTest(
          run: widget.run,
          mode: CircleMode.mixed,
          stageName: 'mixed_test',
          onTestResult: (circlesEntered, completed) {
            _saveTestResult('mixed_test', circlesEntered, completed);
          },
          onCompletion: (circlesEntered, completed) {
            // Final test complete - save its results and complete the entire progression
            _saveTestResult('mixed_test', circlesEntered, completed);
            
            // Complete with combined results from all stages
            widget.run.complete(
              TestResult(
                testId: 'tmt',
                summary: {
                  'progression_completed': true,
                  'all_stages': stageResults,
                  'final_mode': 'mixed',
                },
              ),
            );
          },
        );
      default:
        return const SizedBox();
    }
  }
}

/// Manages single tutorial to test flow
class TMTTestFlow extends StatefulWidget {
  final TestRunContext run;
  const TMTTestFlow({super.key, required this.run});

  @override
  State<TMTTestFlow> createState() => _TMTTestFlowState();
}

class _TMTTestFlowState extends State<TMTTestFlow> {
  bool tutorialComplete = false;

  @override
  Widget build(BuildContext context) {
    if (!tutorialComplete) {
      return TMTTutorial(
        mode: CircleMode.numbersOnly,
        onComplete: () {
          setState(() {
            tutorialComplete = true;
          });
        },
        onAbort: () => widget.run.abort('User aborted'),
      );
    }

    return TMTTest(run: widget.run, mode: CircleMode.numbersOnly);
  }
}

class TMTTest extends StatefulWidget {
  final TestRunContext run;
  final CircleMode mode;
  final String stageName;
  final Function(List<String>, bool)? onTestResult; // Report results to parent
  final VoidCallback? onNextStage; // Callback to move to next stage
  final Function(List<String>, bool)? onCompletion; // Called when final test is done
  const TMTTest({
    super.key,
    required this.run,
    this.mode = CircleMode.numbersOnly,
    this.stageName = 'tmt_test',
    this.onTestResult,
    this.onNextStage,
    this.onCompletion,
  });

  @override
  State<TMTTest> createState() => _TMTTest();
}

class _TMTTest extends State<TMTTest> {
  late CirclesWithNumbers circlesGenerator;
  List<Offset> drawnPoints = [];
  List<String> circlesEntered = [];
  List<String> _lastFeedbackSequence = [];
  Set<String> _allTouchedCircles = {};
  bool testComplete = false;
  Function(String, bool)? _feedbackTrigger;
  VoidCallback? _clearDrawingCallback;
  String? lastCorrectCircle;

  @override
  void initState() {
    super.initState();
    circlesGenerator = CirclesWithNumbers(
      numberOfCircles: 24,
      mode: widget.mode,
    );
  }

  void onCircleEntered(String circleLabel, bool isCorrect) {
    // This is called when parent detects a new circle
    // Trigger feedback in the child widget
    _feedbackTrigger?.call(circleLabel, isCorrect);
  }

  void onDrawingUpdated(List<Offset> points) {
    setState(() {
      drawnPoints = points;
      var result = _getCircleSequenceFromPath(points);
      List<String> newSequence = result['sequence'] as List<String>;
      bool isContinuous = result['isContinuous'] as bool;
      
      // Also detect ALL touched circles (including out-of-sequence ones) for wrong feedback
      Set<String> allTouched = _getAllTouchedCircles(points);
      
      // Trigger feedback for NEW circles in the valid sequence
      for (int i = _lastFeedbackSequence.length; i < newSequence.length; i++) {
        final circleLabel = newSequence[i];
        final isCorrect = true; // These are from the valid sequence, so always correct
        onCircleEntered(circleLabel, isCorrect);
      }
      
      // Trigger feedback for NEW circles touched (but not in valid sequence) = WRONG/out-of-order
      for (String circleLabel in allTouched) {
        if (!_allTouchedCircles.contains(circleLabel)) {
          // This circle was just touched
          // Check if it's part of the valid sequence
          if (!newSequence.contains(circleLabel)) {
            // Not in valid sequence = WRONG circle
            onCircleEntered(circleLabel, false);
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
        bool isCorrectSequence = _isCorrectSequence(circlesEntered);
        
        if (isCorrectSequence && circlesEntered.length == circlesGenerator.numberOfCircles && isContinuous) {
          testComplete = true;
        }
      }      
    });
  }


  String _getExpectedLabel(int index) {
    // Index is 0-based, so 0 = first label, 1 = second label, etc
    if (widget.mode == CircleMode.numbersOnly) {
      return (index + 1).toString();
    } else {
      // Mixed mode: 1, A, 2, B, 3, C, 4, D, etc
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

  /// Returns ALL circles touched in chronological order (including out-of-sequence)
  Set<String> _getAllTouchedCircles(List<Offset> points) {
    Set<String> touched = {};
    
    for (final point in points) {
      if (point.dx == -1) continue; // Skip stroke separators
      
      for (final circle in circlesGenerator.circles) {
        if ((point - circle.center).distance <= circle.radius) {
          touched.add(circle.label);
          break;
        }
      }
    }
    
    return touched;
  }

  /// Returns the sequence of circles entered in order, checking for continuity
  Map<String, dynamic> _getCircleSequenceFromPath(List<Offset> points) {
    List<String> sequence = [];
    String? currentCircle;
    int strokeCount = 0;

    // Record all circle entry events in chronological order
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

    // Now attempt to match sequence using entry events
    if (entries.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    // Find an entry for the first circle
    final firstLabel = circlesGenerator.circles[0].label;
    final firstEntry = entries.firstWhere((e) => e['label'] == firstLabel, orElse: () => {});
    if (firstEntry.isEmpty) return {'sequence': sequence, 'isContinuous': false};

    sequence.add(firstLabel);
    int prevMatchedIdx = firstEntry['idx']!;

    for (int targetIdx = 1; targetIdx < circlesGenerator.circles.length; targetIdx++) {
      final targetLabel = circlesGenerator.circles[targetIdx].label;
      final prevLabel = circlesGenerator.circles[targetIdx - 1].label;
      bool matched = false;

      // try each possible entry for (targetIdx-1) that occurs >= prevMatchedIdx
      for (int i = 0; i < entries.length; i++) {
        final ea = entries[i];
        if (ea['label'] != prevLabel) continue;
        final idxA = ea['idx']!;
        if (idxA < prevMatchedIdx) continue;

        // find a later entry for target
        for (int j = i + 1; j < entries.length; j++) {
          final eb = entries[j];
          if (eb['label'] != targetLabel) continue;
          final idxB = eb['idx']!;
          final strokeA = ea['stroke']!;
          final strokeB = eb['stroke']!;
          if (strokeA != strokeB) continue; // require same stroke for this pair

          final circleA = circlesGenerator.circles[targetIdx - 1];
          final circleB = circlesGenerator.circles[targetIdx];

          if (betweenHasOutsideNoLift(idxA, idxB, circleA, circleB)) {
            // matched this pair
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

    // isContinuous true if full sequence matched (each pair continuous as checked)
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
      testComplete = false;
    });
    // Clear the drawn points in the child widget
    _clearDrawingCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Trail Making Test',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, constraints) {
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                              // Report results to parent progression
                              widget.onTestResult?.call(circlesEntered, testComplete);

                              if (widget.onNextStage != null) {
                                // Move to next stage in progression
                                widget.onNextStage!();
                              } else {
                                // Final test, notify parent to handle completion
                                widget.onCompletion?.call(circlesEntered, testComplete);
                              }
                            }
                          : null,
                      child: const Text('Finish'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => widget.run.abort('User aborted'),
                  child: const Text('Abort'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawAreaWithCircles extends StatefulWidget {
  final Function(List<Offset>) onDrawingUpdated;
  final Function(String, bool)? onCircleEntered; // (circleLabel, isCorrect)
  final Function(Function(String, bool))? setFeedbackCallback; // Pass state callback to parent
  final Function(VoidCallback)? setClearCallback; // Pass clear callback to parent
  final List<Circle> circles;
  final List<Offset> drawnPoints;
  final double width;
  final double height;
  final List<String> circlesEntered; // Correctly entered circles
  final bool testComplete; // Whether test is complete
  final String? lastCorrectCircle; // Last correctly entered circle label

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
  final Map<String, AnimationController> _feedbackControllers = {};
  final Map<String, bool> _feedbackType = {}; // true = correct, false = wrong
  final Set<String> _lastSeenCircles = {};
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

  /// Calculate which point indices are part of correct line segments
  /// A checkpoint is from when user starts drawing to either:
  /// - Correct sequence continuation: 100% alpha (black)
  /// Returns indices of points that form correct line segments
  /// - Black (correct): Lines that start at correct circle and end at next expected circle
  /// - Grey (incorrect): All other lines
  Set<int> _getCorrectLineSegmentIndices() {
    Set<int> correctIndices = {};
    
    if (points.isEmpty) {
      return correctIndices;
    }

    // Current line being drawn - keep it all black
    int currentCheckpointStart = 0;
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].dx == -1) {
        currentCheckpointStart = i + 1;
        break;
      }
    }
    
    if (currentCheckpointStart < points.length) {
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
    
    for (final checkpoint in completedCheckpoints) {
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
            isCheckpointCorrect = false;
          } else {
            // Only validate that the line ENDS at the next expected circle
            // Allow crossing other circles in between
            int nextExpectedIndex = sequenceStartIndex + 1;
            
            // Check if within bounds
            if (nextExpectedIndex >= widget.circles.length) {
              isCheckpointCorrect = false;
            } else {
              String nextExpectedCircle = widget.circles[nextExpectedIndex].label;
              String lastTouchedInCheckpoint = touchedCircles.last;
              
              if (lastTouchedInCheckpoint == nextExpectedCircle) {
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
    
    // Create animation controller if it doesn't exist
    if (!_feedbackControllers.containsKey(circleLabel)) {
      controller = AnimationController(
        duration: Duration(milliseconds: isCorrect ? 200 : 175),
        vsync: this,
      );
      // Don't use setState listener - the CustomPaint.repaint parameter will handle efficient repainting
      _feedbackControllers[circleLabel] = controller;
    } else {
      controller = _feedbackControllers[circleLabel]!;
      // Only reset if not currently animating - this prevents interrupting active animations
      if (!controller.isAnimating) {
        controller.reset();
      } else {
        // If already animating, don't trigger again - let current animation complete
        return;
      }
    }
    
    _feedbackType[circleLabel] = isCorrect;
    
    // Trigger animation - forward then reverse
    controller.forward().then((_) {
      if (mounted && _feedbackControllers.containsKey(circleLabel)) {
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
  bool _isPointInCircle(Offset point, String circleLabel) {
    Circle? circle;
    try {
      circle = widget.circles.firstWhere((c) => c.label == circleLabel);
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
      onPanStart: widget.testComplete ? null : (details) {
        setState(() {
          final startPoint = details.localPosition;
          
          // Determine which circle the user needs to touch to enable drawing
          String requiredCircle;
          if (widget.circlesEntered.isEmpty) {
            // No circles entered yet, user must start at the first circle
            requiredCircle = widget.circles[0].label;
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
              final correctLineSegments = _getCorrectLineSegmentIndices();
              
              return CustomPaint(
                painter: DrawAreaPainter(
                  points: points,
                  circles: widget.circles,
                  feedbackControllers: _feedbackControllers,
                  feedbackType: _feedbackType,
                  circlesEntered: widget.circlesEntered,
                  activePulseController: _activePulseController,
                  requiredCircle: widget.circlesEntered.isEmpty 
                      ? widget.circles[0].label
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
