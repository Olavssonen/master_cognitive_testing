import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';

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
  // Track positions for scoring - updated during drag
  final Map<int, Offset> draggedPositions = {};
  final Map<int, Offset> finalPositions = {};
  final Map<int, Offset> dragStartPositions = {};
  final GlobalKey _stackKey = GlobalKey();

  late Offset clockCenter;
  late double clockRadius;
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
  }

  void _updateNumberPosition(int number, Offset globalPosition) {
    setState(() {
      draggedPositions[number] = globalPosition;
    });
  }

  double _calculateAngle(Offset position) {
    final angle = atan2(position.dy, position.dx) * 180 / pi + 90;
    return (angle + 360) % 360;
  }

  Widget _buildNumberCircle(int number) {
    const circleSizePixels = 70.0;
    final isDragging = draggedPositions.containsKey(number);
    final isPlaced = finalPositions.containsKey(number);

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          dragStartPositions[number] = details.globalPosition;
        });
      },
      onPanUpdate: (details) {
        _updateNumberPosition(number, details.globalPosition);
      },
      onPanEnd: (details) {
        setState(() {
          if (draggedPositions.containsKey(number)) {
            finalPositions[number] = draggedPositions[number]!;
          }
          draggedPositions.remove(number);
          dragStartPositions.remove(number);
        });
      },
      child: Opacity(
        opacity: (isDragging || isPlaced) ? 0 : 1,
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
    );
  }

  void _submitTest() {
    // For now, just submit with 0 correct since we simplified the layout
    // In production, you'd track dragged positions and score them
    final score = {
      'correct_numbers': 0,
      'total_numbers': 12,
      'total_score': 0,
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
        // Main layout
        Column(
          children: [
            Spacer(flex: 2),
            // Clock section
            Expanded(
              flex: 5,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make clock responsive - use 80% of available width
                    final clockSize = constraints.maxWidth * 0.80;
                    final clockRadius = clockSize / 2;
                    return SizedBox(
                      width: clockSize,
                      height: clockSize,
                      child: CustomPaint(
                        painter: ClockPainter(clockRadius: clockRadius),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Spacing between clock and numbers
            Expanded(flex: 1, child: SizedBox.expand()),
            // Number grid section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 75),
                child: SingleChildScrollView(
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
            ),
            Spacer(flex: 1),
            // Buttons
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
        // Overlay for dragged numbers
        ..._buildDraggedOverlay(),
      ],
    );
  }

  List<Widget> _buildDraggedOverlay() {
    final stackRenderBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackRenderBox == null) return [];

    final widgets = <Widget>[];
    final stackHeight = stackRenderBox.size.height;
    // Calculate approximate clock bottom position (60% of first 5 flex + 2 flex spacer)
    // Rough constraint: numbers shouldn't go above 65% of screen height
    final maxTopConstraint = stackHeight * 0.65;
    
    // Render currently dragging numbers
    for (var entry in draggedPositions.entries) {
      final localPos = stackRenderBox.globalToLocal(entry.value);
      
      widgets.add(
        Positioned(
          left: localPos.dx - 35,
          top: localPos.dy - 35,
          child: IgnorePointer(
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.key}',
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

    // Render finally placed numbers
    for (var entry in finalPositions.entries) {
      final localPos = stackRenderBox.globalToLocal(entry.value);
      
      widgets.add(
        Positioned(
          left: localPos.dx - 35,
          top: localPos.dy - 35,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                dragStartPositions[entry.key] = details.globalPosition;
                finalPositions.remove(entry.key);
              });
            },
            onPanUpdate: (details) {
              _updateNumberPosition(entry.key, details.globalPosition);
            },
            onPanEnd: (details) {
              setState(() {
                if (draggedPositions.containsKey(entry.key)) {
                  finalPositions[entry.key] = draggedPositions[entry.key]!;
                }
                draggedPositions.remove(entry.key);
                dragStartPositions.remove(entry.key);
              });
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.key}',
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

  ClockPainter({required this.clockRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw only the circle outline
    canvas.drawCircle(center, clockRadius, paint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) => false;
}

