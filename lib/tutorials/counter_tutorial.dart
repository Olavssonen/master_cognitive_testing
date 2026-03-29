import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';

/// Tutorial screen for Counter Test
class CounterTutorial extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const CounterTutorial({super.key, required this.onComplete});

  @override
  ConsumerState<CounterTutorial> createState() => _CounterTutorialState();
}

class _CounterTutorialState extends ConsumerState<CounterTutorial> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      body: TestShell(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        strings.howToPlay,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.counterTutorialDesc,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '${strings.currentCount}: $counter',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              FloatingActionButton.extended(
                onPressed: () {
                  setState(() => counter++);
                },
                label: Text(strings.tapsRemaining),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(height: 40),
              Text(
                strings.readyToContinue,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomButtonBar(
        primaryButton: BottomButton(
          label: strings.next,
          onPressed: widget.onComplete,
        ),
        showAbortButton: false,
      ),
    );
  }
}
