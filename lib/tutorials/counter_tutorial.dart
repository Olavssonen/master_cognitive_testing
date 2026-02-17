import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';

/// Tutorial screen for Counter Test
class CounterTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  const CounterTutorial({super.key, required this.onComplete});

  @override
  State<CounterTutorial> createState() => _CounterTutorialState();
}

class _CounterTutorialState extends State<CounterTutorial> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Counter Test - Tutorial',
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
                      'How to Play',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Simply tap the "+" button as many times as you can. '
                      'This test measures your tapping speed and coordination.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Current Count: $counter',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),
            FloatingActionButton.extended(
              onPressed: () {
                setState(() => counter++);
              },
              label: const Text('Tap'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 40),
            Text(
              'Tap the button above to increment the counter.\nWhen ready, click "Continue".',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: widget.onComplete,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
