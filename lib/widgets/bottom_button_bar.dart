import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/providers/test_providers.dart';

/// Color palette for the bottom button bar
/// Defines all colors used for buttons and background
class BottomBarColorSet {
  final Color primaryButton;
  final Color primaryButtonText;
  final Color primaryButtonDisabled;
  final Color primaryButtonDisabledText;
  final Color backgroundColor;

  const BottomBarColorSet({
    required this.primaryButton,
    required this.primaryButtonText,
    required this.primaryButtonDisabled,
    required this.primaryButtonDisabledText,
    required this.backgroundColor,
  });

  /// Primary color set - uses crayolaBlue for active state
  static const BottomBarColorSet primary = BottomBarColorSet(
    primaryButton: AppColors.crayolaBlue,
    primaryButtonText: AppColors.white,
    primaryButtonDisabled: AppColors.crayolaBlue, // Will be adjusted with alpha in code
    primaryButtonDisabledText: AppColors.white, // Will be adjusted with alpha in code
    backgroundColor: AppColors.crayolaBlue, // Will be adjusted with alpha in code
  );

  /// Secondary color set - uses tropicalTeal for completed/awaiting state
  static const BottomBarColorSet secondary = BottomBarColorSet(
    primaryButton: AppColors.tropicalTeal,
    primaryButtonText: AppColors.white,
    primaryButtonDisabled: AppColors.tropicalTeal, // Will be adjusted with alpha in code
    primaryButtonDisabledText: AppColors.white, // Will be adjusted with alpha in code
    backgroundColor: AppColors.tropicalTeal, // Will be adjusted with alpha in code
  );
}

/// Represents a single bottom button configuration
class BottomButton {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final BottomButtonType type;
  final IconData? icon;

  const BottomButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.type = BottomButtonType.filled,
    this.icon,
  });
}

/// Enum for button types with different visual styles
enum BottomButtonType {
  /// Filled button (primary action) - rarely used in bottom bar
  filled,

  /// Outlined button (secondary action) - default for action buttons
  outlined,

  /// TextButton for cancel/abort actions
  abort,
}

/// A consistent bottom button bar widget
/// 
/// Displays action buttons followed by an abort button at the bottom of screens.
/// Handles flexible button arrangements with consistent spacing and alignment.
/// Buttons are styled with blue fill, large size for easy interaction.
/// 
/// Example usage:
/// ```dart
/// BottomButtonBar(
///   primaryButton: BottomButton(
///     label: 'Fullfør',
///     onPressed: () => handleFinish(),
///     enabled: true,
///   ),
///   onAbort: () => handleAbort(),
/// )
/// ```
/// 
/// For multiple buttons:
/// ```dart
/// BottomButtonBar(
///   actionButtons: [
///     BottomButton(
///       label: 'Prøv igjen',
///       onPressed: () => handleRetry(),
///     ),
///     BottomButton(
///       label: 'Fortsett',
///       onPressed: () => handleContinue(),
///     ),
///   ],
///   onAbort: () => handleAbort(),
/// )
/// ```
class BottomButtonBar extends ConsumerWidget {
  /// Single primary button (e.g., "Fullfør", "Fortsett")
  /// If provided, this is displayed before actionButtons
  final BottomButton? primaryButton;

  /// List of action buttons to display
  /// Each button is displayed with consistent spacing
  /// If empty and no primaryButton, only abort button is shown
  final List<BottomButton>? actionButtons;

  /// Callback when abort button is pressed
  /// If null, abort button is not shown
  final VoidCallback? onAbort;

  /// Callback for skip test in debug mode
  /// If null, skip button is not shown in debug mode
  final VoidCallback? onSkip;

  /// Label for the abort button (default: 'Avbryt')
  final String abortLabel;

  /// Whether buttons are shown in a row (horizontal) or column (vertical)
  /// Row: when 2-3 buttons, Column: when more buttons or complex layouts
  final bool useRow;

  /// Spacing between buttons
  final double buttonSpacing;

  /// Padding around the entire button bar
  final EdgeInsets padding;

  /// Whether abort button should always be shown
  final bool showAbortButton;

  /// Button height (default: 56.0 for larger touch targets)
  final double buttonHeight;

  /// Font size for button text (default: 16.0)
  final double fontSize;

