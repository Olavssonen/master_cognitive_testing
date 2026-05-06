import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/navigation/app_navigator.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/session/session_state.dart';
import 'dart:io';

class SettingsMenuOverlay extends ConsumerWidget {
  const SettingsMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final visible = session is SessionRunning || session is SessionTransition;

    if (!visible) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.0, -0.18),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Material(
              key: ValueKey(session.runtimeType),
              color: Colors.transparent,
              child: IconButton(
                onPressed: () => _showSettingsMenu(context, ref),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: colorScheme.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    final navigatorColorScheme = Theme.of(navigatorContext).colorScheme;

    showModalBottomSheet(
      context: navigatorContext,
      useRootNavigator: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      barrierColor: navigatorColorScheme.onSurface.withValues(alpha: 0.20),
      builder: (BuildContext sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Material(
                  color: colorScheme.surface,
                  elevation: 10,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Exit options',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _MenuActionTile(
                          icon: Icons.home_rounded,
                          label: 'Back to start menu',
                          accentColor: colorScheme.primary,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            ref.read(sessionProvider.notifier).reset();
                          },
                        ),
                        const SizedBox(height: 12),
                        _MenuActionTile(
                          icon: Icons.close_rounded,
                          label: 'Exit app',
                          accentColor: colorScheme.error,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            exit(0);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorSchemeFor(context, accentColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: accentColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Color colorSchemeFor(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return accentColor == colorScheme.error
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
  }
}
