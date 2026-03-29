import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_master_app/l10n/strings.dart';
import 'package:flutter_master_app/l10n/strings_en.dart';
import 'package:flutter_master_app/l10n/strings_no.dart';

enum AppLocale { english, norwegian }

class LanguageNotifier extends AsyncNotifier<AppLocale> {
  static const String _languageKey = 'app_language';

  @override
  Future<AppLocale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'english';
    return AppLocale.values.firstWhere(
      (locale) => locale.toString().split('.').last == languageCode,
      orElse: () => AppLocale.english,
    );
  }

  Future<void> setLanguage(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = locale.toString().split('.').last;
    await prefs.setString(_languageKey, localeCode);
    state = AsyncValue.data(locale);
  }
}

final languageProvider = AsyncNotifierProvider<LanguageNotifier, AppLocale>(
  LanguageNotifier.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final languageAsync = ref.watch(languageProvider);
  return languageAsync.when(
    data: (locale) {
      return locale == AppLocale.norwegian
          ? NorwegianStrings()
          : EnglishStrings();
    },
    loading: () => EnglishStrings(), // Default to English while loading
    error: (err, stack) => EnglishStrings(), // Default to English on error
  );
});
