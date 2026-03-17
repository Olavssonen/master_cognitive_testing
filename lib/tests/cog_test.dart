import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'dart:math' as Math;

final cogTest = TestDefinition(
  id: 'cog',
  title: 'Clock Test',
  icon: Icons.schedule,
  build: (context, run) => CogTestScreen(run: run),
);

class CogTestScreen extends StatefulWidget {
  final TestRunContext run;
  const CogTestScreen({super.key, required this.run});

  @override
  State<CogTestScreen> createState() => _CogTestScreenState();
}

class _CogTestScreenState extends State<CogTestScreen> {
  late ClockTestWidget clockTest;

  @override
  void initState() {
    super.initState();
    clockTest = ClockTestWidget(
      run: widget.run,
      onAbort: () => widget.run.abort('User aborted'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Clock Test',
      child: clockTest,
    );
  }
}

class ClockTestWidget extends StatefulWidget {
  final TestRunContext run;
  final VoidCallback onAbort;

  const ClockTestWidget({
    super.key,
    required this.run,
    required this.onAbort,
  });

  @override
  State<ClockTestWidget> createState() => _ClockTestWidgetState();
}

class _ClockTestWidgetState extends State<ClockTestWidget> {
  // Track position of numbers on the overlay
  final Map<int, Offset> numberPositions = {};
  
  // Track drag state to calculate deltas properly
  final Map<int, Offset> dragStartGlobalPos = {};
  final Map<int, Offset> dragStartNumberPos = {};
  
  // Track which number is currently being dragged
  int? currentlyDraggingNumber;
  
  final GlobalKey<State> _stackKey = GlobalKey();
  final GlobalKey _clockSizedBoxKey = GlobalKey();
    // Debug mode: show visual zones and color feedback
  static const bool debugMode = false;
    // Clock geometry (initialize to default values, will be set during layout)
  double clockRadius = 0;
  Offset? clockCenter;
  
  // Tolerance area: pixels inside and outside the outer circle for valid zones
  static const double toleranceMargin = 50.0;
  @override
  void initState() {
    super.initState();
    // Initialize all numbers at bottom (not on overlay)
    for (int i = 1; i <= 12; i++) {
      numberPositions[i] = const Offset(-1000, -1000); // Offscreen
    }
  }

  /// Get the pizza slice number (1-12) for a given point
  /// Slice 12 is at the top (12 o'clock), slice 3 is at the right (3 o'clock), etc.
  /// Returns null if error
  int? _getPizzaSlice(Offset point) {
    if (clockCenter == null) return null;
    
    final dx = point.dx - clockCenter!.dx;
    final dy = point.dy - clockCenter!.dy;
    
    // Calculate angle in degrees, where 0° is up (12 o'clock)
    // atan2 returns angle in radians, -π to π
    var angle = (Math.atan2(dx, -dy) * 180 / Math.pi).toDouble();
    
    // Convert to 0-360 range
    if (angle < 0) angle += 360;
    
    // Each slice is 30 degrees (360 / 12)
    // Slice 12 is from -15 to +15 degrees (centered at 0°/top)
    // Slice 1 is from 15 to 45 degrees
    // Slice 3 is from 75 to 105 degrees (right), etc.
    var centerAngle = angle + 15; // Shift so slice boundaries align
    if (centerAngle >= 360) centerAngle -= 360;
    
    final sliceIndex = (centerAngle / 30).floor(); // 0-11
    final clockNumber = sliceIndex == 0 ? 12 : sliceIndex;
    
    return clockNumber;
  }