  /// Debug mode: shows abort button in bottom-right corner, isolated from main layout
  /// This prevents the abort button from taking up space or displacing other buttons
  /// If null, reads from the global debugModeProvider
  final bool? debugMode;

  /// Fixed height for the button bar container (default: 200.0)
  /// Controls the entire vertical space allocated to the button bar
  final double barHeight;

  /// Minimum width for buttons to ensure consistent sizing (default: 120.0)
  /// Expands dynamically if text is longer than minimum width
  final double minButtonWidth;

  /// Color set for the button bar
  /// Defines the primary button color, text color, and background color
  /// Use BottomBarColorSet.primary for default blue theme
  /// Use BottomBarColorSet.secondary for teal theme (indicates completion/awaiting)
  final BottomBarColorSet colorSet;

  const BottomButtonBar({
    super.key,
    this.primaryButton,
    this.actionButtons,
    this.onAbort,
    this.onSkip,
    this.abortLabel = 'Avbryt',
    this.useRow = false,
    this.buttonSpacing = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.showAbortButton = true,
    this.buttonHeight = 75.0,
    this.fontSize = 30.0,
    this.debugMode,
    this.barHeight = 150.0,
    this.minButtonWidth = 120.0,
    this.colorSet = BottomBarColorSet.primary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use provided debugMode or read from provider (only when needed)
    final bool effectiveDebugMode = debugMode ?? ref.watch(debugModeProvider);
    
    final allButtons = _buildButtonList();

    // If no buttons at all, return empty container
    if (allButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Main button bar content - full width, fixed height container
    final mainContent = Container(
      width: double.infinity,
      height: barHeight,
      color: colorSet.backgroundColor.withAlpha((255 * 0.5).toInt()),
      child: Center(
        child: Padding(
          padding: padding,
          child: _buildButtonContainer(allButtons, context),
        ),
      ),
    );

    // If debug mode, add debug buttons in corner overlays
    if (effectiveDebugMode) {
      final List<Widget> debugChildren = [
        // Main button bar
        mainContent,
      ];

      // X button positioned at bottom-right corner
      if (onAbort != null) {
        debugChildren.add(
          Positioned(
            bottom: 8,
            right: 16,
            child: SizedBox(
              height: buttonHeight * 0.8,
              width: buttonHeight * 0.8,
              child: TextButton(
                onPressed: onAbort,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.close, size: 28),
              ),
            ),
          ),
        );
      }

      // Skip arrow button positioned at bottom-left corner
      if (onSkip != null) {
        debugChildren.add(
          Positioned(
            bottom: 8,
            left: 16,
            child: SizedBox(
              height: buttonHeight * 0.8,
              width: buttonHeight * 0.8,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.arrow_forward, size: 28),
              ),
            ),
          ),
        );
      }

      if (debugChildren.length > 1) {
        return Stack(
          clipBehavior: Clip.none,
          children: debugChildren,
        );
      }
    }

