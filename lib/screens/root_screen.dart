import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'package:flutter_master_app/screens/menu_screen.dart';
import 'package:flutter_master_app/screens/library_screen.dart';
import 'package:flutter_master_app/screens/session_runner_screen.dart';
import 'package:flutter_master_app/screens/transition_screen.dart';
import 'package:flutter_master_app/screens/summary_screen.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final registry = ref.watch(testRegistryProvider);

    return switch (session) {
      MainMenuIdle() => const MenuScreen(),
      SessionIdle() => LibraryScreen(registry: registry),
      SessionRunning() => SessionRunnerScreen(registry: registry),
      SessionTransition() => const TransitionScreen(),
      SessionDone() => const SummaryScreen(),
    };
  }
}
