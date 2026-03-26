import 'package:flutter/material.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

class TestShell extends StatelessWidget {
  final Widget child;

  const TestShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.platinum,
      body: SafeArea(child: child),
    );
  }
}
