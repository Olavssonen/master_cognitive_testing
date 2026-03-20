import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CelebrationDialog extends StatefulWidget {
  final VoidCallback onNext;
  final String? title;
  final String? subtitle;

  const CelebrationDialog({
    Key? key,
    required this.onNext,
    this.title = 'Ferdig!',
    this.subtitle,
  }) : super(key: key);

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 800));
    // Start confetti animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          elevation: 8,
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with primary color
                  Text(
                    widget.title!,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNext();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Neste',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Confetti animation - positioned at top
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.08,
            emissionFrequency: 0.01,
            numberOfParticles: 80,
            gravity: 0.3,
            shouldLoop: false,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              AppColors.successGreen,
              AppColors.warningYellow,
              AppColors.lavender,
            ],
          ),
        ),
      ],
    );
  }
}

/// Show celebration dialog with confetti animation
Future<void> showCelebrationDialog(
  BuildContext context, {
  required VoidCallback onNext,
  String title = 'Ferdig!',
  String? subtitle,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return CelebrationDialog(
        onNext: onNext,
        title: title,
        subtitle: subtitle,
      );
    },
  );
}
