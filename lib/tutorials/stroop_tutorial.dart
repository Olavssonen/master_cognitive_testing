import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

/// Tutorial screen for Stroop Test
class StroopTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;

  const StroopTutorial({super.key, required this.onComplete, this.onAbort});

  @override
  State<StroopTutorial> createState() => _StroopTutorialState();
}

class _StroopTutorialState extends State<StroopTutorial>
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

  List<StroopItem> _generateTutorialItems() {
    final colors = StroopColorConstants.colors;
    final colorNames = StroopColorConstants.colorNames;
    final colorLetters = StroopColorConstants.colorLetters;
    final items = <StroopItem>[];

    if (stage == 0) {
      // Stage 0: All colors in order, word matches color
      for (int i = 0; i < 4; i++) {
        items.add(
          StroopItem(
            textColor: colors[i],
            displayWord: colorNames[i],
            correctLetter: colorLetters[i],
          ),
        );
      }
    } else if (stage == 1) {
      // Stage 1: All colors in random order, word matches color
      final indices = [0, 1, 2, 3];
      indices.shuffle();
      for (final i in indices) {
        items.add(
          StroopItem(
            textColor: colors[i],
            displayWord: colorNames[i],
            correctLetter: colorLetters[i],
          ),
        );
      }
    } else {
      // Stage 2: Random mismatched items (like real test)
      final random = DateTime.now().millisecond;
      for (int i = 0; i < 4; i++) {
        int textColorIndex = (random + i) % colors.length;
        int wordNameIndex = (random + i * 2) % colorNames.length;

        // Ensure word doesn't match text color
        while (wordNameIndex == textColorIndex) {
          wordNameIndex = (wordNameIndex + 1) % colorNames.length;
        }

        items.add(
          StroopItem(
            textColor: colors[textColorIndex],
            displayWord: colorNames[wordNameIndex],
            correctLetter: colorLetters[textColorIndex],
          ),
        );
      }
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
          if (stage < 2) {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Stroop Fargetest',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Se på fargen på teksten, ikke ordet som er skrevet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => setState(() => showIntroduction = false),
                child: const Text('Start veiledning'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentItemIndex >= currentItems.length) {
      return TestShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stage < 2 ? 'Bra! Går videre...' : 'Du skjønner det!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => setState(() {
                  if (stage < 2) {
                    stage++;
                    _initializeStage();
                    _wordTransitionController.reset();
                    _wordTransitionController.forward();
                  } else {
                    widget.onComplete();
                  }
                }),
                child: const Text('Fortsett'),
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
              backgroundColor: stage == 2 ? AppColors.grey700 : colors[i],
              label: stage == 0 ? colorNames[i] : null,
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
