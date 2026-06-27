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

  String get playerLevelLabel => _localizedValue(
    en: 'Level',
    it: 'Livello',
    es: 'Nivel',
    fr: 'Niveau',
    de: 'Level',
    ja: 'Level',
  );

  String get xpProgressLabel => _localizedValue(
    en: 'XP Progress',
    it: 'Progresso XP',
    es: 'Progreso XP',
    fr: 'Progression XP',
    de: 'XP Fortschritt',
    ja: 'XP Progress',
  );

  String get pawPointsLabel => _localizedValue(
    en: 'Paw Points',
    it: 'Punti Zampa',
    es: 'Puntos Garra',
    fr: 'Points Patte',
    de: 'Pfotenpunkte',
    ja: 'Paw Points',
  );

  String get dailyMissionsTitle => _localizedValue(
    en: 'Daily Missions',
    it: 'Missioni Giornaliere',
    es: 'Misiones Diarias',
    fr: 'Missions du Jour',
    de: 'Tagesmissionen',
    ja: 'Daily Missions',
  );

  String get discoverOneCatMission => _localizedValue(
    en: 'Discover 1 cat',
    it: 'Scopri 1 gatto',
    es: 'Descubre 1 gato',
    fr: 'Decouvre 1 chat',
    de: 'Entdecke 1 Katze',
    ja: 'Discover 1 cat',
  );

  String get importOnePhotoMission => _localizedValue(
    en: 'Import 1 photo',
    it: 'Importa 1 foto',
    es: 'Importa 1 foto',
    fr: 'Importe 1 photo',
    de: 'Importiere 1 Foto',
    ja: 'Import 1 photo',
  );

  String get visitCatDexMission => _localizedValue(
    en: 'Visit your CatDex',
    it: 'Visita il tuo CatDex',
    es: 'Visita tu CatDex',
    fr: 'Visite ton CatDex',
    de: 'Besuche dein CatDex',
    ja: 'Visit your CatDex',
  );

  String get completedLabel => _localizedValue(
    en: 'Completed',
    it: 'Completata',
    es: 'Completada',
    fr: 'Terminee',
    de: 'Abgeschlossen',
    ja: 'Completed',
  );

  String get notCompletedLabel => _localizedValue(
    en: 'Not completed',
    it: 'Non completata',
    es: 'No completada',
    fr: 'Non terminee',
    de: 'Nicht abgeschlossen',
    ja: 'Not completed',
  );

  String get recentDiscoveriesTitle => _localizedValue(
    en: 'Recent Discoveries',
    it: 'Scoperte Recenti',
    es: 'Descubrimientos Recientes',
    fr: 'Decouvertes Recentes',
    de: 'Neue Entdeckungen',
    ja: 'Recent Discoveries',
  );

  String get currentEventTitle => _localizedValue(
    en: 'Current Event',
    it: 'Evento Attuale',
    es: 'Evento Actual',
    fr: 'Evenement Actuel',
    de: 'Aktuelles Event',
    ja: 'Current Event',
  );

  String get quickActionsTitle => _localizedValue(
    en: 'Quick Actions',
    it: 'Azioni Rapide',
    es: 'Acciones Rapidas',
    fr: 'Actions Rapides',
    de: 'Schnellaktionen',
    ja: 'Quick Actions',
  );

  String get captureCatAction => _localizedValue(
    en: 'Capture Cat',
    it: 'Cattura Gatto',
    es: 'Capturar Gato',
    fr: 'Capturer Chat',
    de: 'Katze Fangen',
    ja: 'Capture Cat',
  );

  String get openCatDexAction => _localizedValue(
    en: 'Open CatDex',
    it: 'Apri CatDex',
    es: 'Abrir CatDex',
    fr: 'Ouvrir CatDex',
    de: 'CatDex Offnen',
    ja: 'Open CatDex',
  );

  String get viewProfileAction => _localizedValue(
    en: 'View Profile',
    it: 'Vedi Profilo',
    es: 'Ver Perfil',
    fr: 'Voir Profil',
    de: 'Profil Ansehen',
    ja: 'View Profile',
  );

  String get captureTitle => _localizedValue(
    en: 'Capture',
    it: 'Cattura',
    es: 'Captura',
    fr: 'Capture',
    de: 'Fangen',
    ja: 'Capture',
  );

  String get captureHeading => _localizedValue(
    en: 'Choose a cat photo',
    it: 'Scegli una foto di gatto',
    es: 'Elige una foto de gato',
    fr: 'Choisis une photo de chat',
    de: 'Wahle ein Katzenfoto',
    ja: 'Choose a cat photo',
  );

  String get captureEmptyMessage => _localizedValue(
    en: 'Take a new photo or import one from your gallery.',
    it: 'Scatta una nuova foto o importane una dalla galleria.',
    es: 'Toma una foto nueva o importala desde tu galeria.',
    fr: 'Prends une nouvelle photo ou importe-en une.',
    de: 'Mach ein neues Foto oder importiere eines.',
    ja: 'Take a new photo or import one from your gallery.',
  );

  String get takePhotoAction => _localizedValue(
    en: 'Take Photo',
    it: 'Scatta Foto',
    es: 'Tomar Foto',
    fr: 'Prendre Photo',
    de: 'Foto Machen',
    ja: 'Take Photo',
  );

  String get importFromGalleryAction => _localizedValue(
    en: 'Import from Gallery',
    it: 'Importa dalla Galleria',
    es: 'Importar de Galeria',
    fr: 'Importer de la Galerie',
    de: 'Aus Galerie Importieren',
    ja: 'Import from Gallery',
  );

  String get removeSelectedImageAction => _localizedValue(
    en: 'Remove selected image',
    it: 'Rimuovi immagine selezionata',
    es: 'Quitar imagen seleccionada',
    fr: 'Retirer image selectionnee',
    de: 'Ausgewahltes Bild entfernen',
    ja: 'Remove selected image',
  );

  String get continueAction => _localizedValue(
    en: 'Continue',
    it: 'Continua',
    es: 'Continuar',
    fr: 'Continuer',
    de: 'Weiter',
    ja: 'Continue',
  );

  String get selectedImageLabel => _localizedValue(
    en: 'Selected image preview',
    it: 'Anteprima immagine selezionata',
    es: 'Vista previa de imagen seleccionada',
    fr: 'Apercu de image selectionnee',
    de: 'Vorschau des ausgewahlten Bildes',
    ja: 'Selected image preview',
  );

  String get detectLocationAction => _localizedValue(
    en: 'Detect Location',
    it: 'Rileva Posizione',
    es: 'Detectar Ubicacion',
    fr: 'Detecter la Position',
    de: 'Standort Erkennen',
    ja: 'Detect Location',
  );

  String get detectedLocationLabel => _localizedValue(
    en: 'Detected location',
    it: 'Posizione rilevata',
    es: 'Ubicacion detectada',
    fr: 'Position detectee',
    de: 'Erkannter Standort',
    ja: 'Detected location',
  );

  String get coordinatesOnlyLabel => _localizedValue(
    en: 'Coordinates only',
    it: 'Solo coordinate',
    es: 'Solo coordenadas',
    fr: 'Coordonnees seulement',
    de: 'Nur Koordinaten',
    ja: 'Coordinates only',
  );

  String get locationUnavailableLabel => _localizedValue(
    en: 'Location unavailable',
    it: 'Posizione non disponibile',
    es: 'Ubicacion no disponible',
    fr: 'Position indisponible',
    de: 'Standort nicht verfugbar',
    ja: 'Location unavailable',
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
