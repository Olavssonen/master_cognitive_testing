import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';

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
                        'Slik spiller du',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Trykk enkelt på "+"-knappen så mange ganger du kan. '
                        'Denne testen måler tappingshastigheten og koordinasjonen din.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Gjeldende telling: $counter',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              FloatingActionButton.extended(
                onPressed: () {
                  setState(() => counter++);
                },
                label: const Text('Trykk'),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(height: 40),
              Text(
                'Trykk på knappen ovenfor for å øke telleren.\nNår du er klar, klikk "Fortsett".',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomButtonBar(
        primaryButton: BottomButton(
          label: 'Fortsett',
          onPressed: widget.onComplete,
        ),
        showAbortButton: false,
      ),
    );
  }
}
