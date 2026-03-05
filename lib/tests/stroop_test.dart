import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
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
    final List<Color> colors = [
      const Color(0xFFD32F2F), // Red
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFFBC02D), // Yellow
    ];

    final List<String> colorNames = ['rød', 'blå', 'grønt', 'gul'];
    final List<String> colorLetters = ['Ø', 'L', 'R', 'U'];

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
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              '${currentIndex + 1}/$numberOfWords',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Center(
              child: !testComplete
                  ? Text(
                      stroopItems[currentIndex].displayWord,
                      style: TextStyle(
                        fontSize: 64,
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: !testComplete
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildColorButton('Ø'),
                      _buildColorButton('L'),
                      _buildColorButton('R'),
                      _buildColorButton('U'),
                    ],
                  )
                : const SizedBox(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (testComplete)
                  OutlinedButton(
                    onPressed: _finishTest,
                    child: const Text('Submit Results'),
                  )
                else
                  const SizedBox(),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onAbort,
                  child: const Text('Abort'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(String letter) {
    return SizedBox(
      width: 80,
      height: 80,
      child: FilledButton(
        onPressed: () => _onButtonPressed(letter),
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class StroopItem {
  final Color textColor;
  final String displayWord;
  final String correctLetter;

  StroopItem({
    required this.textColor,
    required this.displayWord,
    required this.correctLetter,
  });
}
