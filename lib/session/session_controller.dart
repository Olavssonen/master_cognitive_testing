import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/session/session_state.dart';

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  final List<TestResult> _results = [];

  @override
  SessionState build() => const SessionIdle();

  void start(List<String> plan) {
    _results.clear();
    state = SessionRunning(plan, 0);
  }

  void completeTest(TestResult result) {
    _results.add(result);

    final current = state;
    if (current is! SessionRunning) return;

    final isLast = current.index == current.plan.length - 1;
    if (isLast) {
      state = SessionDone(List.unmodifiable(_results));
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

    state = SessionRunning(current.plan, current.toIndex);
  }

  void abortSession(String reason) {
    _results.clear();
    state = const SessionIdle();
  }

  void reset() {
    _results.clear();
    state = const SessionIdle();
  }
}
