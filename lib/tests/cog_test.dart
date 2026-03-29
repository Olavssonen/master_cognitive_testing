import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/round_info_screen.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'dart:math' as Math;

final cogTest = TestDefinition(
  id: 'Mini-Cog Test',
  title: 'Hukommelse',
  icon: Icons.schedule,
  build: (context, run) => CogTestScreen(run: run),
);

// Words for the word recall test
const List<String> targetWords = ['Banan', 'Soloppgang', 'Stol'];
const List<String> distractorWords = ['Leder', 'Årstid', 'Bord', 'Landsby', 'Kjøkken', 'Baby', 'Elv'];

class CogTestScreen extends StatefulWidget {
  final TestRunContext run;
  const CogTestScreen({super.key, required this.run});

  @override
  State<CogTestScreen> createState() => _CogTestScreenState();
}

class _CogTestScreenState extends State<CogTestScreen> {
  late MiniCogTestWidget miniCogTest;

  @override
  void initState() {
    super.initState();
    miniCogTest = MiniCogTestWidget(
      run: widget.run,
      onAbort: () => widget.run.abort('User aborted'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      child: miniCogTest,
    );
  }
}

class MiniCogTestWidget extends ConsumerStatefulWidget {
  final TestRunContext run;
  final VoidCallback onAbort;

  const MiniCogTestWidget({
    super.key,
    required this.run,
    required this.onAbort,
  });

  @override
  ConsumerState<MiniCogTestWidget> createState() => _MiniCogTestWidgetState();
}

class _MiniCogTestWidgetState extends ConsumerState<MiniCogTestWidget> {
  // Phases: 'word_recall_1', 'clock_instruction', 'clock_test', 'word_recall_2', 'completed'
  String _currentPhase = 'word_recall_1';
  
  // Score tracking
  int _correctWords = 0;
  int _correctClockNumbers = 0;
  int _correctHourHand = 0;
  int _correctMinuteHand = 0;
  Uint8List? _clockImage;
  
  late ClockTestWidget clockTest;
  
  @override
  void initState() {
    super.initState();
    clockTest = ClockTestWidget(
      run: widget.run,
      onAbort: widget.onAbort,
      onClockComplete: _handleClockTestComplete,
    );
  }

  void _handleClockTestComplete(Map<String, dynamic> clockScore) {
    setState(() {
      _correctClockNumbers = clockScore['correct_numbers'] as int? ?? 0;
      _correctHourHand = clockScore['hour_hand_correct'] as int? ?? 0;
      _correctMinuteHand = clockScore['minute_hand_correct'] as int? ?? 0;
      var image = clockScore['image'];
      if (image != null) {
        if (image is Uint8List) {
          _clockImage = image;
        } else if (image is List<int>) {
          _clockImage = Uint8List.fromList(image);
        }
      }
      _currentPhase = 'word_recall_2';
    });
  }

  void _proceedToClockTest() {
    setState(() {
      _currentPhase = 'clock_instruction';
    });
  }

  void _proceedToClockTestExecution() {
    setState(() {
      _currentPhase = 'clock_test';
    });
  }

  void _handleWordRecall2Complete(int correctCount) {
    setState(() {
      _correctWords = correctCount;
      _currentPhase = 'completed';
    });
    
    // Submit the test with all scores
    _submitTest();
  }

  void _submitTest() {
    final score = {
      'word_recall_correct': _correctWords,
      'word_recall_total': 3,
      'correct_numbers': _correctClockNumbers,
      'total_numbers': 12,
      'hour_hand_correct': _correctHourHand,
      'minute_hand_correct': _correctMinuteHand,
      'hands_correct': _correctHourHand + _correctMinuteHand,
      'hands_total': 2,
      'total_score': _correctWords + _correctClockNumbers + _correctHourHand + _correctMinuteHand,
      'clock_image': _clockImage,
    };

    widget.run.complete(
      TestResult(testId: 'cog', summary: score),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPhase == 'word_recall_1') {
      return WordRecallPhase1(
        onNext: _proceedToClockTest,
        onAbort: widget.onAbort,
      );
    } else if (_currentPhase == 'clock_instruction') {
      return TestShell(
        child: RoundInfoScreen(
          title: ref.watch(appStringsProvider).round2,
          subtitle: ref.watch(appStringsProvider).clockInstruction,
          bodyText: ref.watch(appStringsProvider).clockInstruction2,
          bottomContent: BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).start,
              icon: Icons.play_arrow,
              onPressed: _proceedToClockTestExecution,
            ),
            onAbort: widget.onAbort,
            debugMode: true,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
      );
    } else if (_currentPhase == 'clock_test') {
      return clockTest;
    } else if (_currentPhase == 'word_recall_2') {
      return WordRecallPhase2(
        onComplete: _handleWordRecall2Complete,
        onAbort: widget.onAbort,
      );
    }
    
