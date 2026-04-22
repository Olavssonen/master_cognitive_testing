import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/l10n/strings.dart';

/// Abstract formatter for displaying test results
/// Each test type implements this to define how its data is displayed
abstract class TestResultFormatter {
  /// Returns text summary to display below the test title
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings);

  /// Returns optional widget to display below the text summary (e.g., images)
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) {
    return null;
  }
}

/// Counter Test Formatter
class CounterTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    final counter = summary['counter'] as int? ?? 0;
    return Text('${strings.counterTest}: $counter');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) => null;
}

/// Tap10 Test Formatter
class Tap10TestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    final taps = summary['taps'] as int? ?? 0;
    return Text('${strings.taps}: $taps / 10');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) => null;
}

/// Stroop Test Formatter (Old - Debug Only)
class StroopTestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? strings.completed : strings.incomplete;

      // Extract correct/wrong counts if available
      final result = stageData['result'] as Map<String, dynamic>?;
      if (result != null) {
        final correct = result['correct'] as int? ?? 0;
        final wrong = result['wrong'] as int? ?? 0;
        final accuracy = result['accuracy'] as String? ?? '0.0';
        stageInfo.add(
          '${entry.key}: $statusText\n'
          '  ${strings.correct}: $correct | ${strings.wrong}: $wrong | ${strings.accuracy_label}: $accuracy%',
        );
      } else {
        stageInfo.add('${entry.key}: $statusText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : strings.testComplete);
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) => null;
}

/// Stroop Test Formatter (Main Version - V2 with Symbols)
class StroopTestFormatterV2 implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? strings.completed : strings.incomplete;

      // Extract correct/wrong counts if available
      final result = stageData['result'] as Map<String, dynamic>?;
      if (result != null) {
        final correct = result['correct'] as int? ?? 0;
        final wrong = result['wrong'] as int? ?? 0;
        final accuracy = result['accuracy'] as String? ?? '0.0';
        stageInfo.add(
          '${entry.key}: $statusText\n'
          '  ${strings.correct}: $correct | ${strings.wrong}: $wrong | ${strings.accuracy_label}: $accuracy%',
        );
      } else {
        stageInfo.add('${entry.key}: $statusText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : strings.testComplete);
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) => null;
}

/// TMT Test Formatter
class TMTTestFormatter implements TestResultFormatter {
  String _translateStageName(String stageName, AppStrings strings) {
    return switch (stageName) {
      'numbers_test' => strings.numberStage,
      'mixed_test' => strings.letterStage,
      _ => stageName.replaceAll('_', ' ').toUpperCase(),
    };
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? strings.completed : strings.incomplete;

      // Show circle count, time, and mistakes for TMT tests
      final circlesOrder = stageData['circlesOrder'] as List<dynamic>?;
      final timeSpent = stageData['timeSpent'] as int? ?? 0;
      final mistakes = stageData['mistakes'] as int? ?? 0;
      final timeText = _formatTime(timeSpent);
      final mistakeText = mistakes > 0 ? ' | ${strings.mistakes}: $mistakes' : '';
      
      if (circlesOrder != null && circlesOrder.isNotEmpty) {
        stageInfo.add('${_translateStageName(entry.key, strings)}: $statusText (${circlesOrder.length} ${strings.circles}) - ${strings.time}: $timeText$mistakeText');
      } else {
        stageInfo.add('${_translateStageName(entry.key, strings)}: $statusText - ${strings.time}: $timeText$mistakeText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : strings.testComplete);
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) {
    return _buildCombinedTMTView(summary, strings, context);
  }

  Widget _buildCombinedTMTView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) {
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(strings.noDrawingsFound),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawing results (centered)
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
                            _translateStageName(entry.key, strings),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
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
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    // Word recall scoring (from mini-cog implementation)
    final wordRecallCorrect = summary['word_recall_correct'] as int? ?? 0;
    final wordRecallTotal = summary['word_recall_total'] as int? ?? 3;
    
    // Clock numbers scoring
    final correctNumbers = summary['correct_numbers'] as int? ?? 0;
    final totalNumbers = summary['total_numbers'] as int? ?? 12;
    
    // Clock hand scoring
    final hourHandCorrect = summary['hour_hand_correct'] as int? ?? 0;
    final minuteHandCorrect = summary['minute_hand_correct'] as int? ?? 0;
    final handsCorrect = summary['hands_correct'] as int? ?? 0;
    final handsTotal = summary['hands_total'] as int? ?? 2;
    
    final hourHandStatus = hourHandCorrect == 1 ? '✓' : '✗';
    final minuteHandStatus = minuteHandCorrect == 1 ? '✓' : '✗';
    
    // Calculate Mini-Cog Score (0-5 points)
    // 1 point per correct word (up to 3) + 2 points if clock is perfect (all numbers + both hands)
    int miniCogScore = wordRecallCorrect;
    if (correctNumbers == totalNumbers && handsCorrect == handsTotal) {
      miniCogScore += 2; // 2 points for perfect clock
    }
    // If clock has any mistakes, add 0 points for clock portion

    // Total score
    final totalScore = summary['total_score'] as int? ?? 0;

    return Text(
      '${strings.miniCogScore}: $miniCogScore/5\n'
      '\n'
      '${strings.wordRecall}: $wordRecallCorrect/$wordRecallTotal\n'
      '${strings.clockNumbers}: $correctNumbers/$totalNumbers\n'
      '${strings.hourHand}: $hourHandStatus\n'
      '${strings.minuteHand}: $minuteHandStatus\n'
      '${strings.clockHands}: $handsCorrect/$handsTotal\n'
      '${strings.totalScoreLabel}: $totalScore/17',
    );
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) {
    var image = summary['clock_image'];
    
    if (image == null) {
      return null;
    }
    
    // Handle different types that might come through
    Uint8List? imageData;
    if (image is Uint8List) {
      imageData = image;
    } else if (image is List<int>) {
      imageData = Uint8List.fromList(image);
    }
    
    if (imageData == null) {
      return null;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              strings.clockDrawing,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
                height: 350,
                width: 350,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 350,
                    width: 350,
                    color: Colors.red[100],
                    child: Center(
                      child: Text('${strings.errorMessage}$error'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Factory to get the appropriate formatter for a test type
class TestResultFormatterFactory {
  static TestResultFormatter getFormatter(String testId) {
    return switch (testId) {
      'counter' => CounterTestFormatter(),
      'tap10' => Tap10TestFormatter(),
      'cog' => CogTestFormatter(),
      'stroop' => StroopTestFormatterV2(),
      'stroop_old' => StroopTestFormatter(),
      'TMT' => TMTTestFormatter(),
      _ => _DefaultFormatter(),
    };
  }
}

/// Default formatter for unknown test types
class _DefaultFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary, AppStrings strings) {
    return Text(strings.testComplete);
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary, AppStrings strings, BuildContext context) => null;
}
