import 'package:flutter/material.dart';

/// A reusable full-screen overlay widget that displays a message
/// and fades away after a specified duration.
/// 
/// Can be used at any point in a test to show information,
/// instructions, or messages to the user.
/// 
/// Usage (Simple fade):
/// ```dart
/// FullScreenOverlay(
///   child: yourTestWidget,
///   text: 'Get ready...',
///   duration: const Duration(seconds: 2),
/// )
/// ```
/// 
/// Usage (Animate text to position):
/// ```dart
/// FullScreenOverlay(
///   child: yourTestWidget,
///   text: 'Get ready...',
///   duration: const Duration(seconds: 2),
///   animateTo: Offset(0, -0.3), // Target position
///   maxTextWidth: 400, // Constrain width for consistent wrapping
/// )
/// ```
class FullScreenOverlay extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final String? text;
  final Offset? animateTo;
  final double? maxTextWidth;

  const FullScreenOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.text,
    this.animateTo,
    this.maxTextWidth,
  });

  @override
  State<FullScreenOverlay> createState() => _FullScreenOverlayState();
}

class _FullScreenOverlayState extends State<FullScreenOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller for fade-out effect
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Tween for fading from 1.0 (opaque) to 0.0 (transparent)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCirc),
    );

    // Position animation if animateTo is specified
    if (widget.animateTo != null) {
      _positionAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: widget.animateTo!,
      ).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCirc),
      );
    } else {
      _positionAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_fadeController);
    }

    // Start fade-out animation after the specified duration
    Future.delayed(widget.duration, () {
      if (mounted && !_animationStarted) {
        _startAnimation();
      }
    });
  }

  void _startAnimation() {
    if (!_animationStarted) {
      setState(() {
        _animationStarted = true;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Underlying test widget
        widget.child,
        
        // Fade-out overlay that covers the screen
        // Only use GestureDetector when animation hasn't started yet
        if (!_animationStarted)
          GestureDetector(
            onTap: _startAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: widget.text != null
                    ? SlideTransition(
                        position: _positionAnimation,
                        child: Transform.translate(
                          offset: const Offset(0, -40),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.maxTextWidth ?? MediaQuery.of(context).size.width * 0.85,
                              ),
                              child: Text(
                                widget.text!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          )
        else
          IgnorePointer(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: widget.text != null
                    ? SlideTransition(
                        position: _positionAnimation,
                        child: Transform.translate(
                          offset: const Offset(0, -40),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.maxTextWidth ?? MediaQuery.of(context).size.width * 0.85,
                              ),
                              child: Text(
                                widget.text!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

