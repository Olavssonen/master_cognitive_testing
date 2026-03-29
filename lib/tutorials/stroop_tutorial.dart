import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers.dart';
import 'package:flutter_master_app/widgets/round_info_screen.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';

/// Tutorial screen for Stroop Test
class StroopTutorial extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;

  const StroopTutorial({super.key, required this.onComplete, this.onAbort});

  @override
  ConsumerState<StroopTutorial> createState() => _StroopTutorialState();
}

class _StroopTutorialState extends ConsumerState<StroopTutorial>
    with TickerProviderStateMixin {
  int stage = 0;
  int correctAnswersInStage = 0;
  final int answersNeededPerStage = 4;
  late List<StroopItem> currentItems;
  int currentItemIndex = 0;
  bool showIntroduction = true;

  // Feedback state
  String? feedbackLetter;
  Color? feedbackColor;
  late AnimationController _feedbackController;
  late AnimationController _wordTransitionController;
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
    _wordTransitionController.forward(); // Prime it so first word shows
    _initializeStage();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _wordTransitionController.dispose();
    super.dispose();
  }

  void _initializeStage() {
    currentItems = _generateTutorialItems();
    currentItemIndex = 0;
    correctAnswersInStage = 0;
  }

  String? _getButtonLabel(int colorIndex) {
    final colorNames = StroopColorConstants.colorNames;
    final colorLetters = StroopColorConstants.colorLetters;
    
    if (stage == 0) {
      // Stage 0: Full word with colored buttons - RØD, BLÅ, GRØNN, GUL
      return colorNames[colorIndex];
    } else if (stage == 1) {
      // Stage 1: Full word with grey buttons - RØD, BLÅ, GRØNN, GUL
      return colorNames[colorIndex];
    } else if (stage == 2) {
      // Stage 2: Without last letter(s) - RØ, BL, GR, GU
      final abbreviations = ['RØ', 'BL', 'GR', 'GU'];
      return abbreviations[colorIndex];
    } else {
      // Stage 3: Only first letter - Ø, L, R, U (return null to show letter)
      return null;
    }
  }

  List<StroopItem> _generateTutorialItems() {
    final colors = StroopColorConstants.colors;
    final colorNames = StroopColorConstants.colorNames;
    final colorLetters = StroopColorConstants.colorLetters;
    final items = <StroopItem>[];
    final random = Random();

    // All stages: Ensure each color appears exactly once with mismatched words
    // This ensures user must press all 4 buttons per tutorial part
    
    // Shuffle colors to randomize the order they appear
    final shuffledColorIndices = List<int>.generate(colors.length, (i) => i);
    shuffledColorIndices.shuffle(random);
    
    for (int i = 0; i < 4; i++) {
      final colorIndex = shuffledColorIndices[i];
      
      // Select a word that doesn't match the color
      int wordIndex = random.nextInt(colorNames.length);
      while (wordIndex == colorIndex) {
        wordIndex = random.nextInt(colorNames.length);
      }
      
      items.add(
        StroopItem(
          textColor: colors[colorIndex],
          displayWord: colorNames[wordIndex],
          correctLetter: colorLetters[colorIndex],
        ),
      );
    }

    return items;
  }

  void _onButtonPressed(String letter) async {
    if (currentItemIndex >= currentItems.length || _isProcessing) return;

    _isProcessing = true;
    final currentItem = currentItems[currentItemIndex];
    final isCorrect = letter == currentItem.correctLetter;

    setState(() {
      feedbackLetter = letter;
      feedbackColor = isCorrect ? AppColors.successGreen : AppColors.errorRed;
    });

    _feedbackController.reset();
    await _feedbackController.forward();

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        correctAnswersInStage++;
        if (correctAnswersInStage >= answersNeededPerStage) {
          // Progress to next stage
          if (stage < 3) {
            stage++;
            _initializeStage();
            _wordTransitionController.reset();
            _wordTransitionController.forward();
            feedbackLetter = null;
            feedbackColor = null;
            _isProcessing = false;
          } else {
            // Tutorial complete
            _isProcessing = false;
            widget.onComplete();
          }
        } else {
          currentItemIndex++;  // Update item FIRST, before animation
          _wordTransitionController.reset();
          _wordTransitionController.forward();
          _isProcessing = false;
        }
      });
      
      if (mounted) {
        setState(() {
          feedbackLetter = null;
          feedbackColor = null;
        });
      }
    } else {
      // Wrong answer - show feedback but don't progress
      setState(() {
        _wordTransitionController.reset();
        _wordTransitionController.forward();
        _isProcessing = false;
      });
      
      if (mounted) {
        setState(() {
          feedbackLetter = null;
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
              onPressed: () => setState(() => showIntroduction = false),
            ),
            onAbort: null,
            showAbortButton: false,
            colorSet: BottomBarColorSet.secondary,
          ),
        ),
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
                stage < 3 ? strings.great : strings.gotIt,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => setState(() {
                  if (stage < 3) {
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
    final colors = StroopColorConstants.colors;
    final colorLetters = StroopColorConstants.colorLetters;
    final colorNames = StroopColorConstants.colorNames;

    return TestShell(
      child: StroopScreen(
        progressText: '${currentItemIndex + 1}/$answersNeededPerStage',
        middleContent: StroopWordDisplay(
          word: currentItem.displayWord,
          style: TextStyle(
            fontSize: StroopLayout.tutorial.middleTextSize,
            fontWeight: FontWeight.bold,
            color: currentItem.textColor,
          ),
          animationController: _wordTransitionController,
        ),
        buttons: [
          for (int i = 0; i < colorLetters.length; i++)
            FeedbackStroopButton(
              letter: colorLetters[i],
              backgroundColor: stage >= 1 ? AppColors.grey700 : colors[i],
              label: _getButtonLabel(i),
              size: StroopLayout.unifiedButtonSize,
              onPressed: () => _onButtonPressed(colorLetters[i]),
              feedbackController: _feedbackController,
              feedbackLetter: feedbackLetter,
              feedbackColor: feedbackColor,
            ),
        ],
        onAbort: widget.onAbort,
      ),
    );
  }
}
