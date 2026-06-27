import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CatDexLocalizations {
  const CatDexLocalizations(this.locale);

  final Locale locale;

  static const appName = 'CatDex';

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _CatDexLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static CatDexLocalizations of(BuildContext context) {
    return Localizations.of<CatDexLocalizations>(context, CatDexLocalizations)!;
  }

  String get splashTitle => _localizedValue(
    en: 'Splash',
    it: 'Avvio',
    es: 'Inicio',
    fr: 'Lancement',
    de: 'Start',
    ja: 'Splash',
  );

  String get onboardingTitle => _localizedValue(
    en: 'Onboarding',
    it: 'Introduzione',
    es: 'Bienvenida',
    fr: 'Accueil',
    de: 'Einfuhrung',
    ja: 'Onboarding',
  );

  String get loginTitle => _localizedValue(
    en: 'Login',
    it: 'Accesso',
    es: 'Acceso',
    fr: 'Connexion',
    de: 'Anmeldung',
    ja: 'Login',
  );

  String get homeTitle => _localizedValue(
    en: 'Home',
    it: 'Home',
    es: 'Inicio',
    fr: 'Accueil',
    de: 'Home',
    ja: 'Home',
  );

  String get captureTitle => _localizedValue(
    en: 'Capture',
    it: 'Cattura',
    es: 'Captura',
    fr: 'Capture',
    de: 'Fangen',
    ja: 'Capture',
  );

  String get catDexTitle => _localizedValue(
    en: 'CatDex',
    it: 'CatDex',
    es: 'CatDex',
    fr: 'CatDex',
    de: 'CatDex',
    ja: 'CatDex',
  );

  String get friendsTitle => _localizedValue(
    en: 'Friends',
    it: 'Amici',
    es: 'Amigos',
    fr: 'Amis',
    de: 'Freunde',
    ja: 'Friends',
  );

  String get profileTitle => _localizedValue(
    en: 'Profile',
    it: 'Profilo',
    es: 'Perfil',
    fr: 'Profil',
    de: 'Profil',
    ja: 'Profile',
  );

  String get settingsTitle => _localizedValue(
    en: 'Settings',
    it: 'Impostazioni',
    es: 'Ajustes',
    fr: 'Parametres',
    de: 'Einstellungen',
    ja: 'Settings',
  );

  String get offlineTitle => _localizedValue(
    en: 'Offline',
    it: 'Offline',
    es: 'Sin conexion',
    fr: 'Hors ligne',
    de: 'Offline',
    ja: 'Offline',
  );

  String get globalErrorTitle => _localizedValue(
    en: 'Something went wrong',
    it: 'Qualcosa non ha funzionato',
    es: 'Algo salio mal',
    fr: 'Un probleme est survenu',
    de: 'Etwas ist schiefgelaufen',
    ja: 'Something went wrong',
  );

  String get unknownRouteTitle => _localizedValue(
    en: 'Page not found',
    it: 'Pagina non trovata',
    es: 'Pagina no encontrada',
    fr: 'Page introuvable',
    de: 'Seite nicht gefunden',
    ja: 'Page not found',
  );

  String _localizedValue({
    required String en,
    required String it,
    required String es,
    required String fr,
    required String de,
    required String ja,
  }) {
    return switch (locale.languageCode) {
      'it' => it,
      'es' => es,
      'fr' => fr,
      'de' => de,
      'ja' => ja,
      _ => en,
    };
  }
}

class _CatDexLocalizationsDelegate
    extends LocalizationsDelegate<CatDexLocalizations> {
  const _CatDexLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return CatDexLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<CatDexLocalizations> load(Locale locale) {
    return SynchronousFuture<CatDexLocalizations>(CatDexLocalizations(locale));
  }

  @override
  bool shouldReload(_CatDexLocalizationsDelegate old) => false;
}
