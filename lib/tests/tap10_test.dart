import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/providers/test_providers.dart';

final tap10Test = TestDefinition(
  id: 'Trykk 10 Test',
  title: 'Trykking',
  icon: Icons.touch_app,
  build: (context, run) => Tap10TestScreen(run: run),
);

class Tap10TestScreen extends ConsumerStatefulWidget {
  final TestRunContext run;
  const Tap10TestScreen({super.key, required this.run});

  @override
  ConsumerState<Tap10TestScreen> createState() => _Tap10TestScreenState();
}

class _Tap10TestScreenState extends ConsumerState<Tap10TestScreen> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isDebugMode = ref.watch(debugModeProvider);
    final done = taps >= 10;

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
                    '${strings.taps}: $taps / 10',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: done ? null : () => setState(() => taps++),
                    child: const Text('Trykk'),
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
                  TestResult(testId: 'tap10', summary: {'taps': taps}),
                );
              },
              enabled: done,
              icon: Icons.check_circle,
            ),
            colorSet: done 
              ? BottomBarColorSet.secondary 
              : BottomBarColorSet.primary,
            onAbort: isDebugMode ? () => widget.run.abort('User aborted') : null,
            onSkip: () {
              widget.run.complete(
                TestResult(testId: 'tap10', summary: {'taps': 0}),
              );
            },
          ),
        ],
      ),
    );
  }
}
