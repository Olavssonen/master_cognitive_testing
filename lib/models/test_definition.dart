import 'package:flutter/material.dart';

typedef TestBuilder = Widget Function(BuildContext context, TestRunContext run);

class TestDefinition {
  final String id;
  final String title;
  final IconData icon;
  final TestBuilder build;

  const TestDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.build,
  });
}

class TestResult {
  final String testId;
  final Map<String, Object?> summary;

  const TestResult({
    required this.testId,
    required this.summary,
  });
}

class TestRunContext {
  final void Function(TestResult result) complete;
  final void Function(String reason) abort;

  const TestRunContext({
    required this.complete,
    required this.abort,
  });
}
