import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/navigation/app_navigator.dart';
import 'package:flutter_master_app/screens/root_screen.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/widgets/settings_menu_overlay.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Krister Tester - Kognitive Evner',
      theme: AppTheme.light(),
      home: const RootScreen(),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child,
            const SettingsMenuOverlay(),
          ],
        );
      },
    );
  }
}
