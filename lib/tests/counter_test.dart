import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';

final counterTest = TestDefinition(
  id: 'counter',
  title: 'Counter Test',
  icon: Icons.exposure_plus_1,
  build: (context, run) => CounterTestScreen(run: run),
);

class CounterTestScreen extends StatefulWidget {
  final TestRunContext run;
  const CounterTestScreen({super.key, required this.run});

  @override
  State<CounterTestScreen> createState() => _CounterTestScreenState();
}

class _CounterTestScreenState extends State<CounterTestScreen> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return TestShell(
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
