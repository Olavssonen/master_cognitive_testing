import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/providers/test_providers.dart';

final counterTest = TestDefinition(
  id: 'Counter Test',
  title: 'Count',
  icon: Icons.exposure_plus_1,
  build: (context, run) => CounterTestScreen(run: run),
);

class CounterTestScreen extends ConsumerStatefulWidget {
  final TestRunContext run;
  const CounterTestScreen({super.key, required this.run});

  @override
  ConsumerState<CounterTestScreen> createState() => _CounterTestScreenState();
}

class _CounterTestScreenState extends ConsumerState<CounterTestScreen> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isDebugMode = ref.watch(debugModeProvider);
    
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
              label: strings.done,
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
            onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
            showAbortButton: false,
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
