import 'package:flutter/material.dart';
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
  // Track position of numbers on the overlay
  final Map<int, Offset> numberPositions = {};
  
  // Track drag state to calculate deltas properly
  final Map<int, Offset> dragStartGlobalPos = {};
  final Map<int, Offset> dragStartNumberPos = {};
  
  // Track which number is currently being dragged
  int? currentlyDraggingNumber;
  
  final GlobalKey<State> _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize all numbers at bottom (not on overlay)
    for (int i = 1; i <= 12; i++) {
      numberPositions[i] = const Offset(-1000, -1000); // Offscreen
    }
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

