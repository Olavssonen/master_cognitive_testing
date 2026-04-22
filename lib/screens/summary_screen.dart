import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/models/test_result_formatter.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/l10n/strings.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionDone;
    final strings = ref.watch(appStringsProvider);
    final totalPoints = ref.watch(sessionPointsProvider);
    final pointsSystemEnabled = ref.watch(pointsSystemEnabledProvider);

    return Scaffold(
      body: Column(
        children: [
          // Custom header with blue title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  strings.summary,
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
                // Points Card at top - only show if points system is enabled
                if (pointsSystemEnabled)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.lavender,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          strings.points,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalPoints',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tropicalTeal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Per-test scores with alternating backgrounds
                        ...[
                          for (int i = 0; i < s.results.length; i++)
                            if (s.results[i].summary['pointsEarned'] != null)
                              Container(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.results[i].testId,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      '${s.results[i].summary['pointsEarned']} pts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (pointsSystemEnabled)
                  const SizedBox(height: 24),
                for (final r in s.results)
                  _buildTestCard(r, strings, context),
              ],
            ),
          ),
          // Bottom button bar
          BottomButtonBar(
            primaryButton: BottomButton(
              label: strings.done,
              onPressed: () {
                ref.read(sessionPointsProvider.notifier).reset();
                ref.read(sessionProvider.notifier).reset();
              },
            ),
            onAbort: null,
            showAbortButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(TestResult r, AppStrings strings, BuildContext context) {
    final formatter = TestResultFormatterFactory.getFormatter(r.testId);
    final detailedView = formatter.getDetailedView(r.summary, strings, context);
    final textSummary = formatter.getTextSummary(r.summary, strings);

    // For Mini-Cog tests, use standard formatted layout
    if (r.testId == 'cog') {
      final wordRecallCorrect = r.summary['word_recall_correct'] as int? ?? 0;
      final wordRecallTotal = r.summary['word_recall_total'] as int? ?? 3;
      final correctNumbers = r.summary['correct_numbers'] as int? ?? 0;
      final totalNumbers = r.summary['total_numbers'] as int? ?? 12;
      final hourHandCorrect = r.summary['hour_hand_correct'] as int? ?? 0;
      final minuteHandCorrect = r.summary['minute_hand_correct'] as int? ?? 0;
      final handsCorrect = r.summary['hands_correct'] as int? ?? 0;
      final handsTotal = r.summary['hands_total'] as int? ?? 2;
      final totalScore = r.summary['total_score'] as int? ?? 0;
      final miniCogScore = r.summary['word_recall_correct'] as int? ?? 0;

      final hourHandStatus = hourHandCorrect == 1 ? '✓' : '✗';
      final minuteHandStatus = minuteHandCorrect == 1 ? '✓' : '✗';

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                strings.miniCogCardTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$miniCogScore/5',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              // Word Recall Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.wordRecall,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.wordsRemembered,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$wordRecallCorrect/$wordRecallTotal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Clock Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.clockDrawing,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...[
                Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.clockNumbers,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$correctNumbers/$totalNumbers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.hourHand.replaceAll(RegExp(r'\s*\(\d+\)'), ''),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        hourHandStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.minuteHand.replaceAll(RegExp(r'\s*\(\d+\)'), ''),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        minuteHandStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (detailedView != null) ...[
                const SizedBox(height: 16),
                detailedView,
              ],
            ],
          ),
        ),
      );
    }

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
