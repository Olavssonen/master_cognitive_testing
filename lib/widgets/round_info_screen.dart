import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable info screen widget with consistent styling
/// Shows a title, optional subtitle, and optional body text with clear visual hierarchy
/// Can be used as simple text info screens throughout the application
/// Text fades in smoothly when the widget is displayed.
/// 
/// Example usage:
/// ```dart
/// RoundInfoScreen(
///   title: 'Runde 1',
///   subtitle: 'Se på fargen, ikke ordet',
///   bodyText: 'Husk disse ordene',
///   bottomContent: BottomButtonBar(...),
/// )
/// ```
class RoundInfoScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? bodyText;
  final Widget? bottomContent;

  const RoundInfoScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.bodyText,
    this.bottomContent,
  });

  @override
  State<RoundInfoScreen> createState() => _RoundInfoScreenState();
}

class _RoundInfoScreenState extends State<RoundInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonBarController;
  late Animation<double> _buttonBarAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Button bar animation starts after text fade completes
    _buttonBarController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonBarController, curve: Curves.easeIn),
    );

    _fadeController.forward().then((_) {
      // Start button bar animation after text fade completes
      if (mounted) {
        _buttonBarController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title - largest, most prominent
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      
                      widget.title,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 120,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Subtitle - medium size, clear separation
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 180),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).colorScheme.primary,
                              decorationThickness: 1.5,
                              fontSize: 54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  // Body text - smaller, additional information
                  if (widget.bodyText != null && widget.bodyText!.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.bodyText!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 46,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Button bar with fade-in animation after text completes
        if (widget.bottomContent != null)
          FadeTransition(
            opacity: _buttonBarAnimation,
            child: widget.bottomContent!,
          ),
      ],
    );
  }
}
