import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/tests/counter_test.dart';
import 'package:flutter_master_app/tests/tap10_test.dart';
import 'package:flutter_master_app/tests/tmt_test.dart';
import 'package:flutter_master_app/tests/stroop_test.dart';
import 'package:flutter_master_app/tests/cog_test.dart';

final debugModeProvider = NotifierProvider<DebugModeNotifier, bool>(DebugModeNotifier.new);

class DebugModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}

final testRegistryProvider = Provider<List<TestDefinition>>((ref) {
  final debugMode = ref.watch(debugModeProvider);
  
  if (debugMode) {
    // Debug mode ON: all tests available
    return [
      counterTest,
      tap10Test,
      cogTest,
      tmtTest,
      stroopTest,
    ];
  } else {
    // Debug mode OFF: only stroop, tmt, and cog available
    return [
      cogTest,
      tmtTest,
      stroopTest,
    ];
  }
});
