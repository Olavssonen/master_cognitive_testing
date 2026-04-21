import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers_v2.dart';
import 'package:flutter_master_app/tutorials/stroop_tutorial_v2.dart';
import 'package:flutter_master_app/widgets/round_info_screen.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/points_collected_widget.dart';

// Quick ref.watch helper for tests
final stroopTestV2 = TestDefinition(
  id: 'Stroop Test V2',
  title: 'Farger',
  icon: Icons.color_lens,
  build: (context, run) => StroopTestScreenV2(run: run),
);

class StroopTestScreenV2 extends ConsumerStatefulWidget {
  final TestRunContext run;
  const StroopTestScreenV2({super.key, required this.run});

  @override
  ConsumerState<StroopTestScreenV2> createState() => _StroopTestScreenStateV2();
}

class _StroopTestScreenStateV2 extends ConsumerState<StroopTestScreenV2> {
  int stage = 0;
  final Map<String, dynamic> stageResults = {};

  void _saveTestResult(
      String stageName, dynamic result, bool completed) {
    stageResults[stageName] = {
      'completed': completed,
      'result': result,
      'pointsEarned': result['pointsEarned'] as int? ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDebugMode = ref.watch(debugModeProvider);
    
    switch (stage) {
      case 0:
        return StroopTutorialV2(
          onComplete: () {
            setState(() => stage = 1);
          },
          onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
        );
      case 1:
        return TestShell(
          child: StroopIntermediateScreenV2(
            onReplay: () {
              setState(() => stage = 0);
            },
            onStartTest: () {
              setState(() => stage = 2);
            },
            onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
          ),
        );
      case 2:
        return StroopTestContentV2(
          run: widget.run,
          stageName: 'stroop_test_v2',
          onTestResult: (result, completed) {
            _saveTestResult('stroop_test_v2', result, completed);
            final pointsEarned = (result['pointsEarned'] as int?) ?? 0;
            widget.run.complete(
              TestResult(
                testId: 'stroop_v2',
                summary: {
                  'progression_completed': true,
                  'all_stages': stageResults,
                  'pointsEarned': pointsEarned,
                },
              ),
            );
          },
          onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
        );
      default:
        return const SizedBox();
    }
  }
}

class StroopTestContentV2 extends ConsumerStatefulWidget {
  final TestRunContext run;
  final String stageName;
  final Function(dynamic, bool)? onTestResult;
  final VoidCallback? onAbort;

  const StroopTestContentV2({
    super.key,
    required this.run,
    this.stageName = 'stroop_test_v2',
    this.onTestResult,
    this.onAbort,
  });

  @override
  ConsumerState<StroopTestContentV2> createState() => _StroopTestStateV2();
}

class _StroopTestStateV2 extends ConsumerState<StroopTestContentV2> with TickerProviderStateMixin {
  final int numberOfWords = 25; // Configurable number of trials
  
  late List<StroopItemV2> stroopItems;
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool testComplete = false;

  // Feedback state
  IconData? feedbackSymbol;
  Color? feedbackColor;
  late AnimationController _feedbackController;
  late AnimationController _wordTransitionController;
  bool _isProcessing = false;
  
  // Points tracking
  int startingSessionPoints = 0;
  late int basePointsPerWord;
  int lastPointsAwarded = 0;
  int lastTimeElapsedMs = 0;
  int lastDeduction = 0;

  @override
  void initState() {
    super.initState();
    // Capture starting points for this test
    startingSessionPoints = ref.read(sessionPointsProvider);
    
    // Calculate base points per word (dynamic based on numberOfWords)
    basePointsPerWord = (1000 / numberOfWords).ceil();
    
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _wordTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _wordTransitionController.forward(); // Prime it so first word shows
    stroopItems = _generateStroopItems(numberOfWords);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _wordTransitionController.dispose();
    super.dispose();
  }

  List<StroopItemV2> _generateStroopItems(int count) {
    final colors = StroopColorConstantsV2.colors;
    final colorNames = StroopColorConstantsV2.colorNames;
    final colorSymbols = StroopColorConstantsV2.colorSymbols;

    final random = Random();
    final List<StroopItemV2> items = [];
    int? previousColorIndex;

    for (int i = 0; i < count; i++) {
      int textColorIndex = random.nextInt(colors.length);
      
      // Ensure correct answer doesn't repeat consecutively
      while (textColorIndex == previousColorIndex) {
        textColorIndex = random.nextInt(colors.length);
      }
      
      int wordNameIndex = random.nextInt(colorNames.length);

      // Ensure word doesn't match text color for most items
      while (wordNameIndex == textColorIndex && count > 1) {
        wordNameIndex = random.nextInt(colorNames.length);
      }

      items.add(
        StroopItemV2(
          textColor: colors[textColorIndex],
          displayWord: colorNames[wordNameIndex],
          correctSymbol: colorSymbols[textColorIndex],
        ),
      );
      
      previousColorIndex = textColorIndex;
    }

    return items;
  }
  
