import 'package:flutter/material.dart';

class TestShell extends StatelessWidget {
  final Widget child;

  const TestShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
    );
  }
}
