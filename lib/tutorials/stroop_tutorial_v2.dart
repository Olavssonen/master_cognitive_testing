import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers_v2.dart';
import 'package:flutter_master_app/widgets/round_info_screen.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';

/// Tutorial screen for Stroop Test V2 (with symbols)
class StroopTutorialV2 extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;

  const StroopTutorialV2({super.key, required this.onComplete, this.onAbort});

  @override
  ConsumerState<StroopTutorialV2> createState() => _StroopTutorialStateV2();
}

class _StroopTutorialStateV2 extends ConsumerState<StroopTutorialV2>
    with TickerProviderStateMixin {
  int stage = 0;
  int correctAnswersInStage = 0;
  final int answersNeededPerStage = 8;
  late List<StroopItemV2> currentItems;
  int currentItemIndex = 0;
  bool showIntroduction = true;
  bool showExamples = false;
  bool showButtonGuidance = true;
  int consecutiveWrongAnswers = 0;

  // Feedback state
  IconData? feedbackSymbol;
  Color? feedbackColor;
  late AnimationController _feedbackController;
  late AnimationController _wordTransitionController;
  late AnimationController _guidanceArrowController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _wordTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _guidanceArrowController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat();
    _wordTransitionController.forward(); // Prime it so first word shows
    _initializeStage();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _wordTransitionController.dispose();
    _guidanceArrowController.dispose();
    super.dispose();
  }

  void _initializeStage() {
    currentItems = _generateTutorialItems();
    currentItemIndex = 0;
    correctAnswersInStage = 0;
    showButtonGuidance = true;
    consecutiveWrongAnswers = 0;
  }

  List<StroopItemV2> _generateTutorialItems() {
    final colors = StroopColorConstantsV2.colors;
    final strings = ref.read(appStringsProvider);
    final colorNames = StroopColorConstantsV2.getColorNames(
      strings.colorRed.toUpperCase(),
      strings.colorBlue.toUpperCase(),
      strings.colorGreen.toUpperCase(),
      strings.colorYellow.toUpperCase(),
    );
    final colorSymbols = StroopColorConstantsV2.colorSymbols;
    final items = <StroopItemV2>[];
    final random = Random();

    // Build an 8-item sequence for each tutorial part.
    // First guarantee each color appears once, then add four more items
    // while avoiding consecutive repeats.
    final colorSequence = <int>[];

    final shuffledColorIndices = List<int>.generate(colors.length, (i) => i)
      ..shuffle(random);
    colorSequence.addAll(shuffledColorIndices);

    while (colorSequence.length < 8) {
      final previousColorIndex = colorSequence.last;
      final availableColorIndices = List<int>.generate(
        colors.length,
        (i) => i,
      ).where((index) => index != previousColorIndex).toList()..shuffle(random);
      colorSequence.add(availableColorIndices.first);
    }

    for (final colorIndex in colorSequence) {
      // Select a word that doesn't match the color
      int wordIndex = random.nextInt(colorNames.length);
      while (wordIndex == colorIndex) {
        wordIndex = random.nextInt(colorNames.length);
      }

      items.add(
        StroopItemV2(
          textColor: colors[colorIndex],
          displayWord: colorNames[wordIndex],
          correctSymbol: colorSymbols[colorIndex],
        ),
      );
    }

    return items;
  }

  void _onButtonPressed(IconData symbol) async {
    if (currentItemIndex >= currentItems.length || _isProcessing) return;

    _isProcessing = true;
    final currentItem = currentItems[currentItemIndex];
    final isCorrect = symbol == currentItem.correctSymbol;

    setState(() {
      feedbackSymbol = symbol;
      feedbackColor = isCorrect ? AppColors.successGreen : AppColors.errorRed;
    });

    _feedbackController.reset();
    await _feedbackController.forward();

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        correctAnswersInStage++;
        showButtonGuidance = false;
        consecutiveWrongAnswers = 0;
        if (correctAnswersInStage >= answersNeededPerStage) {
          // Progress to next stage
          if (stage < 1) {
            // Only 2 stages (0 and 1) for V2
            stage++;
            _initializeStage();
            _wordTransitionController.reset();
            _wordTransitionController.forward();
            feedbackSymbol = null;
            feedbackColor = null;
            _isProcessing = false;
          } else {
            // Tutorial complete
            _isProcessing = false;
            widget.onComplete();
          }
        } else {
          currentItemIndex++; // Update item FIRST, before animation
          _wordTransitionController.reset();
          _wordTransitionController.forward();
          _isProcessing = false;
        }
      });

      if (mounted) {
        setState(() {
          feedbackSymbol = null;
          feedbackColor = null;
        });
      }
    } else {
      // Wrong answer - show feedback but don't progress
      setState(() {
        if (!showButtonGuidance) {
          consecutiveWrongAnswers++;
          if (consecutiveWrongAnswers >= 2) {
            showButtonGuidance = true;
            consecutiveWrongAnswers = 0;
          }
        }
        _wordTransitionController.reset();
        _wordTransitionController.forward();
        _isProcessing = false;
      });

      if (mounted) {
        setState(() {
          feedbackSymbol = null;
          feedbackColor = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show introduction screen first
    if (showIntroduction) {
      return TestShell(
        child: RoundInfoScreen(
          title: ref.watch(appStringsProvider).round1,
          subtitle: ref.watch(appStringsProvider).stroopTest,
          bodyText: ref.watch(appStringsProvider).lookAtColorNotWord,
          bottomContent: BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).start,
              icon: Icons.play_arrow,
              onPressed: () => setState(() {
                showIntroduction = false;
                showExamples = true;
              }),
            ),
            onAbort: null,
            showAbortButton: false,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
      );
    }

    // Show examples screen
    if (showExamples) {
      return StroopExampleScreenV2(
        onContinue: () => setState(() => showExamples = false),
      );
    }

    if (currentItemIndex >= currentItems.length) {
      final strings = ref.watch(appStringsProvider);
      return TestShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stage < 1 ? strings.great : strings.gotIt,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => setState(() {
                  if (stage < 1) {
                    stage++;
                    _initializeStage();
                    _wordTransitionController.reset();
                    _wordTransitionController.forward();
                  } else {
                    widget.onComplete();
                  }
                }),
                child: Text(strings.continueTutorial),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = currentItems[currentItemIndex];
    final colors = StroopColorConstantsV2.colors;
    final colorSymbols = StroopColorConstantsV2.colorSymbols;
    final strings = ref.watch(appStringsProvider);

    return TestShell(
      child: StroopScreenV2(
        progressText: '${currentItemIndex + 1}/$answersNeededPerStage',
        middleContent: StroopWordDisplayV2(
          word: currentItem.displayWord,
          style: TextStyle(
            fontSize: StroopLayoutV2.tutorial.middleTextSize,
            fontWeight: FontWeight.bold,
            color: currentItem.textColor,
          ),
          animationController: _wordTransitionController,
        ),
        buttons: [
          for (int i = 0; i < colorSymbols.length; i++)
            SizedBox(
              width: StroopLayoutV2.unifiedButtonSize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showButtonGuidance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorSymbols[i] == currentItem.correctSymbol
                                  ? AppColors.successGreen.withOpacity(0.2)
                                  : AppColors.errorRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    colorSymbols[i] == currentItem.correctSymbol
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                                width: 2,
                              ),
                            ),
                            child: SizedBox(
                              height: 30,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  colorSymbols[i] == currentItem.correctSymbol
                                      ? strings.correctOption
                                      : strings.wrongOption,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        colorSymbols[i] ==
                                            currentItem.correctSymbol
                                        ? AppColors.successGreen
                                        : AppColors.errorRed,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _guidanceArrowController,
                            child: Icon(
                              Icons.keyboard_double_arrow_down,
                              color:
                                  colorSymbols[i] == currentItem.correctSymbol
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                              size: 36,
                            ),
                            builder: (context, child) {
                              final wave =
                                  (sin(
                                        _guidanceArrowController.value * pi * 2,
                                      ) +
                                      1) /
                                  2;
                              return Transform.translate(
                                offset: Offset(0, 10 * wave),
                                child: Opacity(
                                  opacity: 0.35 + (0.65 * wave),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  FeedbackStroopButtonV2(
                    symbol: colorSymbols[i],
                    backgroundColor: stage >= 1 ? AppColors.grey700 : colors[i],
                    size: StroopLayoutV2.unifiedButtonSize,
                    onPressed: () => _onButtonPressed(colorSymbols[i]),
                    feedbackController: _feedbackController,
                    feedbackSymbol: feedbackSymbol,
                    feedbackColor: feedbackColor,
                  ),
                ],
              ),
            ),
        ],
        onAbort: widget.onAbort,
      ),
    );
  }
}
