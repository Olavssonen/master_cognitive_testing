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
  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Stroop Test',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Stroop Test Implementation Area',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: () {
                    widget.onTestResult?.call({}, true);
                  },
                  child: const Text('Finish'),
                ),
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
}
