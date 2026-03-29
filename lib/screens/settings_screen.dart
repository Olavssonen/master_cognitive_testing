import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/providers/test_providers.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'package:flutter_master_app/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugMode = ref.watch(debugModeProvider);
    final strings = ref.watch(appStringsProvider);
    final languageAsync = ref.watch(languageProvider);

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Text(
                  strings.settings,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Debug Mode Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.lavender,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.debug,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Switch(
                          value: debugMode,
                          onChanged: (value) {
                            ref.read(debugModeProvider.notifier).set(value);
                          },
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Points Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.lavender,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.points,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Language Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.lavender,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.language,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        languageAsync.when(
                          data: (currentLocale) {
                            // Build items list with current language first, then others
                            final items = <DropdownMenuItem<AppLocale>>[];
                            
                            // Add current locale first
                            if (currentLocale == AppLocale.english) {
                              items.add(const DropdownMenuItem(
                                value: AppLocale.english,
                                child: Text('English'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.norwegian,
                                child: Text('Norsk'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.spanish,
                                child: Text('Español'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.swedish,
                                child: Text('Svenska'),
                              ));
                            } else if (currentLocale == AppLocale.norwegian) {
                              items.add(const DropdownMenuItem(
                                value: AppLocale.norwegian,
                                child: Text('Norsk'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.english,
                                child: Text('English'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.spanish,
                                child: Text('Español'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.swedish,
                                child: Text('Svenska'),
                              ));
                            } else if (currentLocale == AppLocale.spanish) {
                              items.add(const DropdownMenuItem(
                                value: AppLocale.spanish,
                                child: Text('Español'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.english,
                                child: Text('English'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.norwegian,
                                child: Text('Norsk'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.swedish,
                                child: Text('Svenska'),
                              ));
                            } else {
                              items.add(const DropdownMenuItem(
                                value: AppLocale.swedish,
                                child: Text('Svenska'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.english,
                                child: Text('English'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.norwegian,
                                child: Text('Norsk'),
                              ));
                              items.add(const DropdownMenuItem(
                                value: AppLocale.spanish,
                                child: Text('Español'),
                              ));
                            }
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<AppLocale>(
                                value: currentLocale,
                                items: items,
                                onChanged: (AppLocale? newLocale) {
                                  if (newLocale != null) {
                                    ref
                                        .read(languageProvider.notifier)
                                        .setLanguage(newLocale);
                                  }
                                },
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                                underline: const SizedBox.shrink(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                isExpanded: false,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            width: 100,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, stack) => Text('Error'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