    return const SizedBox.shrink();
  }
}

class WordRecallPhase1 extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onAbort;

  const WordRecallPhase1({
    super.key,
    required this.onNext,
    this.onAbort,
  });

  @override
  ConsumerState<WordRecallPhase1> createState() => _WordRecallPhase1State();
}

class _WordRecallPhase1State extends ConsumerState<WordRecallPhase1> {
  bool _showingInstructions = true;

  @override
  @override
  Widget build(BuildContext context) {
    if (_showingInstructions) {
      return TestShell(
        child: RoundInfoScreen(
          title: ref.watch(appStringsProvider).round1,
          subtitle: ref.watch(appStringsProvider).memory,
          bodyText: ref.watch(appStringsProvider).rememberWords,
          bottomContent: BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).start,
              onPressed: () => setState(() => _showingInstructions = false),
              icon: Icons.play_arrow,
            ),
            onAbort: widget.onAbort,
            debugMode: true,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
      );
    }

    return TestShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...targetWords.map((word) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        word,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).done,
              onPressed: widget.onNext,
              icon: Icons.check_circle,
            ),
            onAbort: widget.onAbort,
            debugMode: true,
          ),
        ],
      ),
    );
  }
}

class WordRecallPhase2 extends ConsumerStatefulWidget {
  final Function(int) onComplete;
  final VoidCallback? onAbort;

  const WordRecallPhase2({
    super.key,
    required this.onComplete,
    this.onAbort,
  });

  @override
  ConsumerState<WordRecallPhase2> createState() => _WordRecallPhase2State();
}

class _WordRecallPhase2State extends ConsumerState<WordRecallPhase2> {
  late List<String> allWords;
  Set<String> selectedWords = {};
  bool _showingInstructions = true;

  @override
  void initState() {
    super.initState();
    // Shuffle and prepare the word list
    allWords = [...targetWords, ...distractorWords];
    allWords.shuffle(Math.Random());
  }

  void _toggleWord(String word) {
    setState(() {
      if (selectedWords.contains(word)) {
        selectedWords.remove(word);
      } else {
        selectedWords.add(word);
      }
    });
  }

  void _submitRecall() {
    // Count how many correct words were selected
    int correctCount = 0;
    for (String word in selectedWords) {
      if (targetWords.contains(word)) {
        correctCount++;
      }
    }
    
    widget.onComplete(correctCount);
  }

  @override
  Widget build(BuildContext context) {
    if (_showingInstructions) {
      return TestShell(
        child: RoundInfoScreen(
          title: ref.watch(appStringsProvider).round4,
          subtitle: ref.watch(appStringsProvider).memory,
          bodyText: ref.watch(appStringsProvider).repeatWords,
          bottomContent: BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).start,
              onPressed: () => setState(() => _showingInstructions = false),
              icon: Icons.play_arrow,
            ),
            onAbort: widget.onAbort,
            debugMode: true,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
      );
    }

    return TestShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 700,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 150,
                      ),
                      itemCount: allWords.length,
                      itemBuilder: (context, index) {
                        final word = allWords[index];
                        final isSelected = selectedWords.contains(word);
                        return GestureDetector(
                          onTap: () => _toggleWord(word),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                word,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).done,
              onPressed: _submitRecall,
              icon: Icons.check_circle,
            ),
            onAbort: widget.onAbort,
            debugMode: true,
          ),
        ],
      ),
    );
  }
}

