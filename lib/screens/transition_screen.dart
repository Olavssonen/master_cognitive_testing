import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/widgets/session_path_widget.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/widgets/bottom_button_bar.dart';

class TransitionScreen extends ConsumerStatefulWidget {
  const TransitionScreen({super.key});

  @override
  ConsumerState<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends ConsumerState<TransitionScreen> {
  bool _animationsComplete = false;
  late SessionTransition _lastSession;

  @override
  void initState() {
    super.initState();
    _lastSession = ref.read(sessionProvider) as SessionTransition;
  }

  @override
  void didUpdateWidget(TransitionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if session changed - if so, reset animations flag
    final currentSession = ref.read(sessionProvider) as SessionTransition;
    if (_lastSession.toIndex != currentSession.toIndex || 
        _lastSession.fromIndex != currentSession.fromIndex) {
      setState(() {
        _animationsComplete = false;
        _lastSession = currentSession;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider) as SessionTransition;
    final registry = ref.watch(testRegistryProvider);
    final strings = ref.watch(appStringsProvider);
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
      body: Column(
            children: [
          // Session path widget
          Expanded(
            child: SessionPathWidget(
              currentIndex: currentIndex,
              totalTests: s.plan.length,
              testRegistry: registry,
              testPlan: s.plan,
              onAnimationsComplete: () {
                setState(() {
                  _animationsComplete = true;
                });
              },
            ),
          ),
          // Bottom button bar
          BottomButtonBar(
            primaryButton: BottomButton(
              label: strings.start,
              onPressed: () => ref.read(sessionProvider.notifier).continueAfterTransition(),
              icon: Icons.play_arrow,
            ),
            colorSet: _animationsComplete 
              ? BottomBarColorSet.secondary 
              : BottomBarColorSet.primary,
            debugMode: false,
          ),
            ],
          ),
    );
  }
}
