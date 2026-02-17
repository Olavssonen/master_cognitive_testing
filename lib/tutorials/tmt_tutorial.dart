import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/circles_painter.dart';

/// Tutorial screen for Trail Making Test (TMT)
/// Uses 3 circles instead of 6 and provides detailed instructions
class TMTTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final CircleMode mode;
  const TMTTutorial({
    super.key,
    required this.onComplete,
    this.mode = CircleMode.numbersOnly,
  });

  @override
  State<TMTTutorial> createState() => _TMTTutorialState();
}

class _TMTTutorialState extends State<TMTTutorial> with TickerProviderStateMixin {
  late CirclesWithNumbers circlesGenerator;
  List<Offset> drawnPoints = [];
  List<String> circlesEntered = [];
  List<String> _lastFeedbackSequence = [];
  Set<String> _allTouchedCircles = {};
  String feedbackMessage = 'Draw through circles in order';
  bool tutorialComplete = false;
  Function(String, bool)? _feedbackTrigger;
  VoidCallback? _clearDrawingCallback;
  String? lastCorrectCircle;

  @override
  void initState() {
    super.initState();
    circlesGenerator = CirclesWithNumbers(
      numberOfCircles: 3,
      mode: widget.mode,
    );
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

      if (circlesEntered.isNotEmpty) {
        bool isCorrectSequence = _isCorrectSequence(circlesEntered);

        if (isCorrectSequence && circlesEntered.length == 3 && isContinuous) {
          feedbackMessage = 'Perfect! You completed the tutorial!';
          tutorialComplete = true;
        } else if (!isContinuous && circlesEntered.isNotEmpty) {
          feedbackMessage = 'You must draw a continuous line!';
        } else if (!isCorrectSequence) {
          String nextExpected = _getExpectedLabel(circlesEntered.length);
          feedbackMessage = 'Next, touch $nextExpected';
        } else {
          String nextExpected = _getExpectedLabel(circlesEntered.length);
          feedbackMessage = 'Next, touch $nextExpected';
        }
      } else {
        feedbackMessage = _getSequenceInstruction();
      }
    });
  }

  String _getSequenceInstruction() {
    if (widget.mode == CircleMode.numbersOnly) {
      return 'Draw through circles in order: 1 → 2 → 3';
    } else {
      return 'Draw through circles in order: 1 → A → 2';
    }
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
      feedbackMessage = _getSequenceInstruction();
      tutorialComplete = false;
    });
    _clearDrawingCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Trail Making Test - Tutorial',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'How to Play',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Draw a continuous line through the numbered circles in order (1 → 2 → 3). '
                    'Do not lift your finger until you reach the final circle.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
              final height = (constraints.maxHeight.isFinite && constraints.maxHeight > 200)
                  ? constraints.maxHeight - 300
                  : 300.0;

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
                testComplete: tutorialComplete,
                lastCorrectCircle: lastCorrectCircle,
              );
            }),
            const SizedBox(height: 16),
            Text(
              feedbackMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tutorialComplete ? AppColors.grey900 : AppColors.grey800,
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
                  onPressed: tutorialComplete ? widget.onComplete : null,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
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
                if (isDrawingAllowed && _isPointInBounds(details.localPosition)) {
                  points.add(details.localPosition);
                  widget.onDrawingUpdated(points);
                }
              });
            },
      onPanEnd: (_) {
        setState(() {
          isDrawingAllowed = false;
          points.add(Offset(-1, -1));
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
                      ? '1'
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
