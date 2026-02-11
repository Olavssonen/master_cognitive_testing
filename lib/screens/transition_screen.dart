import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';

class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionTransition;

    return Scaffold(
      appBar: AppBar(title: const Text('Transition')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Completed: ${s.lastResult.testId}'),
            const SizedBox(height: 12),
            Text('Next test: ${s.toIndex + 1}/${s.plan.length}'),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: (s.toIndex) / (s.plan.length)),
            const Spacer(),
            FilledButton(
              onPressed: () => ref.read(sessionProvider.notifier).continueAfterTransition(),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
