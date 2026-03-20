import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';

class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionTransition;
    final isInitial = s.fromIndex == -1;
    final isFinal = s.toIndex == s.fromIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isInitial) ...[
              const Text('Klar for å starte?'),
              const SizedBox(height: 12),
              Text('${s.plan.length} tester i alt'),
            ] else if (isFinal) ...[
              const Text('Gratulerer!'),
              const SizedBox(height: 12),
              const Text('Du har fullført alle testene'),
            ] else ...[
              Text('Ferdig: ${s.lastResult.testId}'),
              const SizedBox(height: 12),
              Text('Neste test: ${s.toIndex + 1}/${s.plan.length}'),
            ],
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: isFinal ? 1.0 : (s.toIndex) / (s.plan.length),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => ref.read(sessionProvider.notifier).continueAfterTransition(),
              child: Text(isFinal ? 'Gå til sammendrag' : 'Fortsett'),
            ),
          ],
        ),
      ),
    );
  }
}
