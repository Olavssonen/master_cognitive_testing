import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/stroop_helpers.dart';
import 'package:flutter_master_app/tutorials/stroop_tutorial.dart';

final stroopTest = TestDefinition(
  id: 'stroop',
  title: 'Stroop Test',
  icon: Icons.color_lens,
  build: (context, run) => StroopTestScreen(run: run),
);

class StroopTestScreen extends StatefulWidget {
  final TestRunContext run;
  const StroopTestScreen({super.key, required this.run});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  int stage = 0;
  final Map<String, dynamic> stageResults = {};

  void _saveTestResult(
      String stageName, dynamic result, bool completed) {
    stageResults[stageName] = {
      'completed': completed,
      'result': result,
    };
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case 0:
        return StroopTutorial(
          onComplete: () {
            setState(() => stage = 1);
          },
          onAbort: () => widget.run.abort('User aborted'),
        );
      case 1:
        return StroopTest(
          run: widget.run,
          stageName: 'stroop_test',
          onTestResult: (result, completed) {
            _saveTestResult('stroop_test', result, completed);
            widget.run.complete(
              TestResult(
                testId: 'stroop',
                summary: {
                  'progression_completed': true,
                  'all_stages': stageResults,
                },
              ),
            );
          },
          onAbort: () => widget.run.abort('User aborted'),
        );
      default:
        return const SizedBox();
    }
  }
}

class StroopTest extends StatefulWidget {
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
  State<StroopTest> createState() => _StroopTestState();
}

class _StroopTestState extends State<StroopTest> {
  final int numberOfWords = 4; // Configurable number of trials
  
  late List<StroopItem> stroopItems;
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool testComplete = false;

  @override
  void initState() {
    super.initState();
    stroopItems = _generateStroopItems(numberOfWords);
  }

  List<StroopItem> _generateStroopItems(int count) {
    final colors = StroopColorConstants.colors;
    final colorNames = StroopColorConstants.colorNames;
    final colorLetters = StroopColorConstants.colorLetters;

    final random = DateTime.now().millisecond;
    final List<StroopItem> items = [];

    for (int i = 0; i < count; i++) {
      int textColorIndex = (random + i) % colors.length;
      int wordNameIndex = (random + i * 2) % colorNames.length;

      // Ensure word doesn't match text color for most items
      while (wordNameIndex == textColorIndex && count > 1) {
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

    return items;
  }

  void _onButtonPressed(String letter) {
    if (testComplete) return;

    final currentItem = stroopItems[currentIndex];
    final isCorrect = letter == currentItem.correctLetter;

    setState(() {
      if (isCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }

      if (currentIndex < stroopItems.length - 1) {
        currentIndex++;
      } else {
        testComplete = true;
      }
    });
  }

  void _finishTest() {
    final testData = {
      'total_words': numberOfWords,
      'correct': correctCount,
      'wrong': wrongCount,
      'accuracy': numberOfWords > 0 ? (correctCount / numberOfWords * 100).toStringAsFixed(1) : '0.0',
    };

    widget.onTestResult?.call(testData, true);
  }

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Stroop Test',
      child: StroopScreen(
        progressText: '${currentIndex + 1}/$numberOfWords',
        middleContent: !testComplete
            ? Text(
                stroopItems[currentIndex].displayWord,
                style: TextStyle(
                  fontSize: StroopLayout.test.middleTextSize,
                  fontWeight: FontWeight.bold,
                  color: stroopItems[currentIndex].textColor,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Test Complete!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Correct: $correctCount\nWrong: $wrongCount',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        buttons: !testComplete
            ? [
                for (final letter in StroopColorConstants.colorLetters)
                  StroopColorButton(
                    letter: letter,
                    backgroundColor: Colors.grey[700]!,
                    onPressed: () => _onButtonPressed(letter),
                    size: StroopLayout.tutorial.buttonSize,
                  ),
              ]
            : [],
        bottomButton: testComplete
            ? OutlinedButton(
                onPressed: _finishTest,
                child: const Text('Submit Results'),
              )
            : null,
        onAbort: widget.onAbort,
      ),
    );
  }

}
