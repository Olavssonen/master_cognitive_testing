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
    return Text('Teller: $counter');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// Tap10 Test Formatter
class Tap10TestFormatter implements TestResultFormatter {
  @override
  Text getTextSummary(Map<String, dynamic> summary) {
    final taps = summary['taps'] as int? ?? 0;
    return Text('Trykk: $taps / 10');
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
      final statusText = completed ? '✓ Fullført' : '✗ Ufullstendig';

      // Extract correct/wrong counts if available
      final result = stageData['result'] as Map<String, dynamic>?;
      if (result != null) {
        final correct = result['correct'] as int? ?? 0;
        final wrong = result['wrong'] as int? ?? 0;
        final accuracy = result['accuracy'] as String? ?? '0.0';
        stageInfo.add(
          '${entry.key}: $statusText\n'
          '  ✓ $correct riktig | ✗ $wrong galt | Nøyaktighet: $accuracy%',
        );
      } else {
        stageInfo.add('${entry.key}: $statusText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : 'Test fullført');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}

/// TMT Test Formatter
class TMTTestFormatter implements TestResultFormatter {
  String _translateStageName(String stageName) {
    return switch (stageName) {
      'numbers_test' => 'Tall',
      'mixed_test' => 'Bokstaver',
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
  Text getTextSummary(Map<String, dynamic> summary) {
    final allStages = summary['all_stages'] as Map<String, dynamic>? ?? {};
    final stageInfo = <String>[];

    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? '✓ Fullført' : '✗ Ufullstendig';

      // Show circle count, time, and mistakes for TMT tests
      final circlesOrder = stageData['circlesOrder'] as List<dynamic>?;
      final timeSpent = stageData['timeSpent'] as int? ?? 0;
      final mistakes = stageData['mistakes'] as int? ?? 0;
      final timeText = _formatTime(timeSpent);
      final mistakeText = mistakes > 0 ? ' | Feil: $mistakes' : '';
      
      if (circlesOrder != null && circlesOrder.isNotEmpty) {
        stageInfo.add('${_translateStageName(entry.key)}: $statusText (${circlesOrder.length} sirkler) - Tid: $timeText$mistakeText');
      } else {
        stageInfo.add('${_translateStageName(entry.key)}: $statusText - Tid: $timeText$mistakeText');
      }
    }

    return Text(stageInfo.isNotEmpty ? stageInfo.join('\n') : 'Test fullført');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) {
    return _buildCombinedTMTView(summary);
  }

  Widget _buildCombinedTMTView(Map<String, dynamic> summary) {
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
        child: Text('Ingen tegningsbilder fanget'),
      );
    }

    // Build text summary
    final stageInfo = <String>[];
    for (final entry in allStages.entries) {
      final stageData = entry.value as Map<String, dynamic>? ?? {};
      final completed = stageData['completed'] as bool? ?? false;
      final statusText = completed ? 'Fullført' : 'Ufullstendig';

      // Show circle count, time, and mistakes for TMT tests
      final circlesOrder = stageData['circlesOrder'] as List<dynamic>?;
      final timeSpent = stageData['timeSpent'] as int? ?? 0;
      final mistakes = stageData['mistakes'] as int? ?? 0;
      final timeText = _formatTime(timeSpent);
      final mistakeText = mistakes > 0 ? ' | Feil: $mistakes' : '';
      
      if (circlesOrder != null && circlesOrder.isNotEmpty) {
        stageInfo.add('${_translateStageName(entry.key)}: $statusText (${circlesOrder.length} sirkler) - Tid: $timeText$mistakeText');
      } else {
        stageInfo.add('${_translateStageName(entry.key)}: $statusText - Tid: $timeText$mistakeText');
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Text results (left-aligned)
          Text(
            stageInfo.isNotEmpty ? stageInfo.join('\n') : 'Test fullført',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Bottom: Drawing results (centered)
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
                            _translateStageName(entry.key),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                    child: Text('Feil: $error'),
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
      'Mini-Cog poengsum: $miniCogScore/5\n'
      '\n'
      'Ordgjenkjenning: $wordRecallCorrect/$wordRecallTotal\n'
      'Klokkesifre: $correctNumbers/$totalNumbers\n'
      'Timeviser (10): $hourHandStatus\n'
      'Minuttviser (11): $minuteHandStatus\n'
      'Klokkeviser: $handsCorrect/$handsTotal\n'
      'Totalpoeng: $totalScore/17',
    );
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) {
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
              'Klokke',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      child: Text('Feil: $error'),
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
    return const Text('Test fullført');
  }

  @override
  Widget? getDetailedView(Map<String, dynamic> summary) => null;
}
