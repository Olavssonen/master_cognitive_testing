import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';

/// Tutorial screen for Stroop Test
class StroopTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onAbort;

  const StroopTutorial({super.key, required this.onComplete, this.onAbort});

  @override
  State<StroopTutorial> createState() => _StroopTutorialState();
}

class _StroopTutorialState extends State<StroopTutorial> {
  @override
  Widget build(BuildContext context) {
    return TestShell(
      title: 'Stroop Test - Tutorial',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Stroop Tutorial Implementation Area',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: widget.onComplete,
                  child: const Text('Continue'),
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
