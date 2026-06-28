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

  String get onboardingDiscoverTitle => _localizedValue(
    en: 'Discover real cats',
    it: 'Scopri gatti reali',
    es: 'Descubre gatos reales',
    fr: 'Decouvre de vrais chats',
    de: 'Entdecke echte Katzen',
    ja: 'Discover real cats',
  );

  String get onboardingDiscoverMessage => _localizedValue(
    en: 'Take or import a cat photo whenever you find a new friend.',
    it: 'Scatta o importa una foto quando trovi un nuovo amico.',
    es: 'Toma o importa una foto cuando encuentres un nuevo amigo.',
    fr: 'Prends ou importe une photo quand tu trouves un nouvel ami.',
    de: 'Mache oder importiere ein Foto, wenn du eine neue Katze findest.',
    ja: 'Take or import a cat photo whenever you find a new friend.',
  );

  String get onboardingCardsTitle => _localizedValue(
    en: 'AI creates collectible cards',
    it: 'L AI crea carte collezionabili',
    es: 'La IA crea cartas coleccionables',
    fr: 'L IA cree des cartes a collectionner',
    de: 'KI erstellt Sammelkarten',
    ja: 'AI creates collectible cards',
  );

  String get onboardingCardsMessage => _localizedValue(
    en: 'CatDex turns each discovery into species, traits, rarity, and story.',
    it: 'CatDex trasforma ogni scoperta in specie, tratti, rarita e storia.',
    es: 'CatDex convierte cada hallazgo en especie, rasgos, rareza e historia.',
    fr:
        'CatDex transforme chaque decouverte en espece, traits, rarete et '
        'histoire.',
    de:
        'CatDex verwandelt jede Entdeckung in Art, Merkmale, Seltenheit und '
        'Story.',
    ja: 'CatDex turns each discovery into species, traits, rarity, and story.',
  );

  String get onboardingLevelTitle => _localizedValue(
    en: 'Build your CatDex',
    it: 'Costruisci il tuo CatDex',
    es: 'Construye tu CatDex',
    fr: 'Construis ton CatDex',
    de: 'Baue dein CatDex auf',
    ja: 'Build your CatDex',
  );

  String get onboardingLevelMessage => _localizedValue(
    en: 'Save discoveries, grow your collection, earn XP, and level up.',
    it: 'Salva scoperte, amplia la collezione, guadagna XP e sali di livello.',
    es: 'Guarda hallazgos, amplia tu coleccion, gana XP y sube de nivel.',
    fr: 'Sauvegarde tes decouvertes, agrandis ta collection, gagne de l XP.',
    de:
        'Speichere Entdeckungen, erweitere die Sammlung, verdiene XP und '
        'Levels.',
    ja: 'Save discoveries, grow your collection, earn XP, and level up.',
  );

  String get mascotPlaceholderTitle => _localizedValue(
    en: 'Meet your CatDex guide',
    it: 'Incontra la guida CatDex',
    es: 'Conoce tu guia CatDex',
    fr: 'Rencontre ton guide CatDex',
    de: 'Triff deinen CatDex-Guide',
    ja: 'Meet your CatDex guide',
  );

  String get mascotPlaceholderMessage => _localizedValue(
    en: 'A polished mascot illustration will land here before beta.',
    it: 'Qui arrivera una mascotte rifinita prima della beta.',
    es: 'Aqui llegara una mascota final antes de la beta.',
    fr: 'Une mascotte finalisee arrivera ici avant la beta.',
    de: 'Hier erscheint vor der Beta eine fertige Maskottchen-Illustration.',
    ja: 'A polished mascot illustration will land here before beta.',
  );

  String get permissionEducationTitle => _localizedValue(
    en: 'Permissions when you need them',
    it: 'Permessi solo quando servono',
    es: 'Permisos cuando hagan falta',
    fr: 'Permissions seulement au bon moment',
    de: 'Berechtigungen erst wenn notig',
    ja: 'Permissions when you need them',
  );

  String get cameraEducationTitle => _localizedValue(
    en: 'Camera',
    it: 'Fotocamera',
    es: 'Camara',
    fr: 'Camera',
    de: 'Kamera',
    ja: 'Camera',
  );

  String get cameraEducationMessage => _localizedValue(
    en: 'Asked only when you choose Take Photo.',
    it: 'Richiesta solo quando scegli Scatta Foto.',
    es: 'Se pide solo cuando eliges Tomar Foto.',
    fr: 'Demandee seulement quand tu choisis Prendre une Photo.',
    de: 'Wird erst gefragt, wenn du Foto aufnehmen wahlst.',
    ja: 'Asked only when you choose Take Photo.',
  );

  String get photosEducationTitle => _localizedValue(
    en: 'Photos',
    it: 'Foto',
    es: 'Fotos',
    fr: 'Photos',
    de: 'Fotos',
    ja: 'Photos',
  );

  String get photosEducationMessage => _localizedValue(
    en: 'Asked only when you import from your gallery.',
    it: 'Richiesto solo quando importi dalla galleria.',
    es: 'Se pide solo cuando importas desde la galeria.',
    fr: 'Demandee seulement quand tu importes depuis ta galerie.',
    de: 'Wird erst gefragt, wenn du aus der Galerie importierst.',
    ja: 'Asked only when you import from your gallery.',
  );

  String get locationEducationTitle => _localizedValue(
    en: 'Location',
    it: 'Posizione',
    es: 'Ubicacion',
    fr: 'Position',
    de: 'Standort',
    ja: 'Location',
  );

  String get locationEducationMessage => _localizedValue(
    en: 'Asked only when you choose to add discovery location.',
    it: 'Richiesta solo quando scegli di aggiungere il luogo della scoperta.',
    es: 'Se pide solo cuando eliges agregar ubicacion al hallazgo.',
    fr: 'Demandee seulement quand tu ajoutes le lieu de decouverte.',
    de: 'Wird erst gefragt, wenn du den Fundort hinzufugst.',
    ja: 'Asked only when you choose to add discovery location.',
  );

  String get continueAsGuestAction => _localizedValue(
    en: 'Continue as Guest',
    it: 'Continua come Ospite',
    es: 'Continuar como Invitado',
    fr: 'Continuer en Invite',
    de: 'Als Gast fortfahren',
    ja: 'Continue as Guest',
  );

  String get onboardingSignInAction => _localizedValue(
    en: 'Sign in',
    it: 'Accedi',
    es: 'Iniciar sesion',
    fr: 'Se connecter',
    de: 'Einloggen',
    ja: 'Sign in',
  );

  String get onboardingLoadingMessage => _localizedValue(
    en: 'Preparing your CatDex...',
    it: 'Prepariamo il tuo CatDex...',
    es: 'Preparando tu CatDex...',
    fr: 'Preparation de ton CatDex...',
    de: 'Dein CatDex wird vorbereitet...',
    ja: 'Preparing your CatDex...',
  );

  String get loginTitle => _localizedValue(
    en: 'Login',
    it: 'Accesso',
    es: 'Acceso',
    fr: 'Connexion',
    de: 'Anmeldung',
    ja: 'Login',
  );

  String get authWelcomeTitle => _localizedValue(
    en: 'Welcome to CatDex',
    it: 'Benvenuto in CatDex',
    es: 'Bienvenido a CatDex',
    fr: 'Bienvenue dans CatDex',
    de: 'Willkommen bei CatDex',
    ja: 'Welcome to CatDex',
  );

  String get authWelcomeMessage => _localizedValue(
    en: 'Sign in or create an account to prepare for future cloud sync.',
    it:
        'Accedi o crea un account per preparare la futura '
        'sincronizzazione cloud.',
    es:
        'Inicia sesion o crea una cuenta para preparar la futura '
        'sincronizacion.',
    fr:
        'Connecte-toi ou cree un compte pour preparer la future '
        'synchronisation.',
    de:
        'Melde dich an oder erstelle ein Konto fur die spatere '
        'Cloud-Synchronisierung.',
    ja: 'Sign in or create an account to prepare for future cloud sync.',
  );

  String get emailLabel => _localizedValue(
    en: 'Email',
    it: 'Email',
    es: 'Email',
    fr: 'Email',
    de: 'Email',
    ja: 'Email',
  );

  String get passwordLabel => _localizedValue(
    en: 'Password',
    it: 'Password',
    es: 'Contrasena',
    fr: 'Mot de passe',
    de: 'Passwort',
    ja: 'Password',
  );

  String get loginAction => _localizedValue(
    en: 'Log In',
    it: 'Accedi',
    es: 'Iniciar Sesion',
    fr: 'Se Connecter',
    de: 'Einloggen',
    ja: 'Log In',
  );

  String get signupAction => _localizedValue(
    en: 'Sign Up',
    it: 'Registrati',
    es: 'Registrarse',
    fr: 'Creer un Compte',
    de: 'Registrieren',
    ja: 'Sign Up',
  );

  String get logoutAction => _localizedValue(
    en: 'Log Out',
    it: 'Esci',
    es: 'Cerrar Sesion',
    fr: 'Se Deconnecter',
    de: 'Ausloggen',
    ja: 'Log Out',
  );

  String get signedInEmailLabel => _localizedValue(
    en: 'Signed in email',
    it: 'Email collegata',
    es: 'Email conectada',
    fr: 'Email connecte',
    de: 'Angemeldete Email',
    ja: 'Signed in email',
  );

  String get guestModeTitle => _localizedValue(
    en: 'Guest / Local Mode',
    it: 'Modalita Ospite Locale',
    es: 'Modo Invitado Local',
    fr: 'Mode Invite Local',
    de: 'Gast- und Lokalmodus',
    ja: 'Guest / Local Mode',
  );

  String get guestModeMessage => _localizedValue(
    en:
        'You can keep exploring locally. Cloud sync will be available '
        'after login.',
    it:
        'Puoi continuare a esplorare in locale. La sincronizzazione cloud '
        'arrivera dopo il login.',
    es:
        'Puedes seguir explorando localmente. La sincronizacion llegara '
        'tras iniciar sesion.',
    fr:
        'Tu peux continuer en local. La synchronisation sera disponible '
        'apres connexion.',
    de:
        'Du kannst lokal weiterspielen. Cloud-Synchronisierung folgt nach '
        'dem Login.',
    ja:
        'You can keep exploring locally. Cloud sync will be available '
        'after login.',
  );

  String authFailureMessage(String code) {
    return switch (code) {
      'missingEmail' => _localizedValue(
        en: 'Enter your email address.',
        it: 'Inserisci il tuo indirizzo email.',
        es: 'Introduce tu email.',
        fr: 'Entre ton adresse email.',
        de: 'Gib deine Email-Adresse ein.',
        ja: 'Enter your email address.',
      ),
      'missingPassword' => _localizedValue(
        en: 'Enter your password.',
        it: 'Inserisci la password.',
        es: 'Introduce tu contrasena.',
        fr: 'Entre ton mot de passe.',
        de: 'Gib dein Passwort ein.',
        ja: 'Enter your password.',
      ),
      'invalidCredentials' => _localizedValue(
        en: 'Those login details did not work. Please try again.',
        it: 'Questi dati non funzionano. Riprova.',
        es: 'Estos datos no funcionaron. Intentalo otra vez.',
        fr: 'Ces identifiants ne fonctionnent pas. Reessaie.',
        de: 'Diese Anmeldedaten funktionieren nicht. Versuch es erneut.',
        ja: 'Those login details did not work. Please try again.',
      ),
      _ => _localizedValue(
        en: 'CatDex could not complete that auth request yet.',
        it: 'CatDex non puo completare questa richiesta di accesso.',
        es: 'CatDex no pudo completar esta solicitud.',
        fr: 'CatDex ne peut pas terminer cette demande.',
        de: 'CatDex konnte diese Anmeldung noch nicht abschliessen.',
        ja: 'CatDex could not complete that auth request yet.',
      ),
    };
  }

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

  String get analysisTitle => _localizedValue(
    en: 'Analysis',
    it: 'Analisi',
    es: 'Analisis',
    fr: 'Analyse',
    de: 'Analyse',
    ja: 'Analysis',
  );

  String get analysisPreparingTitle => _localizedValue(
    en: 'Reading cat magic...',
    it: 'Lettura magia felina...',
    es: 'Leyendo magia felina...',
    fr: 'Lecture de magie feline...',
    de: 'Katzenmagie wird gelesen...',
    ja: 'Reading cat magic...',
  );

  String get analysisPreparingMessage => _localizedValue(
    en: 'CatDex is preparing a local fake analysis result.',
    it: 'CatDex sta preparando una finta analisi locale.',
    es: 'CatDex prepara un resultado falso local.',
    fr: 'CatDex prepare une fausse analyse locale.',
    de: 'CatDex erstellt eine lokale Fake-Analyse.',
    ja: 'CatDex is preparing a local fake analysis result.',
  );

  String get analysisResultTitle => _localizedValue(
    en: 'Fake Analysis Result',
    it: 'Risultato Analisi Finta',
    es: 'Resultado Falso',
    fr: 'Resultat Fictif',
    de: 'Fake-Analyse Ergebnis',
    ja: 'Fake Analysis Result',
  );

  String get breedLabel => _localizedValue(
    en: 'Breed',
    it: 'Razza',
    es: 'Raza',
    fr: 'Race',
    de: 'Rasse',
    ja: 'Breed',
  );

  String get catNameLabel => _localizedValue(
    en: 'Cat Name',
    it: 'Nome Gatto',
    es: 'Nombre del Gato',
    fr: 'Nom du Chat',
    de: 'Katzenname',
    ja: 'Cat Name',
  );

  String get catNamePlaceholder => _localizedValue(
    en: 'Mochi',
    it: 'Mochi',
    es: 'Mochi',
    fr: 'Mochi',
    de: 'Mochi',
    ja: 'Mochi',
  );

  String get confidenceLabel => _localizedValue(
    en: 'Confidence',
    it: 'Confidenza',
    es: 'Confianza',
    fr: 'Confiance',
    de: 'Vertrauen',
    ja: 'Confidence',
  );

  String get variantLabel => _localizedValue(
    en: 'Variant',
    it: 'Variante',
    es: 'Variante',
    fr: 'Variante',
    de: 'Variante',
    ja: 'Variant',
  );

  String get storyLabel => _localizedValue(
    en: 'Story',
    it: 'Storia',
    es: 'Historia',
    fr: 'Histoire',
    de: 'Geschichte',
    ja: 'Story',
  );

  String get moodLabel => _localizedValue(
    en: 'Mood',
    it: 'Umore',
    es: 'Animo',
    fr: 'Humeur',
    de: 'Stimmung',
    ja: 'Mood',
  );

  String get xpEarnedLabel => _localizedValue(
    en: 'XP Earned',
    it: 'XP Ottenuti',
    es: 'XP Ganada',
    fr: 'XP Gagnes',
    de: 'XP Verdient',
    ja: 'XP Earned',
  );

  String get saveToCatDexAction => _localizedValue(
    en: 'Save to CatDex',
    it: 'Salva nel CatDex',
    es: 'Guardar en CatDex',
    fr: 'Enregistrer dans CatDex',
    de: 'In CatDex Speichern',
    ja: 'Save to CatDex',
  );

  String get addToCatDexAction => _localizedValue(
    en: 'Add to CatDex',
    it: 'Aggiungi al CatDex',
    es: 'Anadir al CatDex',
    fr: 'Ajouter au CatDex',
    de: 'Zu CatDex Hinzufugen',
    ja: 'Add to CatDex',
  );

  String get revealDiscoveryAction => _localizedValue(
    en: 'Reveal Discovery',
    it: 'Rivela Scoperta',
    es: 'Revelar Descubrimiento',
    fr: 'Reveler la Decouverte',
    de: 'Entdeckung Anzeigen',
    ja: 'Reveal Discovery',
  );

  String get discoveryRevealTitle => _localizedValue(
    en: 'Discovery Reveal',
    it: 'Rivelazione Scoperta',
    es: 'Revelacion',
    fr: 'Revelation',
    de: 'Entdeckung',
    ja: 'Discovery Reveal',
  );

  String get discoveryUnlockedLabel => _localizedValue(
    en: 'New Cat Unlocked',
    it: 'Nuovo Gatto Sbloccato',
    es: 'Nuevo Gato Desbloqueado',
    fr: 'Nouveau Chat Debloque',
    de: 'Neue Katze Freigeschaltet',
    ja: 'New Cat Unlocked',
  );

  String get coinsEarnedLabel => _localizedValue(
    en: 'Coins Earned',
    it: 'Monete Ottenute',
    es: 'Monedas Ganadas',
    fr: 'Pieces Gagnees',
    de: 'Munzen Verdient',
    ja: 'Coins Earned',
  );

  String get savedToCatDexLabel => _localizedValue(
    en: 'Saved to CatDex',
    it: 'Salvato nel CatDex',
    es: 'Guardado en CatDex',
    fr: 'Enregistre dans CatDex',
    de: 'In CatDex Gespeichert',
    ja: 'Saved to CatDex',
  );

  String get saveToCatDexFailedLabel => _localizedValue(
    en: 'Save failed. Your discovery is waiting to sync.',
    it: 'Salvataggio non riuscito. La scoperta attende la sincronizzazione.',
    es: 'No se pudo guardar. Tu descubrimiento espera sincronizarse.',
    fr: 'Echec de sauvegarde. La decouverte attend la synchronisation.',
    de: 'Speichern fehlgeschlagen. Deine Entdeckung wartet auf Sync.',
    ja: 'Save failed. Your discovery is waiting to sync.',
  );

  String get retrySaveAction => _localizedValue(
    en: 'Retry Save',
    it: 'Riprova Salvataggio',
    es: 'Reintentar Guardado',
    fr: 'Reessayer',
    de: 'Speichern Wiederholen',
    ja: 'Retry Save',
  );

  String get photoPreviewLabel => _localizedValue(
    en: 'Photo preview',
    it: 'Anteprima foto',
    es: 'Vista previa',
    fr: 'Apercu photo',
    de: 'Fotovorschau',
    ja: 'Photo preview',
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

  String get collectionProgressTitle => _localizedValue(
    en: 'Collection Progress',
    it: 'Progresso Collezione',
    es: 'Progreso de Coleccion',
    fr: 'Progression Collection',
    de: 'Sammlungsfortschritt',
    ja: 'Collection Progress',
  );

  String get totalEntriesLabel => _localizedValue(
    en: 'Total Entries',
    it: 'Entry Totali',
    es: 'Entradas Totales',
    fr: 'Entrees Totales',
    de: 'Eintrage Gesamt',
    ja: 'Total Entries',
  );

  String get discoveredLabel => _localizedValue(
    en: 'Discovered',
    it: 'Scoperti',
    es: 'Descubiertos',
    fr: 'Decouverts',
    de: 'Entdeckt',
    ja: 'Discovered',
  );

  String get completionLabel => _localizedValue(
    en: 'Completion',
    it: 'Completamento',
    es: 'Completado',
    fr: 'Completion',
    de: 'Abschluss',
    ja: 'Completion',
  );

  String get searchCatDexLabel => _localizedValue(
    en: 'Search CatDex',
    it: 'Cerca nel CatDex',
    es: 'Buscar CatDex',
    fr: 'Chercher CatDex',
    de: 'CatDex Suchen',
    ja: 'Search CatDex',
  );

  String get allFilterLabel => _localizedValue(
    en: 'All',
    it: 'Tutti',
    es: 'Todo',
    fr: 'Tous',
    de: 'Alle',
    ja: 'All',
  );

  String get undiscoveredLabel => _localizedValue(
    en: 'Undiscovered',
    it: 'Non scoperti',
    es: 'No descubiertos',
    fr: 'Non decouverts',
    de: 'Unentdeckt',
    ja: 'Undiscovered',
  );

  String get rarityFiltersTitle => _localizedValue(
    en: 'Rarity',
    it: 'Rarita',
    es: 'Rareza',
    fr: 'Rarete',
    de: 'Seltenheit',
    ja: 'Rarity',
  );

  String get variantFiltersTitle => _localizedValue(
    en: 'Variant',
    it: 'Variante',
    es: 'Variante',
    fr: 'Variante',
    de: 'Variante',
    ja: 'Variant',
  );

  String get originLabel => _localizedValue(
    en: 'Origin',
    it: 'Origine',
    es: 'Origen',
    fr: 'Origine',
    de: 'Herkunft',
    ja: 'Origin',
  );

  String get notDiscoveredYetLabel => _localizedValue(
    en: 'Not discovered yet',
    it: 'Non ancora scoperto',
    es: 'Aun no descubierto',
    fr: 'Pas encore decouvert',
    de: 'Noch nicht entdeckt',
    ja: 'Not discovered yet',
  );

  String get traitsLabel => _localizedValue(
    en: 'Traits',
    it: 'Tratti',
    es: 'Rasgos',
    fr: 'Traits',
    de: 'Merkmale',
    ja: 'Traits',
  );

  String get placeholderTraitsLabel => _localizedValue(
    en: 'Curious, Friendly, Fluffy',
    it: 'Curioso, Amichevole, Soffice',
    es: 'Curioso, Amigable, Suave',
    fr: 'Curieux, Amical, Doux',
    de: 'Neugierig, Freundlich, Flauschig',
    ja: 'Curious, Friendly, Fluffy',
  );

  String catDexDetailDescription({
    required String speciesName,
    required String origin,
  }) {
    return _localizedValue(
      en: '$speciesName is a collectible CatDex entry from $origin.',
      it: '$speciesName e una scheda collezionabile CatDex da $origin.',
      es: '$speciesName es una entrada coleccionable CatDex de $origin.',
      fr: '$speciesName est une entree CatDex de collection de $origin.',
      de: '$speciesName ist ein CatDex-Sammeleintrag aus $origin.',
      ja: '$speciesName is a collectible CatDex entry from $origin.',
    );
  }

  String rarityName(String rarityCode) {
    return switch (rarityCode) {
      'common' => _localizedValue(
        en: 'Common',
        it: 'Comune',
        es: 'Comun',
        fr: 'Commun',
        de: 'Gewohnlich',
        ja: 'Common',
      ),
      'uncommon' => _localizedValue(
        en: 'Uncommon',
        it: 'Non comune',
        es: 'Poco comun',
        fr: 'Peu commun',
        de: 'Ungewohnlich',
        ja: 'Uncommon',
      ),
      'rare' => _localizedValue(
        en: 'Rare',
        it: 'Raro',
        es: 'Raro',
        fr: 'Rare',
        de: 'Selten',
        ja: 'Rare',
      ),
      'epic' => _localizedValue(
        en: 'Epic',
        it: 'Epico',
        es: 'Epico',
        fr: 'Epique',
        de: 'Episch',
        ja: 'Epic',
      ),
      'legendary' => _localizedValue(
        en: 'Legendary',
        it: 'Leggendario',
        es: 'Legendario',
        fr: 'Legendaire',
        de: 'Legendar',
        ja: 'Legendary',
      ),
      'mythic' => _localizedValue(
        en: 'Mythic',
        it: 'Mitico',
        es: 'Mitico',
        fr: 'Mythique',
        de: 'Mythisch',
        ja: 'Mythic',
      ),
      _ => rarityCode,
    };
  }

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

  String get offlineMessage => _localizedValue(
    en:
        'CatDex can keep local progress available, but cloud sync and online '
        'checks may wait until your connection returns.',
    it:
        'CatDex puo mantenere disponibili i progressi locali, ma sync cloud e '
        'controlli online possono attendere il ritorno della connessione.',
    es:
        'CatDex puede mantener disponible el progreso local, pero la nube y '
        'las comprobaciones online pueden esperar a que vuelva la conexion.',
    fr:
        'CatDex peut garder la progression locale disponible, mais la synchro '
        'cloud et les controles en ligne attendront la connexion.',
    de:
        'CatDex kann lokalen Fortschritt weiter anzeigen. Cloud-Sync und '
        'Online-Prufungen warten auf die Verbindung.',
    ja:
        'CatDex can keep local progress available, but cloud sync and online '
        'checks may wait until your connection returns.',
  );

  String get globalErrorTitle => _localizedValue(
    en: 'Something went wrong',
    it: 'Qualcosa non ha funzionato',
    es: 'Algo salio mal',
    fr: 'Un probleme est survenu',
    de: 'Etwas ist schiefgelaufen',
    ja: 'Something went wrong',
  );

  String get globalErrorMessage => _localizedValue(
    en:
        'This screen could not load safely. Your local CatDex progress should '
        'remain available.',
    it:
        'Questa schermata non si e caricata in modo sicuro. I progressi '
        'locali del CatDex dovrebbero restare disponibili.',
    es:
        'Esta pantalla no pudo cargarse con seguridad. Tu progreso local de '
        'CatDex deberia seguir disponible.',
    fr:
        'Cet ecran n a pas pu se charger correctement. Ta progression locale '
        'CatDex devrait rester disponible.',
    de:
        'Dieser Bildschirm konnte nicht sicher geladen werden. Dein lokaler '
        'CatDex-Fortschritt sollte verfugbar bleiben.',
    ja:
        'This screen could not load safely. Your local CatDex progress should '
        'remain available.',
  );

  String get unknownRouteTitle => _localizedValue(
    en: 'Page not found',
    it: 'Pagina non trovata',
    es: 'Pagina no encontrada',
    fr: 'Page introuvable',
    de: 'Seite nicht gefunden',
    ja: 'Page not found',
  );

  String get unknownRouteMessage => _localizedValue(
    en: 'That CatDex path does not exist yet.',
    it: 'Questo percorso CatDex non esiste ancora.',
    es: 'Esta ruta de CatDex aun no existe.',
    fr: 'Ce chemin CatDex n existe pas encore.',
    de: 'Diesen CatDex-Pfad gibt es noch nicht.',
    ja: 'That CatDex path does not exist yet.',
  );

  String get backHomeAction => _localizedValue(
    en: 'Back Home',
    it: 'Torna Home',
    es: 'Volver al Inicio',
    fr: 'Retour Accueil',
    de: 'Zuruck Home',
    ja: 'Back Home',
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