class ClockTestWidget extends ConsumerStatefulWidget {
  final TestRunContext run;
  final VoidCallback onAbort;
  final Function(Map<String, dynamic>)? onClockComplete;

  const ClockTestWidget({
    super.key,
    required this.run,
    required this.onAbort,
    this.onClockComplete,
  });

  @override
  ConsumerState<ClockTestWidget> createState() => _ClockTestWidgetState();
}

class _ClockTestWidgetState extends ConsumerState<ClockTestWidget> {
  // Track position of numbers on the overlay
  final Map<int, Offset> numberPositions = {};
  
  // Track drag state to calculate deltas properly
  final Map<int, Offset> dragStartGlobalPos = {};
  final Map<int, Offset> dragStartNumberPos = {};
  
  // Track which number is currently being dragged
  int? currentlyDraggingNumber;
  
  final GlobalKey<State> _stackKey = GlobalKey();
  final GlobalKey _clockSizedBoxKey = GlobalKey();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  // Screenshot capture
  Uint8List? _capturedImage;
  
  // Clock geometry (initialize to default values, will be set during layout)
  double clockRadius = 0;
  Offset? clockCenter;
  
  // Tolerance area: pixels inside and outside the outer circle for valid zones
  static const double toleranceMargin = 50.0;
  
  // Boundary constraint: prevent circles from being dragged below this Y position
  double? _bottomBoundaryY; // Y position where circles should stop
  
  // Top boundary: prevent circles from being dragged above this Y position
  double? _topBoundaryY; // Y position where circles should stop at top
  
  // Top boundary: visual separator below the text
  static const double topBoundaryLineHeight = 1.0;
  
  // Two phases: 'numbers', 'hands_instruction', 'hands'
  String _phase = 'numbers';
  
  // Hand angles in degrees (0 = 12 o'clock, 90 = 3 o'clock, etc.)
  double _minuteHandAngle = 246; // langeviser (minute/long hand) - pointing downwards
  double _hourHandAngle = 120; // korteviser (hour/short hand) - pointing downwards
  
  // Track which hand is currently being dragged (null, 0 for minute, 1 for hour)
  int? _draggingHandId;
  
