import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/models/test_result_formatter.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionDone;

    return Scaffold(
      body: Column(
        children: [
          // Custom header with blue title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Sammendrag',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Content list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Fullførte ${s.results.length} tester'),
                const SizedBox(height: 12),
                for (final r in s.results)
                  _buildTestCard(r),
              ],
            ),
          ),
          // Bottom button bar
          BottomButtonBar(
            primaryButton: BottomButton(
              label: 'Ferdig',
              onPressed: () => ref.read(sessionProvider.notifier).reset(),
            ),
            onAbort: null,
            showAbortButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(TestResult r) {
    final formatter = TestResultFormatterFactory.getFormatter(r.testId);
    final detailedView = formatter.getDetailedView(r.summary);
    final textSummary = formatter.getTextSummary(r.summary);

    // For TMT tests with detailed view, combine text and image in one card
    if (r.testId == 'TMT' && detailedView != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.testId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              detailedView,
            ],
          ),
        ),
      );
    }

    // For other tests, use consistent layout with bold title
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.testId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            textSummary,
            if (detailedView != null) ...[
              const SizedBox(height: 16),
              detailedView,
            ],
          ],
        ),
      ),
    );
  }
}
