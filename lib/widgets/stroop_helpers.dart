import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bottom_button_bar.dart';
import 'round_info_screen.dart';

/// Centralized constants for Stroop test
class StroopColorConstants {
  static const List<Color> colors = [
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFFBC02D), // Yellow
  ];

  static const List<String> colorNames = ['RØD', 'BLÅ', 'GRØNN', 'GUL'];
  static const List<String> colorLetters = ['Ø', 'L', 'R', 'U'];
}

/// Layout and sizing configuration for Stroop test
class StroopLayout {
  static const tutorial = StroopLayoutConfig(
    buttonSize: 100,
    middleTextSize: 72,
  );

  static const test = StroopLayoutConfig(
    buttonSize: 100,
    middleTextSize: 64,
  );
  
  // Unified button size for both tutorial and test
  static const double unifiedButtonSize = 140;
}

class StroopLayoutConfig {
  final double buttonSize;
  final double middleTextSize;

  const StroopLayoutConfig({
    required this.buttonSize,
    required this.middleTextSize,
  });
}

/// Represents a single Stroop test item
class StroopItem {
  final Color textColor;
  final String displayWord;
  final String correctLetter;

  StroopItem({
    required this.textColor,
    required this.displayWord,
    required this.correctLetter,
  });
}

/// Reusable Stroop color button widget
class StroopColorButton extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final String? label;
  final double size;
  final VoidCallback onPressed;

  const StroopColorButton({
    super.key,
    required this.letter,
    required this.backgroundColor,
    required this.onPressed,
    this.label,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label == null) ...[
              // Show letter when no label (test mode)
              Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ] else ...[
              // Show label centered and larger (tutorial mode)
              Text(
                label!,
                style: TextStyle(
                  fontSize: size * 0.19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable Stroop screen layout widget
/// Enforces consistent layout structure between tutorial and test
class StroopScreen extends StatelessWidget {
  final String progressText; // e.g., "1/2" or "1/4"
  final Widget middleContent; // The large colored word
  final List<Widget> buttons;
  final VoidCallback? onAbort;
  final Widget? bottomButton; // Optional Continue/Submit Results button

  const StroopScreen({
    super.key,
    required this.progressText,
    required this.middleContent,
    required this.buttons,
    this.onAbort,
    this.bottomButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Progress counter at top
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            progressText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        // Expanded center section with colored word
        Expanded(
          child: Center(
            child: middleContent,
          ),
        ),
        // Buttons section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: buttons,
          ),
        ),
        // Bottom action button and abort
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (bottomButton != null) bottomButton! else const SizedBox(),
              if (bottomButton != null) const SizedBox(height: 12) else const SizedBox(),
              if (onAbort != null)
                TextButton(
                  onPressed: onAbort,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                  child: const Text('Avbryt'),
                )
              else
                const SizedBox(height: 36), // Maintain spacing when button is hidden
            ],
          ),
        ),
      ],
    );
  }
}

/// Button with feedback animation (shockwave ripple on press)
class FeedbackStroopButton extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final String? label;
  final double size;
  final VoidCallback onPressed;
  final String? feedbackLetter;
  final Color? feedbackColor;
  final AnimationController feedbackController;

  const FeedbackStroopButton({
    super.key,
    required this.letter,
    required this.backgroundColor,
    required this.onPressed,
    required this.feedbackController,
    this.label,
    this.size = 80,
    this.feedbackLetter,
    this.feedbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Filled expanding circle
        if (feedbackLetter == letter && feedbackColor != null)
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(parent: feedbackController, curve: Curves.easeOut),
            ),
            child: Opacity(
              opacity: (1.0 - feedbackController.value).clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: feedbackColor?.withOpacity(0.6),
                ),
              ),
            ),
          ),
        // Button
        _buildButton(),
      ],
    );
  }

  Widget _buildButton() {
    return StroopColorButton(
      letter: letter,
      backgroundColor: feedbackLetter == letter
          ? (feedbackColor ?? backgroundColor)
          : backgroundColor,
      label: label,
      size: size,
      onPressed: onPressed,
    );
  }
}

/// Animated word display with fade-in and scale animation
class StroopWordDisplay extends StatelessWidget {
  final String word;
  final TextStyle style;
  final AnimationController animationController;

  const StroopWordDisplay({
    super.key,
    required this.word,
    required this.style,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: animationController, curve: Curves.easeOut),
          ),
          child: Opacity(
            opacity: animationController.value,
            child: Text(word, style: style),
          ),
        );
      },
    );
  }
}

/// Intermediate screen between tutorial and test
class StroopIntermediateScreen extends StatelessWidget {
  final VoidCallback onReplay;
  final VoidCallback onStartTest;
  final VoidCallback? onAbort;

  const StroopIntermediateScreen({
    super.key,
    required this.onReplay,
    required this.onStartTest,
    this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
    return RoundInfoScreen(
      title: 'Runde 2',
      subtitle: 'Se på fargen, ikke ordet',
      bottomContent: BottomButtonBar(
        actionButtons: [
          BottomButton(
            label: 'Prøv igjen',
            onPressed: onReplay,
            icon: Icons.refresh,
          ),
          BottomButton(
            label: 'Start',
            onPressed: onStartTest,
            icon: Icons.play_arrow,
          ),
        ],
        onAbort: onAbort,
        showAbortButton: false,
        useRow: true,
      ),
    );
  }
}