  // Hand dimensions - easily adjustable
  static const double minuteHandLength = 250.0; // longeviser
  static const double minuteHandWidth = 32.0;
  static const double hourHandLength = 175.0;   // korteviser
  static const double hourHandWidth = 32.0;
  
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
  Map<String, int> _calculateNumberScore() {
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

  /// Calculate hand scores by checking if hands point to correct positions
  /// The minute hand (langeviser) should be in slice 2
  /// The hour hand (korteviser) should be in slice 11
  Map<String, bool> _calculateHandScore() {
    // Get the pizza slice for each hand
    final minuteHandSlice = _getPizzaSliceFromAngle(_minuteHandAngle);
    final hourHandSlice = _getPizzaSliceFromAngle(_hourHandAngle);
    
    // Check if hands are in correct pizza slices
    // Minute hand (langeviser/long) should be in slice 2 only
    final minuteHandCorrect = minuteHandSlice == 2;
    
    // Hour hand (korteviser/short) should be in slice 11 only
    final hourHandCorrect = hourHandSlice == 11;
    
    return {
      'minute_hand_correct': minuteHandCorrect,
      'hour_hand_correct': hourHandCorrect,
    };
  }

  /// Convert hand angle to pizza slice number
  /// angle: degrees where 0 = 12 o'clock, 90 = 3 o'clock, etc.
  int _getPizzaSliceFromAngle(double angle) {
    // Normalize angle to 0-360
    double normalizedAngle = angle % 360;
    if (normalizedAngle < 0) normalizedAngle += 360;
    
    // Each slice is 30 degrees, slice 12 is centered at 0°
    // Add 15 degrees to shift so boundaries align at multiples of 30
    var centerAngle = normalizedAngle + 15;
    if (centerAngle >= 360) centerAngle -= 360;
    
    final sliceIndex = (centerAngle / 30).floor(); // 0-11
    return sliceIndex == 0 ? 12 : sliceIndex;
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
            if (_phase != 'numbers') return; // Only drag in numbers phase
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
            if (_phase != 'numbers') return; // Only drag in numbers phase
            if (currentlyDraggingNumber != number) return;
            
            final delta = Offset(
              details.globalPosition.dx - dragStartGlobalPos[number]!.dx,
              details.globalPosition.dy - dragStartGlobalPos[number]!.dy,
            );
            
            var newX = dragStartNumberPos[number]!.dx + delta.dx;
            var newY = dragStartNumberPos[number]!.dy + delta.dy;
            
            // Apply boundary constraints
            if (_bottomBoundaryY != null) {
              const circleSizePixels = 70.0;
              final maxY = _bottomBoundaryY! - circleSizePixels;
              if (newY > maxY) {
                newY = maxY;
              }
            }
            
            if (_topBoundaryY != null) {
              if (newY < _topBoundaryY!) {
                newY = _topBoundaryY!;
              }
            }
            
            setState(() {
              numberPositions[number] = Offset(newX, newY);
            });
          },
          onPanEnd: (details) {
            if (_phase != 'numbers') return; // Only drag in numbers phase
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
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureClockWidget() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          setState(() {
            _capturedImage = bytes;
          });
        }
      }
    } catch (e) {
      print('Error capturing clock widget: $e');
    }
  }

  void _submitTest() {
    if (_phase == 'numbers') {
      // Transition to hands instruction phase
      setState(() {
        _phase = 'hands_instruction';
      });
    } else if (_phase == 'hands_instruction') {
      // Transition from instruction to actual hands phase
      setState(() {
        _phase = 'hands';
      });
    } else {
      // Phase 'hands': capture screenshot then submit the test with all scores
      _captureClockWidget().then((_) {
        final numberScoreData = _calculateNumberScore();
        final handScoreData = _calculateHandScore();
        
        // Extract hand score values to avoid nullable issues
        final minuteHandCorrect = handScoreData['minute_hand_correct'] ?? false;
        final hourHandCorrect = handScoreData['hour_hand_correct'] ?? false;
        
        final score = {
          'correct_numbers': numberScoreData['correct_numbers'],
          'total_numbers': 12,
          // Separate scoring for clock hands (not part of 12 points)
          'hour_hand_correct': hourHandCorrect ? 1 : 0,
          'minute_hand_correct': minuteHandCorrect ? 1 : 0,
          'hands_total': 2,
          'hands_correct': (minuteHandCorrect && hourHandCorrect) ? 2 : (minuteHandCorrect || hourHandCorrect ? 1 : 0),
          // Overall score
          'total_score': numberScoreData['correct_numbers']! + (minuteHandCorrect ? 1 : 0) + (hourHandCorrect ? 1 : 0),
          // Add screenshot
          'image': _capturedImage,
        };

        // If onClockComplete callback is provided, use it (mini-cog flow)
        if (widget.onClockComplete != null) {
          widget.onClockComplete!(score);
        } else {
          // Fall back to direct completion (backwards compatibility)
          widget.run.complete(
            TestResult(testId: 'cog', summary: score),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final debugMode = ref.watch(debugModeProvider);
    
    final mainContent = Column(
      children: [
        // Top section - instructions (tight container with padding)
        Padding(
          padding: const EdgeInsets.only(top: 50, bottom: 8),
          child: Builder(builder: (context) {
            final strings = ref.watch(appStringsProvider);
            final displayText = _phase == 'hands' 
              ? strings.clockHandInstruction 
              : (_phase == 'hands_instruction' 
                ? strings.clockHandInstruction 
                : strings.clockInstruction2);
            return Text(
              displayText,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),
            );
          }),
        ),
        // RepaintBoundary wraps the Stack with clock, overlays, and hands
        Expanded(
          flex: 1,
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              key: _stackKey,
              children: [
                // Inner layout - clock and numbers (with top padding for the boundary line)
                Positioned(
                  left: 0,
                  top: topBoundaryLineHeight,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      // Middle section - clock (takes 4/7 of remaining space)
                      Expanded(
                        flex: 6,
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
                                
                                // Calculate the bottom boundary for dragged circles
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (stackBox != null) {
                                    // Set boundary to the bottom of the stack
                                    setState(() {
                                      _bottomBoundaryY = stackBox.size.height;
                                      // Set top boundary to just below the boundary line
                                      _topBoundaryY = topBoundaryLineHeight;
                                    });
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
                    strokeColor: Theme.of(context).colorScheme.primary,
                    centerColor: Theme.of(context).colorScheme.primary,
                    boundaryColor: AppColors.errorRed,
                    fillColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
                            },
                          ),
                        ),
                      ),
                      // Bottom section - numbers (takes 2/7 of remaining space)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                    ],
                  ),
                ),
                // Overlay for dragged/placed numbers
                ..._buildDraggedOverlay(debugMode),
                // Clock hands (visible in hands phase)
                if (_phase == 'hands')
                  _buildClockHands(),
              ],
            ),
          ),
        ),
        // Abort button - at bottom using BottomButtonBar
        BottomButtonBar(
          primaryButton: BottomButton(
            label: ref.watch(appStringsProvider).done,
            onPressed: _submitTest,
            type: BottomButtonType.filled,
            icon: Icons.check_circle,
          ),
          onAbort: widget.onAbort,
          debugMode: true,
        ),
      ],
    );
    
    // If showing hands instruction, display it instead of main content
    if (_phase == 'hands_instruction') {
      return TestShell(
        child: RoundInfoScreen(
          title: ref.watch(appStringsProvider).round3,
          subtitle: ref.watch(appStringsProvider).clockInstruction,
          bodyText: ref.watch(appStringsProvider).clockHandInstruction,
          bottomContent: BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).start,
              icon: Icons.play_arrow,
              onPressed: _submitTest,
            ),
            onAbort: widget.onAbort,
            debugMode: debugMode,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
      );
    }
    
    return mainContent;
  }

  List<Widget> _buildDraggedOverlay(bool debugMode) {
    const circleSizePixels = 70.0;
    final List<Widget> widgets = <Widget>[];

    for (final MapEntry<int, Offset> entry in numberPositions.entries) {
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
              if (_phase != 'numbers') return; // Only drag in numbers phase
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
              if (_phase != 'numbers') return; // Only drag in numbers phase
              if (currentlyDraggingNumber != number) return;
              
              final delta = Offset(
                details.globalPosition.dx - dragStartGlobalPos[number]!.dx,
                details.globalPosition.dy - dragStartGlobalPos[number]!.dy,
              );
              
              var newX = dragStartNumberPos[number]!.dx + delta.dx;
              var newY = dragStartNumberPos[number]!.dy + delta.dy;
              
              // Apply boundary constraints
              if (_bottomBoundaryY != null) {
                // Prevent any part of the circle from going below the bottom boundary
                // Circle is 70px tall, so the bottom edge is at (newY + 70)
                // We need: newY + 70 <= _bottomBoundaryY
                const circleSizePixels = 70.0;
                final maxY = _bottomBoundaryY! - circleSizePixels;
                if (newY > maxY) {
                  newY = maxY;
                }
              }
              
              // Prevent any part of the circle from going above the top boundary
              if (_topBoundaryY != null) {
                if (newY < _topBoundaryY!) {
                  newY = _topBoundaryY!;
                }
              }
              
              setState(() {
                numberPositions[number] = Offset(newX, newY);
              });
            },
            onPanEnd: (details) {
              if (_phase != 'numbers') return; // Only drag in numbers phase
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
                  if (!debugMode) return Theme.of(context).colorScheme.primary;
                  // Calculate the center of this number circle
                  final numberCenter = Offset(
                    position.dx + circleSizePixels / 2,
                    position.dy + circleSizePixels / 2,
                  );
                  const numberCircleRadius = circleSizePixels / 2; // 35 pixels
                  // Check if any part of the circle overlaps with valid zone
                  return _circleOverlapsValidZone(numberCenter, numberCircleRadius, number) 
                    ? AppColors.successGreen 
                    : Theme.of(context).colorScheme.primary;
                }(),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
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

  /// Build the clock hands widget for the hands phase
  Widget _buildClockHands() {
    if (_phase != 'hands') {
      return const SizedBox.shrink();
    }
    
    if (clockCenter == null) {
      return const SizedBox.shrink();
    }

    final clockCenterNotNull = clockCenter!;

    return Stack(
      children: [
        // Render clock hands - ignore pointer so touches pass through
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ClockHandsPainter(
                minuteHandAngle: _minuteHandAngle,
                hourHandAngle: _hourHandAngle,
                clockCenter: clockCenterNotNull,
                minuteHandLength: minuteHandLength,
                minuteHandWidth: minuteHandWidth,
                hourHandLength: hourHandLength,
                hourHandWidth: hourHandWidth,
                strokeColor: Theme.of(context).colorScheme.primary,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        // Gesture detection only inside the clock circle
        Positioned(
          left: clockCenterNotNull.dx - clockRadius,
          top: clockCenterNotNull.dy - clockRadius,
          width: clockRadius * 2,
          height: clockRadius * 2,
          child: GestureDetector(
            onPanStart: (details) {
              // Only start hand drag if touch is inside the clock circle
              final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (stackBox == null) return;

              final localPos = stackBox.globalToLocal(details.globalPosition);
              final dx = localPos.dx - clockCenterNotNull.dx;
              final dy = localPos.dy - clockCenterNotNull.dy;
              
              // Check if touch is inside the clock circle
              final distFromCenter = Offset(dx, dy).distance;
              if (distFromCenter > clockRadius) {
                return; // Outside clock - ignore
              }

              // Check if touch is close enough to a hand (anywhere along the line)
              final minuteHandTip = _getHandTipOffset(_minuteHandAngle, minuteHandLength);
              final hourHandTip = _getHandTipOffset(_hourHandAngle, hourHandLength);
              
              // Calculate distance to the hand line segments
              final distToMinuteHand = _distanceToLineSegment(
                Offset.zero, // Clock center in local coords
                minuteHandTip,
                Offset(dx, dy),
              );
              final distToHourHand = _distanceToLineSegment(
                Offset.zero, // Clock center in local coords
                hourHandTip,
                Offset(dx, dy),
              );

              // Determine which hand to drag (closer one wins, within 20 pixels)
              if (distToMinuteHand < 20 && distToMinuteHand < distToHourHand) {
                setState(() {
                  _draggingHandId = 0; // Minute hand
                });
              } else if (distToHourHand < 20) {
                setState(() {
                  _draggingHandId = 1; // Hour hand
                });
              }
            },
            onPanUpdate: (details) {
              // Only update if a hand drag is in progress
              if (_draggingHandId == null) return;

              final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (stackBox == null) return;

              final localPos = stackBox.globalToLocal(details.globalPosition);
              final dx = localPos.dx - clockCenterNotNull.dx;
              final dy = localPos.dy - clockCenterNotNull.dy;

              // Calculate angle in degrees (0 = 12 o'clock)
              // No need to check if inside clock - allow dragging outside
              var angle = (Math.atan2(dx, -dy) * 180 / Math.pi).toDouble();
              if (angle < 0) angle += 360;

              // Update the hand that's being dragged
              if (_draggingHandId == 0) {
                setState(() {
                  _minuteHandAngle = angle;
                });
              } else if (_draggingHandId == 1) {
                setState(() {
                  _hourHandAngle = angle;
                });
              }
            },
            onPanEnd: (details) {
              // Stop dragging any hand
              setState(() {
                _draggingHandId = null;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  /// Get the tip offset of a hand relative to clock center
  Offset _getHandTipOffset(double angle, double length) {
    final radians = (angle - 90) * Math.pi / 180; // Adjust so 0° is up
    return Offset(
      length * Math.cos(radians),
      length * Math.sin(radians),
    );
  }

  /// Calculate the shortest distance from a point to a line segment
  /// lineStart: start of the line (clock center in local coords)
  /// lineEnd: end of the line (hand tip in local coords)
  /// point: the point to measure distance from
  double _distanceToLineSegment(Offset lineStart, Offset lineEnd, Offset point) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) {
      // Line segment is actually a point
      return (point - lineStart).distance;
    }

    // Calculate the projection of the point onto the line
    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / lengthSq;
    t = (t < 0) ? 0 : (t > 1) ? 1 : t;

    final projectionX = lineStart.dx + t * dx;
    final projectionY = lineStart.dy + t * dy;
    final projection = Offset(projectionX, projectionY);

    return (point - projection).distance;
  }
}

class ClockHandsPainter extends CustomPainter {
  final double minuteHandAngle;
  final double hourHandAngle;
  final Offset clockCenter;
  final double minuteHandLength;
  final double minuteHandWidth;
  final double hourHandLength;
  final double hourHandWidth;
  final Color strokeColor;

  ClockHandsPainter({
    required this.minuteHandAngle,
    required this.hourHandAngle,
    required this.clockCenter,
    required this.minuteHandLength,
    required this.minuteHandWidth,
    required this.hourHandLength,
    required this.hourHandWidth,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw minute hand (langeviser - longer)
    _drawHand(
      canvas,
      minuteHandAngle,
      minuteHandLength,
      minuteHandWidth,
      strokeColor,
    );

    // Draw hour hand (korteviser - shorter)
    _drawHand(
      canvas,
      hourHandAngle,
      hourHandLength,
      hourHandWidth,
      strokeColor.withOpacity(0.7),
    );

    // Draw center dot
    final centerPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(clockCenter, 10, centerPaint);
  }

  void _drawHand(
    Canvas canvas,
    double angle,
    double length,
    double width,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Convert angle to radians (0° at top)
    final radians = (angle - 90) * Math.pi / 180;

    final endX = clockCenter.dx + length * Math.cos(radians);
    final endY = clockCenter.dy + length * Math.sin(radians);

    canvas.drawLine(
      clockCenter,
      Offset(endX, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(ClockHandsPainter oldDelegate) {
    return oldDelegate.minuteHandAngle != minuteHandAngle ||
        oldDelegate.hourHandAngle != hourHandAngle;
  }
}

class ClockPainter extends CustomPainter {
  final double clockRadius;
  final double toleranceMargin;
  final bool debugMode;
  final Color strokeColor;
  final Color centerColor;
  final Color boundaryColor;
  final Color fillColor;

  ClockPainter({
    required this.clockRadius,
    required this.toleranceMargin,
    required this.debugMode,
    required this.strokeColor,
    required this.centerColor,
    required this.boundaryColor,
    required this.fillColor,
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
        // Fill the inside of the clock circle with primary color at 50% opacity
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, clockRadius, fillPaint);
        // Draw the main clock circle outline
    final circlePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, clockRadius, circlePaint);
    
    // Draw center point
    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16, centerPaint);
  }

  void _drawPizzaSlices(Canvas canvas, Offset center) {
    const sliceCount = 12;
    const sliceAngle = 360 / sliceCount; // 30 degrees per slice
    
    final minRadius = clockRadius - toleranceMargin;
    final maxRadius = clockRadius + toleranceMargin;
    
    // Colors for different slices (for visual distinction)
    final colors = [
      AppColors.errorRed.withOpacity(0.15),
      AppColors.warningYellow.withOpacity(0.15),
      AppColors.successGreen.withOpacity(0.15),
      AppColors.crayolaBlue.withOpacity(0.15),
      AppColors.tropicalTeal.withOpacity(0.15),
      AppColors.lavender.withOpacity(0.15),
      AppColors.errorRed.withOpacity(0.15),
      AppColors.warningYellow.withOpacity(0.15),
      AppColors.successGreen.withOpacity(0.15),
      AppColors.crayolaBlue.withOpacity(0.15),
      AppColors.tropicalTeal.withOpacity(0.15),
      AppColors.lavender.withOpacity(0.15),
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
      ..color = boundaryColor
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
        oldDelegate.debugMode != debugMode ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.boundaryColor != boundaryColor ||
        oldDelegate.fillColor != fillColor;
  }
}

