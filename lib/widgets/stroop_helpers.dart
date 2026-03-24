import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bottom_button_bar.dart';

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
  static const double unifiedButtonSize = 100;
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
                color: AppColors.white,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: size * 0.15,
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
              TextButton(
                onPressed: onAbort,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Avbryt'),
              ),
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
  final AnimationController? secondLetterAnimationController;
  final String? correctLetter;
  final List<Offset> buttonPositions;
  final int stage;

  const StroopWordDisplay({
    super.key,
    required this.word,
    required this.style,
    required this.animationController,
    this.secondLetterAnimationController,
    this.correctLetter,
    this.buttonPositions = const [],
    this.stage = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        // Only show second letter animation for stage 0 (first four words)
        final shouldShowSecondLetter = stage == 0 && 
            word.length > 1 && 
            secondLetterAnimationController != null && 
            correctLetter != null;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Main word with scale and fade
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: animationController, curve: Curves.easeOut),
              ),
              child: Opacity(
                opacity: animationController.value,
                child: Text(word, style: style),
              ),
            ),
            // Second letter animation - only if all conditions are met
            if (shouldShowSecondLetter)
              SecondLetterIndicator(
                word: word,
                letter: word[1],
                correctLetter: correctLetter!,
                animationController: secondLetterAnimationController!,
                style: style,
                buttonPositions: buttonPositions,
                startFontSize: style.fontSize ?? 72.0,
              ),
          ],
        );
      },
    );
  }
}

/// Animated indicator showing second letter animating down to the button
class SecondLetterIndicator extends StatelessWidget {
  final String word;
  final String letter;
  final String correctLetter;
  final AnimationController animationController;
  final TextStyle style;
  final List<Offset> buttonPositions;
  final double startFontSize;

  const SecondLetterIndicator({
    super.key,
    required this.word,
    required this.letter,
    required this.correctLetter,
    required this.animationController,
    required this.style,
    required this.buttonPositions,
    this.startFontSize = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    // Map letter to button index
    final buttonIndex = StroopColorConstants.colorLetters.indexOf(correctLetter);
    
    if (buttonIndex < 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // Apply professional easing curve: ease-in at start, ease-out at end
        final curvedAnimation = CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOutCubic,
        );
        final animValue = curvedAnimation.value;
        
        // Calculate font size transitioning from word size to button size
        final endFontSize = startFontSize * 0.65;
        final currentFontSize = startFontSize + (endFontSize - startFontSize) * animValue;
        final screenSize = MediaQuery.of(context).size;
        final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

        // Calculate the actual starting position of word[1] dynamically using TextPainter
        final textPainter = TextPainter(
          text: TextSpan(text: letter, style: style),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // Measure widths using TextPainter for accuracy
        final fullWordPainter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
        );
        fullWordPainter.layout();
        
        final firstCharPainter = TextPainter(
          text: TextSpan(text: word[0], style: style),
          textDirection: TextDirection.ltr,
        );
        firstCharPainter.layout();
        
        final secondCharPainter = TextPainter(
          text: TextSpan(text: word[1], style: style),
          textDirection: TextDirection.ltr,
        );
        secondCharPainter.layout();
        
        // Word is centered, so it starts at: -totalWidth / 2
        // Second letter starts at: word start + first char width + half of second char width
        final wordStartX = -fullWordPainter.width / 2;
        final secondLetterStartX = wordStartX + firstCharPainter.width + secondCharPainter.width / 2;

        // Simple: Animate from word[1] position to button center
        double startX = secondLetterStartX;
        double startY = 0.0;
        double endX = 0.0;
        double endY = 0.0;

        if (buttonPositions.isNotEmpty && buttonIndex < buttonPositions.length) {
          final buttonPosition = buttonPositions[buttonIndex];
          endX = buttonPosition.dx - screenCenter.dx;
          endY = buttonPosition.dy - screenCenter.dy;
        } else {
          const buttonWidth = 100.0;
          const buttonSpacing = 16.0;
          const totalButtonsWidth = 4 * buttonWidth + 3 * buttonSpacing;
          const bottomPadding = 16.0;
          const bottomActionHeight = 80.0;
          
          endX = -(totalButtonsWidth / 2) + (buttonIndex * (buttonWidth + buttonSpacing)) + (buttonWidth / 2);
          final estimatedButtonY = screenSize.height - bottomActionHeight - (buttonWidth / 2) - bottomPadding;
          endY = estimatedButtonY - screenCenter.dy;
        }

        // Interpolate from start to end with smooth continuous animation
        // End position includes the plunge downward into the button
        const plungeDistance = 70.0;  // How far the letter plunges down into button
        final smoothEndX = endX;
        final smoothEndY = endY + plungeDistance;
        
        final currentX = startX + (smoothEndX - startX) * animValue;
        final currentY = startY + (smoothEndY - startY) * animValue;

        return Transform.translate(
          offset: Offset(currentX, currentY),
          child: Text(
            letter.toUpperCase(),
            style: (style).copyWith(
              fontSize: currentFontSize,
              color: style.color ?? AppColors.charcoalBlue,
              fontWeight: FontWeight.bold,
            ),
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Klar for testen?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        BottomButtonBar(
          actionButtons: [
            BottomButton(
              label: 'Spill igjen',
              onPressed: onReplay,
              icon: Icons.refresh,
            ),
            BottomButton(
              label: 'Start test',
              onPressed: onStartTest,
              icon: Icons.play_arrow,
            ),
          ],
          onAbort: onAbort,
          showAbortButton: false,
          useRow: true,
        ),
      ],
    );
  }
}
