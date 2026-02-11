import 'package:flutter/material.dart';

class TestShell extends StatelessWidget {
  final String title;
  final Widget child;

  const TestShell({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
    );
  }
}