  int _calculatePointsForAnswer(bool isCorrect) {
    // Fixed points: 1000 / 25 words = 40 points per word
    // Correct: 40 points
    // Wrong: 0 points
    int awardedPoints = isCorrect ? basePointsPerWord : 0;
    
    // Store debug info
    lastPointsAwarded = awardedPoints;
    lastTimeElapsedMs = 0;
    lastDeduction = 0;
    
    return awardedPoints;
  }
  
  void _showPointsAnimation(int points) {
    try {
      // Check if points system is enabled
      final pointsSystemEnabled = ref.watch(pointsSystemEnabledProvider);
      if (!pointsSystemEnabled) {
        return;
      }
      
      // Show points animation just above the test word (appears to spawn from word)
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final wordPosition = Offset(screenSize.width / 2, screenSize.height * 0.30);
        
        PointsCollectedWidget.show(
          context: context,
          points: points,
          position: wordPosition,
          fontSize: 60,
          color: points == 0 ? AppColors.errorRed : null,
        );
      }
    } catch (e) {
      debugPrint('Error showing points animation: $e');
    }
  }

  void _onButtonPressed(IconData symbol) async {
    if (testComplete || _isProcessing) return;

    _isProcessing = true;
    final currentItem = stroopItems[currentIndex];
    final isCorrect = symbol == currentItem.correctSymbol;

    setState(() {
      feedbackSymbol = symbol;
      feedbackColor = isCorrect ? AppColors.successGreen : AppColors.errorRed;
    });

    _feedbackController.reset();
    await _feedbackController.forward();

    if (!mounted) return;

    // Calculate points for this answer
    final pointsAwarded = _calculatePointsForAnswer(isCorrect);
    
    // Add points to session
    ref.read(sessionPointsProvider.notifier).addPoints(pointsAwarded);
    
    // Show animation
    _showPointsAnimation(pointsAwarded);

    setState(() {
      if (isCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }

      if (currentIndex < stroopItems.length - 1) {
        currentIndex++;  // Update item FIRST, before animation
        _wordTransitionController.reset();
        _wordTransitionController.forward();
        _isProcessing = false;
      } else {
        _isProcessing = false;
        // Test is complete - finish immediately without showing result screen
        Future.microtask(() {
          if (mounted) {
            _finishTest();
          }
        });
      }
    });

    if (mounted) {
      setState(() {
        feedbackSymbol = null;
        feedbackColor = null;
      });
    }
  }

  void _finishTest() {
    final currentSessionPoints = ref.read(sessionPointsProvider);
    final pointsEarned = currentSessionPoints - startingSessionPoints;
    
    final testData = {
      'total_words': numberOfWords,
      'correct': correctCount,
      'wrong': wrongCount,
      'accuracy': numberOfWords > 0 ? (correctCount / numberOfWords * 100).toStringAsFixed(1) : '0.0',
      'pointsEarned': pointsEarned,
    };

    widget.onTestResult?.call(testData, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorSymbols = StroopColorConstantsV2.colorSymbols;
    return TestShell(
      child: StroopScreenV2(
        progressText: '${currentIndex + 1}/$numberOfWords',
        middleContent: StroopWordDisplayV2(
          word: stroopItems[currentIndex].displayWord,
          style: TextStyle(
            fontSize: StroopLayoutV2.test.middleTextSize,
            fontWeight: FontWeight.bold,
            color: stroopItems[currentIndex].textColor,
          ),
          animationController: _wordTransitionController,
        ),
        buttons: [
          for (final symbol in colorSymbols)
            FeedbackStroopButtonV2(
              symbol: symbol,
              backgroundColor: AppColors.grey700,
              onPressed: () => _onButtonPressed(symbol),
              feedbackController: _feedbackController,
              feedbackSymbol: feedbackSymbol,
              feedbackColor: feedbackColor,
              size: StroopLayoutV2.unifiedButtonSize,
            ),
        ],
        bottomButton: null,
        onAbort: widget.onAbort,
      ),
    );
  }

}

/// Intermediate screen between tutorial and test
class StroopIntermediateScreenV2 extends ConsumerWidget {
  final VoidCallback onReplay;
  final VoidCallback onStartTest;
  final VoidCallback? onAbort;

  const StroopIntermediateScreenV2({
    super.key,
    required this.onReplay,
    required this.onStartTest,
    this.onAbort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    
    return RoundInfoScreen(
      title: strings.round2,
      subtitle: strings.stroopTest,
      bodyText: strings.lookAtColorNotWord,
      bottomContent: BottomButtonBar(
        actionButtons: [
          BottomButton(
            label: strings.retry,
            onPressed: onReplay,
            icon: Icons.refresh,
          ),
          BottomButton(
            label: strings.start,
            onPressed: onStartTest,
            icon: Icons.play_arrow,
          ),
        ],
        onAbort: onAbort,
        showAbortButton: false,
        useRow: true,
      ),
    );
  }
}