    return mainContent;
  }

  /// Builds the button list combining primaryButton and actionButtons
  List<BottomButton> _buildButtonList() {
    final buttons = <BottomButton>[];
    if (primaryButton != null) {
      buttons.add(primaryButton!);
    }
    if (actionButtons != null) {
      buttons.addAll(actionButtons!);
    }
    return buttons;
  }

  /// Builds the container for action buttons (row or column layout)
  Widget _buildButtonContainer(List<BottomButton> buttons, BuildContext context) {
    if (useRow && buttons.length <= 2) {
      return _buildRowLayout(buttons, context);
    } else {
      return _buildColumnLayout(buttons, context);
    }
  }

  /// Builds buttons in a horizontal row
  Widget _buildRowLayout(List<BottomButton> buttons, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          _buildActionButton(buttons[i], context),
          if (i < buttons.length - 1) SizedBox(width: buttonSpacing),
        ],
      ],
    );
  }

  /// Builds buttons in a vertical column
  Widget _buildColumnLayout(List<BottomButton> buttons, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          _buildActionButton(buttons[i], context),
          if (i < buttons.length - 1) SizedBox(height: buttonSpacing),
        ],
      ],
    );
  }

  /// Builds a single action button widget with dynamic width
  Widget _buildActionButton(BottomButton button, BuildContext context) {
    Widget buttonContent = button.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: button.label == 'Tilbake'
                ? [
                    Icon(button.icon, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      button.label,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                    ),
                  ]
                : [
                    Text(
                      button.label,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(button.icon, size: 24),
                  ],
          )
        : Text(
            button.label,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          );

    // Build the button widget based on type
    Widget buttonWidget;
    switch (button.type) {
      case BottomButtonType.filled:
        buttonWidget = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorSet.primaryButton,
            foregroundColor: colorSet.primaryButtonText,
            disabledBackgroundColor: colorSet.primaryButtonDisabled.withValues(alpha: 0.4),
            disabledForegroundColor: colorSet.primaryButtonDisabledText.withValues(alpha: 0.6),
          ),
          onPressed: button.enabled ? button.onPressed : null,
          child: buttonContent,
        );
        break;
      case BottomButtonType.outlined:
        buttonWidget = OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorSet.primaryButton, width: 2),
            foregroundColor: colorSet.primaryButtonText,
            backgroundColor: colorSet.primaryButton,
            disabledBackgroundColor: colorSet.primaryButtonDisabled.withValues(alpha: 0.4),
            disabledForegroundColor: colorSet.primaryButtonDisabledText.withValues(alpha: 0.6),
          ),
          onPressed: button.enabled ? button.onPressed : null,
          child: buttonContent,
        );
        break;
      case BottomButtonType.abort:
        buttonWidget = TextButton(
          onPressed: button.enabled ? button.onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.errorRed,
            disabledForegroundColor: AppColors.errorRed.withValues(alpha: 0.5),
          ),
          child: buttonContent,
        );
        break;
    }

    // Use ConstrainedBox with IntrinsicWidth for dynamic sizing
    return SizedBox(
      height: buttonHeight,
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minButtonWidth),
          child: buttonWidget,
        ),
      ),
    );
  }

  /// Builds the abort button with red styling
  Widget _buildAbortButton() {
    return SizedBox(
      height: buttonHeight,
      child: TextButton(
        onPressed: onAbort,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.errorRed,
        ),
        child: Text(
          abortLabel,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Convenience builders for common button bar patterns

/// Creates a simple finish button at the bottom
BottomButtonBar simpleFinishButton({
  required VoidCallback onFinish,
  VoidCallback? onAbort,
  String finishLabel = 'Fullfør',
  String abortLabel = 'Avbryt',
  double? buttonHeight,
  double? fontSize,
  bool debugMode = false,
}) {
  return BottomButtonBar(
    primaryButton: BottomButton(
      label: finishLabel,
      onPressed: onFinish,
      type: BottomButtonType.filled,
    ),
    onAbort: onAbort,
    abortLabel: abortLabel,
    buttonHeight: buttonHeight ?? 56.0,
    fontSize: fontSize ?? 16.0,
    debugMode: debugMode,
  );
}

/// Creates a continue button at the bottom
BottomButtonBar continueButton({
  required VoidCallback onContinue,
  VoidCallback? onAbort,
  String continueLabel = 'Fortsett',
  String abortLabel = 'Avbryt',
  double? buttonHeight,
  double? fontSize,
  bool debugMode = false,
}) {
  return BottomButtonBar(
    primaryButton: BottomButton(
      label: continueLabel,
      onPressed: onContinue,
      type: BottomButtonType.filled,
    ),
    onAbort: onAbort,
    abortLabel: abortLabel,
    showAbortButton: onAbort != null,
    buttonHeight: buttonHeight ?? 56.0,
    fontSize: fontSize ?? 16.0,
    debugMode: debugMode,
  );
}

/// Creates a retry/continue pair at the bottom
BottomButtonBar retryAndContinueButtons({
  required VoidCallback onRetry,
  required VoidCallback onContinue,
  VoidCallback? onAbort,
  String retryLabel = 'Prøv igjen',
  String continueLabel = 'Fortsett',
  String abortLabel = 'Avbryt',
  double? buttonHeight,
  double? fontSize,
  bool debugMode = false,
}) {
  return BottomButtonBar(
    actionButtons: [
      BottomButton(
        label: retryLabel,
        onPressed: onRetry,
        type: BottomButtonType.outlined,
      ),
      BottomButton(
        label: continueLabel,
        onPressed: onContinue,
        type: BottomButtonType.filled,
      ),
    ],
    onAbort: onAbort,
    abortLabel: abortLabel,
    useRow: true,
    showAbortButton: onAbort != null,
    buttonHeight: buttonHeight ?? 56.0,
    fontSize: fontSize ?? 16.0,
    debugMode: debugMode,
  );
}
