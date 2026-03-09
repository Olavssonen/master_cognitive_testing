import 'package:flutter/material.dart';

/// Centralized constants for Stroop test
class StroopColorConstants {
  static const List<Color> colors = [
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFFBC02D), // Yellow
  ];

  static const List<String> colorNames = ['rød', 'blå', 'grønt', 'gul'];
  static const List<String> colorLetters = ['Ø', 'L', 'R', 'U'];
}

/// Layout and sizing configuration for Stroop test
class StroopLayout {
  static const tutorial = StroopLayoutConfig(
    buttonSize: 100,
    middleTextSize: 72,
  );

  static const test = StroopLayoutConfig(
    buttonSize: 80,
    middleTextSize: 64,
  );
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
            Text(
              letter,
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: size * 0.15,
                  color: Colors.white,
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
              TextButton(
                onPressed: onAbort,
                child: const Text('Abort'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
