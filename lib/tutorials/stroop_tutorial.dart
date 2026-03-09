import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers.dart';

/// Tutorial screen for Stroop Test
class StroopTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;

  const StroopTutorial({super.key, required this.onComplete, this.onAbort});

  @override
  State<StroopTutorial> createState() => _StroopTutorialState();
}

class _StroopTutorialState extends State<StroopTutorial> {
  int stage = 0;
  int correctAnswersInStage = 0;
  final int answersNeededPerStage = 2;
  late List<StroopItem> currentItems;
  int currentItemIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeStage();
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

    // Create simple items where word color and word name match for easier learning
    final items = <StroopItem>[];
    for (int i = 0; i < answersNeededPerStage; i++) {
      final colorIndex = i % colors.length;
      items.add(
        StroopItem(
          textColor: colors[colorIndex],
          displayWord: colorNames[colorIndex],
          correctLetter: colorLetters[colorIndex],
        ),
      );
    }
    return items;
  }

  void _onButtonPressed(String letter) {
    if (currentItemIndex >= currentItems.length) return;

    final currentItem = currentItems[currentItemIndex];
    if (letter == currentItem.correctLetter) {
      setState(() {
        correctAnswersInStage++;
        if (correctAnswersInStage >= answersNeededPerStage) {
          // Move to next stage
          if (stage < 2) {
            stage++;
            _initializeStage();
          } else {
            // Tutorial complete
            widget.onComplete();
          }
        } else {
          currentItemIndex++;
        }
      });
    }
  }

  Widget _buildButton(String letter, Color bgColor, String? label) {
    return StroopColorButton(
      letter: letter,
      backgroundColor: bgColor,
      label: label,
      size: StroopLayout.tutorial.buttonSize,
      onPressed: () => _onButtonPressed(letter),
    );
  }

  String _getStageTitle() {
    switch (stage) {
      case 0:
        return 'Stage 1: Learn the buttons';
      case 1:
        return 'Stage 2: Remember the colors';
      case 2:
        return 'Stage 3: Pure challenge';
      default:
        return '';
    }
  }

  String _getStageInstruction() {
    switch (stage) {
      case 0:
        return 'Press the button matching the COLOR of the word';
      case 1:
        return 'The colors are gone—do you remember which is which?';
      case 2:
        return 'Now press the button for the word\'s COLOR';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentItemIndex >= currentItems.length) {
      return TestShell(
        title: 'Stroop Test - Tutorial',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stage < 2 ? 'Great! Moving on...' : 'You\'ve got it!',
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
                  } else {
                    widget.onComplete();
                  }
                }),
                child: const Text('Continue'),
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
      title: 'Stroop Test - Tutorial',
      child: StroopScreen(
        progressText: '${currentItemIndex + 1}/$answersNeededPerStage',
        middleContent: Text(
          currentItem.displayWord,
          style: TextStyle(
            fontSize: StroopLayout.tutorial.middleTextSize,
            fontWeight: FontWeight.bold,
            color: currentItem.textColor,
          ),
        ),
        buttons: [
          for (int i = 0; i < colorLetters.length; i++)
            _buildButton(
              colorLetters[i],
              stage == 0 ? colors[i] : Colors.grey[700]!,
              stage == 0 ? colorNames[i] : null,
            ),
        ],
        onAbort: widget.onAbort,
      ),
    );
  }
}
