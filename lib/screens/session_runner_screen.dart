import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';

class SessionRunnerScreen extends ConsumerWidget {
  final List<TestDefinition> registry;
  const SessionRunnerScreen({super.key, required this.registry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionRunning;
    final testId = s.plan[s.index];
    final test = registry.firstWhere((t) => t.id == testId);

    final run = TestRunContext(
      complete: (result) => ref.read(sessionProvider.notifier).completeTest(result),
      abort: (reason) => ref.read(sessionProvider.notifier).abortSession(reason),
    );

    return test.build(context, run);
  }
}
