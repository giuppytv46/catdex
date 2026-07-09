import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleControllerProvider =
    AsyncNotifierProvider<AppLocaleController, Locale?>(
      AppLocaleController.new,
    );

class AppLocaleController extends AsyncNotifier<Locale?> {
  static const _preferenceKey = 'catdex_selected_locale';

  @override
  Future<Locale?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLocale = preferences.getString(_preferenceKey);
    final locale = savedLocale == null ? null : parseLocale(savedLocale);
    debugPrint('CATDEX_APP_LOCALE ${localeTag(locale) ?? 'not_selected'}');
    return locale;
  }

  Future<void> selectLocale(
    Locale locale, {
    bool changedFromSettings = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final tag = localeTag(locale)!;
    await preferences.setString(_preferenceKey, tag);
    state = AsyncData(locale);
    debugPrint('CATDEX_LANGUAGE_SELECTED $tag');
    debugPrint('CATDEX_LOCALE_APPLIED $tag');
    debugPrint('CATDEX_APP_LOCALE $tag');
    if (changedFromSettings) {
      debugPrint('CATDEX_LANGUAGE_CHANGED_FROM_SETTINGS $tag');
    }
  }
}

String? localeTag(Locale? locale) {
  if (locale == null) {
    return null;
  }
  final countryCode = locale.countryCode;
  return countryCode == null || countryCode.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}_$countryCode';
}

Locale parseLocale(String value) {
  final parts = value.split(RegExp('[-_]'));
  return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}
