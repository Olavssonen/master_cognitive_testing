import 'package:flutter/material.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

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
class BottomButtonBar extends StatelessWidget {
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
  final bool debugMode;

  /// Fixed height for the button bar container (default: 200.0)
  /// Controls the entire vertical space allocated to the button bar
  final double barHeight;

  /// Minimum width for buttons to ensure consistent sizing (default: 120.0)
  /// Prevents buttons from shrinking when text is short
  final double minButtonWidth;

  const BottomButtonBar({
    super.key,
    this.primaryButton,
    this.actionButtons,
    this.onAbort,
    this.abortLabel = 'Avbryt',
    this.useRow = false,
    this.buttonSpacing = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.showAbortButton = true,
    this.buttonHeight = 75.0,
    this.fontSize = 30.0,
    this.debugMode = true,
    this.barHeight = 150.0,
    this.minButtonWidth = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final allButtons = _buildButtonList();
    final hasAbortButton = onAbort != null && showAbortButton && !debugMode;

    // If no buttons at all, return empty container
    if (allButtons.isEmpty && !hasAbortButton && !debugMode) {
      return const SizedBox.shrink();
    }

    // Main button bar content - full width, fixed height container
    final mainContent = Container(
      width: double.infinity,
      height: barHeight,
      color: AppColors.crayolaBlue.withAlpha((255 * 0.5).toInt()),
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allButtons.isNotEmpty)
                _buildButtonContainer(allButtons, context),
              if (allButtons.isNotEmpty && hasAbortButton)
                SizedBox(height: buttonSpacing),
              if (hasAbortButton)
                _buildAbortButton(),
            ],
          ),
        ),
      ),
    );

    // If debug mode, place abort button in isolated corner using Stack
    if (debugMode && onAbort != null) {
      return SizedBox(
        width: double.infinity, // Expand to full width
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center, // Center children by default
          children: [
            // Main buttons centered
            Align(
              alignment: Alignment.center,
              child: mainContent,
            ),
            // X button positioned at bottom-right of screen - doesn't affect centering
            Positioned(
              bottom: 0,
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
          ],
        ),
      );
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
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: _buildActionButton(buttons[i], context)),
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

  /// Builds a single action button widget
  Widget _buildActionButton(BottomButton button, BuildContext context) {
    Widget buttonContent = button.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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

    switch (button.type) {
      case BottomButtonType.filled:
        return SizedBox(
          height: buttonHeight,
          width: minButtonWidth,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crayolaBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: button.enabled ? button.onPressed : null,
            child: buttonContent,
          ),
        );
      case BottomButtonType.outlined:
        return SizedBox(
          height: buttonHeight,
          width: minButtonWidth,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.crayolaBlue, width: 2),
              foregroundColor: AppColors.crayolaBlue,
            ),
            onPressed: button.enabled ? button.onPressed : null,
            child: buttonContent,
          ),
        );
      case BottomButtonType.abort:
        return SizedBox(
          height: buttonHeight,
          width: minButtonWidth,
          child: TextButton(
            onPressed: button.enabled ? button.onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: buttonContent,
          ),
        );
    }
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
