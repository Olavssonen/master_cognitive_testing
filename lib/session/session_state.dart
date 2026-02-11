import 'package:flutter_master_app/models/test_definition.dart';

sealed class SessionState {
  const SessionState();
}

class SessionIdle extends SessionState {
  const SessionIdle();
}

class SessionRunning extends SessionState {
  final List<String> plan;
  final int index;
  const SessionRunning(this.plan, this.index);
}

class SessionTransition extends SessionState {
  final List<String> plan;
  final int fromIndex;
  final int toIndex;
  final TestResult lastResult;

  const SessionTransition(this.plan, this.fromIndex, this.toIndex, this.lastResult);
}

class SessionDone extends SessionState {
  final List<TestResult> results;
  const SessionDone(this.results);
}
