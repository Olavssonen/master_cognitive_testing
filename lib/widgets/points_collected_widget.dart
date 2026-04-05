import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A widget that displays points earned with a smooth upward animation and fade-out effect.
/// 
/// Can be used in two ways:
/// 1. Directly in a widget tree: Add to a Stack for more control
/// 2. Via the static `show()` method: Uses Overlay for quick, dynamic placement
class PointsCollectedWidget extends StatefulWidget {
  /// The number of points to display
  final int points;

  /// The position where the animation starts (relative to parent or screen)
  final Offset position;

  /// Optional callback when animation completes
  final VoidCallback? onComplete;

  /// Duration of the animation (default: 800ms)
  final Duration duration;

  /// Color of the points text (default: tropicalTeal for positive, errorRed for negative)
  final Color? color;

  /// Font size for the points text (default: displayMedium)
  final double? fontSize;

  const PointsCollectedWidget({
    super.key,
    required this.points,
    required this.position,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
    this.color,
    this.fontSize,
  });

  @override
  State<PointsCollectedWidget> createState() => _PointsCollectedWidgetState();

  /// Shows a points collected animation using the Overlay system.
  /// This is the easiest way to use this widget - just call it whenever points are earned.
  ///
  /// Example:
  /// ```dart
  /// PointsCollectedWidget.show(
  ///   context: context,
  ///   points: 50,
  ///   position: Offset(renderBox.size.width / 2, renderBox.size.height / 2),
  ///   color: AppColors.successGreen,
  /// );
  /// ```
  static void show({
    required BuildContext context,
    required int points,
    required Offset position,
    Duration duration = const Duration(milliseconds: 800),
    Color? color,
    double? fontSize,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 50, // Center the widget (better for larger fontSize)
        top: position.dy, // Start at word position to flow upward from it
        child: IgnorePointer(
          child: PointsCollectedWidget(
            points: points,
            position: Offset.zero,
            duration: duration,
            color: color,
            fontSize: fontSize,
            onComplete: () {
              entry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _PointsCollectedWidgetState extends State<PointsCollectedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Fade out animation: stays visible for 70% of duration, then fades
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Upward movement: smooth ease out
    _position = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -60), // Move up 60 pixels
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the text with proper sign
    final displayText = widget.points < 0 
      ? '${widget.points}' // Already has minus sign
      : '+${widget.points}';
    
    // Determine color: use provided color, or default based on positive/negative
    final displayColor = widget.color ?? 
      (widget.points < 0 ? AppColors.errorRed : AppColors.tropicalTeal);
    
    // Get font size - use provided or default to displayMedium
    final fontSizeValue = widget.fontSize;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _position.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              displayText,
              style: fontSizeValue != null
                ? TextStyle(
                    fontSize: fontSizeValue,
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  )
                : Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: displayColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
            ),
          ),
        );
      },
    );
  }
}
