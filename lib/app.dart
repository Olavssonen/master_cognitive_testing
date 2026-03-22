import 'package:flutter/material.dart';
import 'package:flutter_master_app/screens/root_screen.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krister Tester - Kognitive Evner',
      theme: AppTheme.light(),
      home: const RootScreen(),
    );
  }
}
