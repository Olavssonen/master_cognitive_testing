import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionDone;

    return Scaffold(
      appBar: AppBar(title: const Text('Session summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Completed ${s.results.length} tests'),
          const SizedBox(height: 12),
          for (final r in s.results)
            Card(
              child: ListTile(
                title: Text(r.testId),
                subtitle: Text('${r.summary}'),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(sessionProvider.notifier).reset(),
            child: const Text('Back to start'),
          ),
        ],
      ),
    );
  }
}
