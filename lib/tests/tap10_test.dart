import 'package:flutter/material.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';

final tap10Test = TestDefinition(
  id: 'Trykk 10 Test',
  title: 'Trykking',
  icon: Icons.touch_app,
  build: (context, run) => Tap10TestScreen(run: run),
);

class Tap10TestScreen extends StatefulWidget {
  final TestRunContext run;
  const Tap10TestScreen({super.key, required this.run});

  @override
  State<Tap10TestScreen> createState() => _Tap10TestScreenState();
}

class _Tap10TestScreenState extends State<Tap10TestScreen> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
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
                    'Trykk: $taps / 10',
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
              label: 'Fullfør',
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
            onAbort: () => widget.run.abort('User aborted'),
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
