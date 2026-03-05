import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/models/test_result_formatter.dart';

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
            _buildTestCard(r),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(sessionProvider.notifier).reset(),
            child: const Text('Back to start'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(TestResult r) {
    final formatter = TestResultFormatterFactory.getFormatter(r.testId);
    final detailedView = formatter.getDetailedView(r.summary);

    return Column(
      children: [
        Card(
          child: SizedBox(
            width: double.infinity,
            child: ListTile(
              title: Text(r.testId),
              subtitle: formatter.getTextSummary(r.summary),
              dense: true,
            ),
          ),
        ),
        // Display detailed view if available (e.g., images for TMT) - in its own card
        if (detailedView != null)
          Card(
            child: detailedView,
          ),
      ],
    );
  }
}
