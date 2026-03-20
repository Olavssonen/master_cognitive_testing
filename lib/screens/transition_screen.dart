import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/widgets/session_path_widget.dart';
import 'package:flutter_master_app/providers/test_providers.dart';

class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider) as SessionTransition;
    final registry = ref.watch(testRegistryProvider);
    final isInitial = s.fromIndex == -1;
    final isFinal = s.toIndex == s.fromIndex;

    // Determine current index for the path widget
    // Index -1 = start, 0 = after test 0, 1 = after test 1, etc.
    final int currentIndex;
    if (isInitial) {
      currentIndex = -1; // At start
    } else if (isFinal) {
      currentIndex = s.plan.length; // At goal
    } else {
      currentIndex = s.toIndex - 1; // After completing previous test
    }

    return Scaffold(
      body: Stack(
        children: [
          // Session path widget
          SessionPathWidget(
            currentIndex: currentIndex,
            totalTests: s.plan.length,
            testRegistry: registry,
            testPlan: s.plan,
          ),
          // Button at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: FilledButton(
                onPressed: () => ref.read(sessionProvider.notifier).continueAfterTransition(),
                child: const Text('Fortsett'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
