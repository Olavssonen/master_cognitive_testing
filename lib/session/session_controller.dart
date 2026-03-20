import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_state.dart';

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  final List<TestResult> _results = [];

  TestResult _createPlaceholderResult() {
    return const TestResult(testId: '', summary: {});
  }

  @override
  SessionState build() => const MainMenuIdle();

  void enterLibrary() {
    state = const SessionIdle();
  }

  void returnToMenu() {
    _results.clear();
    state = const MainMenuIdle();
  }

  void start(List<String> plan) {
    _results.clear();
    // Start with a transition screen showing first test info
    state = SessionTransition(plan, -1, 0, _createPlaceholderResult());
  }

  void completeTest(TestResult result) {
    _results.add(result);

    final current = state;
    if (current is! SessionRunning) return;

    final isLast = current.index == current.plan.length - 1;
    if (isLast) {
      // Show transition screen after last test before going to summary
      state = SessionTransition(
        current.plan,
        current.index,
        current.index,
        result,
      );
    } else {
      state = SessionTransition(
        current.plan,
        current.index,
        current.index + 1,
        result,
      );
    }
  }

  void continueAfterTransition() {
    final current = state;
    if (current is! SessionTransition) return;

    // Check if this is the initial transition (fromIndex == -1)
    if (current.fromIndex == -1) {
      state = SessionRunning(current.plan, current.toIndex);
    }
    // Check if this is the final transition (toIndex == fromIndex)
    else if (current.toIndex == current.fromIndex) {
      state = SessionDone(List.unmodifiable(_results));
    }
    // Normal transition between tests
    else {
      state = SessionRunning(current.plan, current.toIndex);
    }
  }

  void abortSession(String reason) {
    _results.clear();
    state = const MainMenuIdle();
  }

  void reset() {
    _results.clear();
    state = const MainMenuIdle();
  }
}
