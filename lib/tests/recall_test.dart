import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';

final recallTest = TestDefinition(
  id: 'recall',
  title: 'Recall Test',
  icon: Icons.exposure_plus_1,
  build: (context, run) => RecallTestScreen(run: run),
);

class RecallTestScreen extends StatefulWidget {
  final TestRunContext run;
  const RecallTestScreen({super.key, required this.run});

  @override
  State<RecallTestScreen> createState() => _RecallTestScreenState();
}

class _RecallTestScreenState extends State<RecallTestScreen> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Recall Test',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Counter: $counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                widget.run.complete(
                  TestResult(testId: 'counter', summary: {'counter': counter}),
                );
              },
              child: const Text('Finish'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => widget.run.abort('User aborted'),
              child: const Text('Abort'),
            ),
          ],
        ),
      ),
    );
  }
}
