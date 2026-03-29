import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable info screen widget with consistent styling
/// Shows a title and optional subtitle with large, bold, primary color text
/// Can be used as simple text info screens throughout the application
/// 
/// Example usage:
/// ```dart
/// RoundInfoScreen(
///   title: 'Runde 1',
///   subtitle: 'Se på fargen, ikke ordet',
///   bottomContent: BottomButtonBar(...),
/// )
/// ```
class RoundInfoScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? bottomContent;

  const RoundInfoScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.bottomContent,
  });

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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.crayolaBlue,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.crayolaBlue,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (bottomContent != null) bottomContent!,
      ],
    );
  }
}
