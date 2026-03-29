import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';

final counterTest = TestDefinition(
  id: 'Counter Test',
  title: 'Telling',
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
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Teller: $counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => counter++),
                    child: const Text('Øk'),
                  ),
                ],
              ),
            ),
          ),
          BottomButtonBar(
            primaryButton: BottomButton(
              label: 'Fullfør',
              onPressed: () {
                widget.run.complete(
                  TestResult(testId: 'counter', summary: {'counter': counter}),
                );
              },
              type: BottomButtonType.filled,
              icon: Icons.check_circle,
            ),
            colorSet: counter > 0 
              ? BottomBarColorSet.secondary 
              : BottomBarColorSet.primary,
            onAbort: () => widget.run.abort('User aborted'),
            showAbortButton: false, // Set to true to show in normal layout, or use debugMode: true
            // debugMode: true, // Uncomment to show abort button in bottom-right corner
            onSkip: () {
              widget.run.complete(
                TestResult(testId: 'counter', summary: {'counter': 0}),
              );
            },
          ),
        ],
      ),
    );
  }
}