  /// Check if any part of a circle overlaps with the valid zone
  /// numberCenter: center of the number circle
  /// numberRadius: radius of the number circle
  /// clockNumber: which clock position this number represents
  bool _circleOverlapsValidZone(Offset numberCenter, double numberRadius, int clockNumber) {
    if (clockCenter == null) return false;
    
    final distanceToCenter = (numberCenter - clockCenter!).distance;
    
    // Valid distance band for the zone
    final minDistance = clockRadius - toleranceMargin;
    final maxDistance = clockRadius + toleranceMargin;
    
    // Check if circle overlaps with distance band
    // Circle touches the band if: closest point <= maxDistance AND farthest point >= minDistance
    final closestPoint = distanceToCenter - numberRadius;
    final farthestPoint = distanceToCenter + numberRadius;
    
    if (farthestPoint < minDistance || closestPoint > maxDistance) {
      return false; // Circle doesn't reach the valid distance band
    }
    
    // Now check if the center is in the correct pizza slice
    // (if center is correct, most of the circle should be in the right slice)
    final sliceNumber = _getPizzaSlice(numberCenter);
    return sliceNumber == clockNumber;
  }

  /// Calculate the score by checking each number's position
  /// Returns map with 'correct_numbers' and 'total_numbers'
  Map<String, int> _calculateScore() {
    int correctCount = 0;
    const numberCircleRadius = 35.0; // Half of circleSizePixels (70)
    
    for (int number = 1; number <= 12; number++) {
      final position = numberPositions[number];
      
      // Skip if number is not on overlay (offscreen)
      if (position == null || (position.dx < -100 && position.dy < -100)) {
        continue;
      }
      
      // Check if any part of the number circle overlaps with the valid zone
      final numberCenter = Offset(
        position.dx + numberCircleRadius,
        position.dy + numberCircleRadius,
      );
      
      if (_circleOverlapsValidZone(numberCenter, numberCircleRadius, number)) {
        correctCount++;
      }
    }
    
    return {
      'correct_numbers': correctCount,
      'total_numbers': 12,
    };
  }

