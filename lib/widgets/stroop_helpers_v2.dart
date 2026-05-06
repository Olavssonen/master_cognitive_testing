import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import 'test_shell.dart';
import 'bottom_button_bar.dart';

/// Centralized constants for Stroop Test V2 (with symbols)
class StroopColorConstantsV2 {
  static const List<Color> colors = [
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFFBC02D), // Yellow
  ];

  // Dynamic color names based on language provider
  static List<String> getColorNames(
    String colorRed,
    String colorBlue,
    String colorGreen,
    String colorYellow,
  ) {
    return [colorRed, colorBlue, colorGreen, colorYellow];
  }

  static const List<IconData> colorSymbols = [
    Icons.favorite_border, // Heart for Red
    Icons.water_drop, // Droplet for Blue
    Icons.eco, // Leaf/plant for Green
    Icons.sunny, // Sun for Yellow
  ];
}

/// Layout and sizing configuration for Stroop Test V2
class StroopLayoutV2 {
  static const tutorial = StroopLayoutConfig(
    buttonSize: 100,
    middleTextSize: 90,
  );

  static const test = StroopLayoutConfig(buttonSize: 100, middleTextSize: 80);

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

/// Represents a single Stroop test item for V2 (using symbols)
class StroopItemV2 {
  final Color textColor;
  final String displayWord;
  final IconData correctSymbol; // Icon instead of letter

  StroopItemV2({
    required this.textColor,
    required this.displayWord,
    required this.correctSymbol,
  });
}

/// Reusable Stroop symbol button widget for V2
class StroopSymbolButton extends StatelessWidget {
  final IconData symbol;
  final Color backgroundColor;
  final double size;
  final VoidCallback onPressed;

  const StroopSymbolButton({
    super.key,
    required this.symbol,
    required this.backgroundColor,
    required this.onPressed,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: backgroundColor),
        onPressed: onPressed,
        child: Icon(symbol, size: size * 0.45, color: Colors.white),
      ),
    );
  }
}

/// Reusable Stroop screen layout widget for V2
/// Enforces consistent layout structure between tutorial and test
class StroopScreenV2 extends ConsumerWidget {
  final String progressText; // e.g., "1/2" or "1/4"
  final Widget middleContent; // The large colored word
  final List<Widget> buttons;
  final Widget? buttonsOverlay; // Optional overlay shown above buttons
  final VoidCallback? onAbort;
  final Widget? bottomButton; // Optional Continue/Submit Results button

  const StroopScreenV2({
    super.key,
    required this.progressText,
    required this.middleContent,
    required this.buttons,
    this.buttonsOverlay,
    this.onAbort,
    this.bottomButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

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
        Expanded(child: Center(child: middleContent)),
        // Buttons section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: buttons,
              ),
              if (buttonsOverlay != null) IgnorePointer(child: buttonsOverlay!),
            ],
          ),
        ),
        // Bottom action button and abort
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (bottomButton != null) bottomButton! else const SizedBox(),
              if (bottomButton != null)
                const SizedBox(height: 12)
              else
                const SizedBox(),
              if (onAbort != null)
                TextButton(
                  onPressed: onAbort,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                  child: Text(strings.cancel),
                )
              else
                const SizedBox(
                  height: 36,
                ), // Maintain spacing when button is hidden
            ],
          ),
        ),
      ],
    );
  }
}

/// Button with feedback animation (shockwave ripple on press)
class FeedbackStroopButtonV2 extends StatelessWidget {
  final IconData symbol;
  final Color backgroundColor;
  final double size;
  final VoidCallback onPressed;
  final IconData? feedbackSymbol;
  final Color? feedbackColor;
  final AnimationController feedbackController;

  const FeedbackStroopButtonV2({
    super.key,
    required this.symbol,
    required this.backgroundColor,
    required this.onPressed,
    required this.feedbackController,
    this.size = 80,
    this.feedbackSymbol,
    this.feedbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Filled expanding circle
        if (feedbackSymbol == symbol && feedbackColor != null)
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(
                parent: feedbackController,
                curve: Curves.easeOut,
              ),
            ),
            child: Opacity(
              opacity: (1.0 - feedbackController.value).clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: feedbackColor!.withOpacity(0.6),
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
    return StroopSymbolButton(
      symbol: symbol,
      backgroundColor: feedbackSymbol == symbol
          ? (feedbackColor ?? backgroundColor)
          : backgroundColor,
      size: size,
      onPressed: onPressed,
    );
  }
}

/// Animated word display with fade-in and scale animation
class StroopWordDisplayV2 extends StatelessWidget {
  final String word;
  final TextStyle style;
  final AnimationController animationController;

  const StroopWordDisplayV2({
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

/// Example screen showing correct and incorrect answers for Stroop Test V2
class StroopExampleScreenV2 extends ConsumerWidget {
  final VoidCallback onContinue;

  const StroopExampleScreenV2({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final colors = StroopColorConstantsV2.colors;
    final colorSymbols = StroopColorConstantsV2.colorSymbols;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final instructionStyle = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 40,
        );
    final colorNames = StroopColorConstantsV2.getColorNames(
      strings.colorRed.toUpperCase(),
      strings.colorBlue.toUpperCase(),
      strings.colorGreen.toUpperCase(),
      strings.colorYellow.toUpperCase(),
    );

    // Example: Blue word displayed in YELLOW color
    final wordIndex = 1; // Blue
    final displayColorIndex = 3; // Yellow
    final word = colorNames[wordIndex];
    final displayColor = colors[displayColorIndex];

    return TestShell(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          strings.hereIsAnExample,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 64,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          strings.lookAtColorNotWord,
                          style: instructionStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word,
                        style: TextStyle(
                          fontSize: StroopLayoutV2.test.middleTextSize,
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              StroopSymbolButton(
                                symbol: colorSymbols[displayColorIndex],
                                backgroundColor: displayColor,
                                size: StroopLayoutV2.unifiedButtonSize,
                                onPressed: () {},
                              ),
                              const SizedBox(height: 18),
                              Text(
                                strings.correctOption,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successGreen,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.check,
                                color: AppColors.successGreen,
                                size: 48,
                                semanticLabel: strings.correct,
                              ),
                            ],
                          ),
                          const SizedBox(width: 64),
                          Column(
                            children: [
                              StroopSymbolButton(
                                symbol: colorSymbols[wordIndex],
                                backgroundColor: colors[wordIndex],
                                size: StroopLayoutV2.unifiedButtonSize,
                                onPressed: () {},
                              ),
                              const SizedBox(height: 18),
                              Text(
                                strings.wrongOption,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.errorRed,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.close,
                                color: AppColors.errorRed,
                                size: 48,
                                semanticLabel: strings.wrong,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      strings.stroopExampleContinueInstruction,
                      style: instructionStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomButtonBar(
            primaryButton: BottomButton(
              label: ref.watch(appStringsProvider).continueTutorial,
              icon: Icons.arrow_forward,
              onPressed: onContinue,
            ),
            onAbort: null,
            showAbortButton: false,
            colorSet: BottomBarColorSet.primary,
          ),
        ],
      ),
    );
  }
}
