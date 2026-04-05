import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/tutorials/stroop_tutorial.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/points_collected_widget.dart';

// Quick ref.watch helper for tests
final stroopTest = TestDefinition(
  id: 'Stroop Test',
  title: 'Farger',
  icon: Icons.color_lens,
  build: (context, run) => StroopTestScreen(run: run),
);

class StroopTestScreen extends ConsumerStatefulWidget {
  final TestRunContext run;
  const StroopTestScreen({super.key, required this.run});

  @override
  ConsumerState<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends ConsumerState<StroopTestScreen> {
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
        return StroopTutorial(
          onComplete: () {
            setState(() => stage = 1);
          },
          onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
        );
      case 1:
        return TestShell(
          child: StroopIntermediateScreen(
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
        return StroopTest(
          run: widget.run,
          stageName: 'stroop_test',
          onTestResult: (result, completed) {
            _saveTestResult('stroop_test', result, completed);
            final pointsEarned = (result['pointsEarned'] as int?) ?? 0;
            widget.run.complete(
              TestResult(
                testId: 'stroop',
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

class StroopTest extends ConsumerStatefulWidget {
  final TestRunContext run;
  final String stageName;
  final Function(dynamic, bool)? onTestResult;
  final VoidCallback? onAbort;

  const StroopTest({
    super.key,
    required this.run,
    this.stageName = 'stroop_test',
    this.onTestResult,
    this.onAbort,
  });

  @override
  ConsumerState<StroopTest> createState() => _StroopTestState();
}

class _StroopTestState extends ConsumerState<StroopTest> with TickerProviderStateMixin {
  final int numberOfWords = 25; // Configurable number of trials
  
  late List<StroopItem> stroopItems;
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool testComplete = false;

  // Feedback state
  String? feedbackLetter;
  Color? feedbackColor;
  late AnimationController _feedbackController;
  late AnimationController _wordTransitionController;
  bool _isProcessing = false;
  
  // Points tracking
  int startingSessionPoints = 0;
  late int basePointsPerWord;
  DateTime? wordStartTime;
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
    
    // Start timer for first word
    wordStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _wordTransitionController.dispose();
    super.dispose();
  }

  List<StroopItem> _generateStroopItems(int count) {
    final colors = StroopColorConstants.colors;
    final colorNames = StroopColorConstants.colorNames;
    final colorLetters = StroopColorConstants.colorLetters;

    final random = Random();
    final List<StroopItem> items = [];
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
        StroopItem(
          textColor: colors[textColorIndex],
          displayWord: colorNames[wordNameIndex],
          correctLetter: colorLetters[textColorIndex],
        ),
      );
      
      previousColorIndex = textColorIndex;
    }

    return items;
  }
  
  int _calculatePointsForAnswer(bool isCorrect) {
    if (wordStartTime == null) return 0;
    
    final now = DateTime.now();
    final timeElapsedMs = now.difference(wordStartTime!).inMilliseconds;
    const Duration quarterSecond = Duration(milliseconds: 250);
    
    // Time penalty: -1 point for every 250ms
    int deduction = (timeElapsedMs / quarterSecond.inMilliseconds).floor();
    
    int awardedPoints;
    if (isCorrect) {
      // Correct: full base points minus time penalty
      awardedPoints = (basePointsPerWord - deduction).clamp(0, basePointsPerWord);
    } else {
      // Wrong: fixed 50% penalty, no time deduction
      int wrongPenalty = (basePointsPerWord * 0.5).ceil();
      awardedPoints = -wrongPenalty; // Fixed negative penalty
    }
    
    // Store debug info
    lastPointsAwarded = awardedPoints;
    lastTimeElapsedMs = timeElapsedMs;
    lastDeduction = deduction;
    
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
          color: points < 0 ? AppColors.errorRed : null,
        );
      }
    } catch (e) {
      debugPrint('Error showing points animation: $e');
    }
  }

  void _onButtonPressed(String letter) async {
    if (testComplete || _isProcessing) return;

    _isProcessing = true;
    final currentItem = stroopItems[currentIndex];
    final isCorrect = letter == currentItem.correctLetter;

    setState(() {
      feedbackLetter = letter;
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
        wordStartTime = DateTime.now(); // Reset timer for next word
        _wordTransitionController.reset();
        _wordTransitionController.forward();
        _isProcessing = false;
      } else {
        testComplete = true;
        _isProcessing = false;
      }
    });

    if (mounted) {
      setState(() {
        feedbackLetter = null;
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
    final strings = ref.watch(appStringsProvider);
    if (testComplete) {
      return TestShell(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      strings.testComplete,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${strings.correctLabel}: $correctCount\n${strings.wrongLabel}: $wrongCount',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            BottomButtonBar(
              primaryButton: BottomButton(
                label: strings.done,
                onPressed: _finishTest,
              ),
              onAbort: null,
              showAbortButton: false,
            ),
          ],
        ),
      );
    }

    return TestShell(
      child: StroopScreen(
        progressText: '${currentIndex + 1}/$numberOfWords',
        middleContent: StroopWordDisplay(
          word: stroopItems[currentIndex].displayWord,
          style: TextStyle(
            fontSize: StroopLayout.test.middleTextSize,
            fontWeight: FontWeight.bold,
            color: stroopItems[currentIndex].textColor,
          ),
          animationController: _wordTransitionController,
        ),
        buttons: [
          for (final letter in StroopColorConstants.colorLetters)
            FeedbackStroopButton(
              letter: letter,
              backgroundColor: AppColors.grey700,
              onPressed: () => _onButtonPressed(letter),
              feedbackController: _feedbackController,
              feedbackLetter: feedbackLetter,
              feedbackColor: feedbackColor,
              size: StroopLayout.unifiedButtonSize,
            ),
        ],
        bottomButton: null,
        onAbort: widget.onAbort,
      ),
    );
  }

}