  Widget _buildNumberCircle(int number) {
    const circleSizePixels = 70.0;
    final position = numberPositions[number]!;
    
    // Hide the original number if it's on the overlay (not offscreen)
    final isOnOverlay = position.dx > -100 && position.dy > -100;
    
    return Opacity(
      opacity: isOnOverlay ? 0 : 1,
      child: IgnorePointer(
        ignoring: isOnOverlay,
        child: GestureDetector(
          onPanStart: (details) {
            if (currentlyDraggingNumber != null) return;
            
            final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
            if (stackBox == null) return;
            
            final localPos = stackBox.globalToLocal(details.globalPosition);
            
            setState(() {
              currentlyDraggingNumber = number;
              dragStartGlobalPos[number] = details.globalPosition;
              dragStartNumberPos[number] = Offset(
                localPos.dx - circleSizePixels / 2,
                localPos.dy - circleSizePixels / 2,
              );
              numberPositions[number] = dragStartNumberPos[number]!;
            });
          },
          onPanUpdate: (details) {
            if (currentlyDraggingNumber != number) return;
            
            final delta = Offset(
              details.globalPosition.dx - dragStartGlobalPos[number]!.dx,
              details.globalPosition.dy - dragStartGlobalPos[number]!.dy,
            );
            
            setState(() {
              numberPositions[number] = Offset(
                dragStartNumberPos[number]!.dx + delta.dx,
                dragStartNumberPos[number]!.dy + delta.dy,
              );
            });
          },
          onPanEnd: (details) {
            if (currentlyDraggingNumber != number) return;
            
            setState(() {
              currentlyDraggingNumber = null;
              dragStartGlobalPos.remove(number);
              dragStartNumberPos.remove(number);
            });
          },
          child: Container(
            width: circleSizePixels,
            height: circleSizePixels,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitTest() {
    final scoreData = _calculateScore();
    final score = {
      'correct_numbers': scoreData['correct_numbers'],
      'total_numbers': scoreData['total_numbers'],
      'total_score': scoreData['correct_numbers'],
    };

    widget.run.complete(
      TestResult(testId: 'cog', summary: score),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        // Main layout - 3 dynamic sections using Expanded with flex proportions
        Column(
          children: [
            // Top section - instructions (takes 1/7 of screen)
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Arrange the numbers around the clock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            // Middle section - clock (takes 4/7 of screen)
            Expanded(
              flex: 4,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make clock responsive - use 80% of available width or height, whichever is smaller
                    final maxSize = (constraints.maxWidth * 0.80).clamp(0.0, constraints.maxHeight);
                    final screenSize = maxSize;
                    final radius = screenSize / 2;
                    
                    // Store clock geometry for validation calculations
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        clockRadius = radius;
                        // Use the SizedBox key to get accurate position
                        final clockBox = _clockSizedBoxKey.currentContext?.findRenderObject() as RenderBox?;
                        final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                        if (clockBox != null && stackBox != null) {
                          // Get the global position of the clock center
                          final clockWidgetCenter = Offset(
                            clockBox.size.width / 2,
                            clockBox.size.height / 2,
                          );
                          // Convert to Stack local coordinates
                          final globalCenter = clockBox.localToGlobal(clockWidgetCenter);
                          clockCenter = stackBox.globalToLocal(globalCenter);
                        }
                      });
                    });
                    
                    return SizedBox(
                      key: _clockSizedBoxKey,
                      width: screenSize,
                      height: screenSize,
                      child: CustomPaint(
                        painter: ClockPainter(
                          clockRadius: radius,
                          toleranceMargin: toleranceMargin,
                          debugMode: debugMode,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Bottom section - numbers (takes 2/7 of screen)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // First row of 6 numbers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final number = index + 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildNumberCircle(number),
                        );
                      }),
                    ),
                    const SizedBox(height: 25),
                    // Second row of 6 numbers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final number = index + 7;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildNumberCircle(number),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons - fixed at bottom
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _submitTest,
                    child: const Text('Submit'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: widget.onAbort,
                    child: const Text('Abort'),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Overlay for dragged/placed numbers
        ..._buildDraggedOverlay(),
      ],
    );
  }

  List<Widget> _buildDraggedOverlay() {
    const circleSizePixels = 70.0;
    final widgets = <Widget>[];

    for (var entry in numberPositions.entries) {
      final number = entry.key;
      final position = entry.value;
      
      // Only show if position is not offscreen
      if (position.dx < -100 || position.dy < -100) continue;

      widgets.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanStart: (details) {
              if (currentlyDraggingNumber != null) return;
              
              final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (stackBox == null) return;
              
              final localPos = stackBox.globalToLocal(details.globalPosition);
              
              setState(() {
                currentlyDraggingNumber = number;
                dragStartGlobalPos[number] = details.globalPosition;
                dragStartNumberPos[number] = Offset(
                  localPos.dx - circleSizePixels / 2,
                  localPos.dy - circleSizePixels / 2,
                );
                numberPositions[number] = dragStartNumberPos[number]!;
              });
            },
            onPanUpdate: (details) {
              if (currentlyDraggingNumber != number) return;
              
              final delta = Offset(
                details.globalPosition.dx - dragStartGlobalPos[number]!.dx,
                details.globalPosition.dy - dragStartGlobalPos[number]!.dy,
              );
              
              setState(() {
                numberPositions[number] = Offset(
                  dragStartNumberPos[number]!.dx + delta.dx,
                  dragStartNumberPos[number]!.dy + delta.dy,
                );
              });
            },
            onPanEnd: (details) {
              if (currentlyDraggingNumber != number) return;
              
              setState(() {
                currentlyDraggingNumber = null;
                dragStartGlobalPos.remove(number);
                dragStartNumberPos.remove(number);
              });
            },
            child: Container(
              width: circleSizePixels,
              height: circleSizePixels,
              decoration: BoxDecoration(
                color: () {
                  if (!debugMode) return Colors.blue;
                  // Calculate the center of this number circle
                  final numberCenter = Offset(
                    position.dx + circleSizePixels / 2,
                    position.dy + circleSizePixels / 2,
                  );
                  const numberCircleRadius = circleSizePixels / 2; // 35 pixels
                  // Check if any part of the circle overlaps with valid zone
                  return _circleOverlapsValidZone(numberCenter, numberCircleRadius, number) 
                    ? Colors.green 
                    : Colors.blue;
                }(),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class ClockPainter extends CustomPainter {
  final double clockRadius;
  final double toleranceMargin;
  final bool debugMode;

  ClockPainter({
    required this.clockRadius,
    required this.toleranceMargin,
    required this.debugMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw debugging visuals only in debug mode
    if (debugMode) {
      // Draw pizza slices with transparent colors for debugging
      _drawPizzaSlices(canvas, center);
      
      // Draw tolerance area bands
      _drawToleranceAreas(canvas, center);
    }
    
    // Draw the main clock circle outline
    final circlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, clockRadius, circlePaint);
    
    // Draw center point
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerPaint);
  }

  void _drawPizzaSlices(Canvas canvas, Offset center) {
    const sliceCount = 12;
    const sliceAngle = 360 / sliceCount; // 30 degrees per slice
    
    final minRadius = clockRadius - toleranceMargin;
    final maxRadius = clockRadius + toleranceMargin;
    
    // Colors for different slices (for visual distinction)
    final colors = [
      Colors.red.withOpacity(0.15),
      Colors.orange.withOpacity(0.15),
      Colors.yellow.withOpacity(0.15),
      Colors.green.withOpacity(0.15),
      Colors.blue.withOpacity(0.15),
      Colors.indigo.withOpacity(0.15),
      Colors.red.withOpacity(0.15),
      Colors.orange.withOpacity(0.15),
      Colors.yellow.withOpacity(0.15),
      Colors.green.withOpacity(0.15),
      Colors.blue.withOpacity(0.15),
      Colors.indigo.withOpacity(0.15),
    ];
    
    for (int i = 0; i < sliceCount; i++) {
      // Center each slice on its clock position
      // Slice 0 (12): center at -90°, span -105° to -75°
      // Slice 3 (3): center at 0°, span -15° to 15°
      final centerAngle = (i * sliceAngle - 90);
      final startAngle = (centerAngle - 15) * Math.pi / 180;
      final endAngle = (centerAngle + 15) * Math.pi / 180;
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      // Create an annular sector (pizza slice within tolerance band)
      final path = Path();
      
      // Start at inner circle
      final innerStartX = center.dx + minRadius * Math.cos(startAngle);
      final innerStartY = center.dy + minRadius * Math.sin(startAngle);
      path.moveTo(innerStartX, innerStartY);
      
      // Arc along inner circle
      path.arcTo(
        Rect.fromCircle(center: center, radius: minRadius),
        startAngle,
        endAngle - startAngle,
        false,
      );
      
      // Line to outer circle
      final outerEndX = center.dx + maxRadius * Math.cos(endAngle);
      final outerEndY = center.dy + maxRadius * Math.sin(endAngle);
      path.lineTo(outerEndX, outerEndY);
      
      // Arc along outer circle (backwards)
      path.arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        endAngle,
        startAngle - endAngle,
        false,
      );
      
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawToleranceAreas(Canvas canvas, Offset center) {
    final minRadius = clockRadius - toleranceMargin;
    final maxRadius = clockRadius + toleranceMargin;
    
    // Draw explicit boundary circles (these are the actual validation boundaries)
    final boundaryPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Inner boundary (closest to center that's still valid)
    canvas.drawCircle(center, minRadius, boundaryPaint);
    
    // Outer boundary (farthest from center that's still valid)
    canvas.drawCircle(center, maxRadius, boundaryPaint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return oldDelegate.clockRadius != clockRadius ||
        oldDelegate.toleranceMargin != toleranceMargin ||
        oldDelegate.debugMode != debugMode;
  }
}

