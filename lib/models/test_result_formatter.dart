import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

/// Abstract formatter for displaying test results
/// Each test type implements this to define how its data is displayed
abstract class TestResultFormatter {
  /// Returns text summary to display below the test title
  Text getTextSummary(Map<String, dynamic> summary);

  /// Returns optional widget to display below the text summary (e.g., images)
  Widget? getDetailedView(Map<String, dynamic> summary) {
    return null;
  }
}

/// Counter Test Formatter
class CounterTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final counter = summary['counter'] as int? ?? 0;
    return Text('Counter: $counter');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// Tap10 Test Formatter
class Tap10TestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final taps = summary['taps'] as int? ?? 0;
    return Text('Taps: $taps / 10');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// Stroop Test Formatter
class StroopTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? '✓ Complete' : '✗ Incomplete';

      // Extract correct/wrong counts if available
      final result = stageData['result'] as Map<String, dynamic>?;
      if (result != null) {
        final correct = result['correct'] as int? ?? 0;
        final wrong = result['wrong'] as int? ?? 0;
        final accuracy = result['accuracy'] as String? ?? '0.0';
        stageInfo.add(
          '${entry.key}: $statusText\n'
          '  ✓ $correct correct | ✗ $wrong wrong | Accuracy: $accuracy%',
        );
      } else {
        stageInfo.add('${entry.key}: $statusText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : 'Test completed');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// TMT Test Formatter
class TMTTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? '✓ Complete' : '✗ Incomplete';

      // Show circle count for TMT tests
      final circlesOrder = stageData['circlesOrder'] as List<dynamic>?;
      if (circlesOrder != null && circlesOrder.isNotEmpty) {
        stageInfo.add('${entry.key}: $statusText (${circlesOrder.length} circles)');
      } else {
        stageInfo.add('${entry.key}: $statusText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : 'Test completed');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) {
    return _buildTMTImages(summary);
  }

  Widget _buildTMTImages(Map<String, dynamic> summary) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};

    final images = <String, Uint8List>{};
    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      var image = stageData['image'];

      // Handle different types that might come through
      if (image != null) {
        if (image is Uint8List) {
          images[entry.key] = image;
        } else if (image is List<int>) {
          images[entry.key] = Uint8List.fromList(image);
        }
      }
    }

    if (images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No drawing images captured'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Drawing Results',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in images.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey500),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.memory(
                              entry.value,
                              fit: BoxFit.contain,
                              height: 300,
                              width: 300,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 300,
                                  width: 300,
                                  color: Colors.red[100],
                                  child: Center(
                                    child: Text('Error: $error'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clock Test (Mini-Cog) Formatter
class CogTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final correctNumbers = summary['correct_numbers'] as int? ?? 0;
    final totalNumbers = summary['total_numbers'] as int? ?? 12;
    final totalScore = summary['total_score'] as int? ?? 0;

    return Text(
      'Numbers placed correctly: $correctNumbers/$totalNumbers\n'
      'Score: $totalScore/12',
    );
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// Factory to get the appropriate formatter for a test type
class TestResultFormatterFactory {
  static TestResultFormatter getFormatter(String testId) {
    return switch (testId) {
      'counter' => CounterTestFormatter(),
      'tap10' => Tap10TestFormatter(),
      'cog' => CogTestFormatter(),
      'stroop' => StroopTestFormatter(),
      'TMT' => TMTTestFormatter(),
      _ => _DefaultFormatter(),
    };
  }
}

/// Default formatter for unknown test types
class _DefaultFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    return const Text('Test completed');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}
