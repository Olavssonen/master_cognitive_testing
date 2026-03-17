import 'package:flutter/material.dart';
import 'package:flutter_master_app/widgets/test_shell.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

/// Tutorial screen for Tap 10 Times Test
class Tap10Tutorial extends StatefulWidget {
  final VoidCallback onComplete;
  const Tap10Tutorial({super.key, required this.onComplete});

  @override
  State<Tap10Tutorial> createState() => _Tap10TutorialState();
}

class _Tap10TutorialState extends State<Tap10Tutorial> {
  int taps = 0;
  final int maxTaps = 5; // Only need 5 taps to complete tutorial
  bool completed = false;

  void _handleTap() {
    setState(() {
      if (taps < maxTaps) {
        taps++;
        if (taps == maxTaps) {
          completed = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (taps / maxTaps * 100).toStringAsFixed(0);

    return TestShell(
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
                      'Tap the button 10 times as quickly as you can. '
                      'This test measures your finger strength and control.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            LinearProgressIndicator(
              value: taps / maxTaps,
              minHeight: 10,
            ),
            const SizedBox(height: 20),
            Text(
              '$taps / $maxTaps taps ($progress%)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: completed ? AppColors.accent : AppColors.grey800,
                  ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 120,
              height: 120,
              child: FloatingActionButton(
                onPressed: completed ? null : _handleTap,
                backgroundColor: completed ? AppColors.grey300 : AppColors.accent,
                child: const Icon(Icons.touch_app, size: 48),
              ),
            ),
            const SizedBox(height: 40),
            if (!completed)
              Text(
                'Tap ${maxTaps - taps} more times to complete the tutorial.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              )
            else
              Column(
                children: [
                  Text(
                    'Tutorial Completed!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: widget.onComplete,
                    child: const Text('Continue'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
