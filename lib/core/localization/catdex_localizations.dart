import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CatDexLocalizations {
  const CatDexLocalizations(this.locale);

  final Locale locale;

  static const appName = 'CatDex';

  static const supportedLocales = <Locale>[
    Locale('it'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
    Locale('zh', 'CN'),
    Locale('ko'),
    Locale('hi', 'IN'),
    Locale('pt', 'BR'),
    Locale('pt', 'PT'),
  ];

  static const languageOptions = <AppLanguageOption>[
    AppLanguageOption(locale: Locale('it'), nativeName: 'Italiano'),
    AppLanguageOption(
      locale: Locale('en', 'US'),
      nativeName: 'English (US)',
    ),
    AppLanguageOption(locale: Locale('es'), nativeName: 'Español'),
    AppLanguageOption(locale: Locale('fr'), nativeName: 'Français'),
    AppLanguageOption(locale: Locale('de'), nativeName: 'Deutsch'),
    AppLanguageOption(locale: Locale('ja'), nativeName: '日本語'),
    AppLanguageOption(locale: Locale('zh', 'CN'), nativeName: '中文简体'),
    AppLanguageOption(locale: Locale('ko'), nativeName: '한국어'),
    AppLanguageOption(locale: Locale('hi', 'IN'), nativeName: 'हिन्दी'),
    AppLanguageOption(
      locale: Locale('pt', 'BR'),
      nativeName: 'Português (Brasil)',
    ),
    AppLanguageOption(
      locale: Locale('pt', 'PT'),
      nativeName: 'Português (Portugal)',
    ),
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

  static Locale bestSupportedLocale(Locale deviceLocale) {
    for (final locale in supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode &&
          (locale.countryCode == null ||
              locale.countryCode == deviceLocale.countryCode)) {
        return locale;
      }
    }
    return const Locale('en', 'US');
  }

  String get cardsTitle => _coreValue('cardsTitle');
  String get albumTitle => _coreValue('albumTitle');
  String get bottomCatdex => catDexTitle;
  String get bottomCapture => captureTitle;
  String get bottomCards => cardsTitle;
  String get bottomProfile => profileTitle;
  String get bottomHome => homeTitle;
  String get bottomMap => mapTitle;
  String get captureChooseCatPhoto => captureHeading;
  String get captureChooseCatPhotoSubtitle => captureEmptyMessage;
  String get captureTakePhoto => takePhotoAction;
  String get captureImportFromGallery => importFromGalleryAction;
  String get settingsLanguage => _coreValue('settingsLanguage');
  String get editDetails => _coreValue('editDetails');
  String get detailsLabel => _coreValue('details');
  String get editDetailsSubtitle => _coreValue('editDetailsSubtitle');
  String get saveChangesAction => _coreValue('saveChanges');
  String get cancelAction => _coreValue('cancel');
  String get nameDiscoveryTitle => _coreValue('nameDiscoveryTitle');
  String get nameDiscoverySubtitle => _coreValue('nameDiscoverySubtitle');
  String get speciesLabel => _coreValue('species');
  String get personalityLabel => _coreValue('personality');
  String get rarityLabel => _coreValue('rarity');
  String get furLabel => _coreValue('fur');
  String get eyesLabel => _coreValue('eyes');
  String get notDetectedLabel => _coreValue('notDetected');
  String get unknownLabel => _coreValue('unknown');

  String get mapTitle => _mapValue(en: 'Map', it: 'Mappa');

  String get mapEmptyTitle => _mapValue(
    en: 'No cats on the map yet',
    it: 'Ancora nessun gatto sulla mappa',
  );

  String get mapEmptyMessage => _mapValue(
    en: 'Enable location when saving a discovery to find it here.',
    it: 'Attiva la posizione quando salvi una scoperta per ritrovarla qui.',
  );

  String get mapOpenInCatDex => _mapValue(
    en: 'Open in CatDex',
    it: 'Apri nel CatDex',
  );

  String get mapApproximateLocation => _mapValue(
    en: 'Approximate location',
    it: 'Posizione approssimativa',
  );

  String get mapPreciseLocation => _mapValue(
    en: 'Precise location',
    it: 'Posizione precisa',
  );

  String get mapLocationUnavailable => _mapValue(
    en: 'Location unavailable',
    it: 'Posizione non disponibile',
  );

  String get mapCenterCurrentLocation => _mapValue(
    en: 'Center on my location',
    it: 'Centra sulla mia posizione',
  );

  String get mapLocationPermissionRequired => _mapValue(
    en: 'Location permission required',
    it: 'Permesso posizione necessario',
  );

  String get mapLocationPermissionExplanation => _mapValue(
    en:
        'CatDex uses your location only to center this private map. '
        'It is not shared with other users.',
    it:
        'CatDex usa la tua posizione solo per centrare questa mappa privata. '
        'Non viene condivisa con altri utenti.',
  );

  String get mapLocationPermissionPermanentlyDenied => _mapValue(
    en: 'Enable location for CatDex in your device settings.',
    it: 'Abilita la posizione per CatDex nelle impostazioni del dispositivo.',
  );

  String get mapAllowLocationAction => _mapValue(
    en: 'Allow location',
    it: 'Consenti posizione',
  );

  String get mapMissingLocationMessage => _mapValue(
    en: 'Some discoveries do not have a location',
    it: 'Alcune scoperte non hanno una posizione',
  );

  String get mapLoadError => _mapValue(
    en: 'Unable to load the map',
    it: 'Impossibile caricare la mappa',
  );

  String get mapOpenCapture => _mapValue(
    en: 'Open Capture',
    it: 'Apri Cattura',
  );

  String get mapLocationPreferences => _mapValue(
    en: 'Location preferences',
    it: 'Preferenze posizione',
  );

  String get mapLocationPreferencesMessage => _mapValue(
    en:
        'Choose whether new discoveries save an approximate or precise '
        'location.',
    it:
        'Scegli se le nuove scoperte salvano una posizione approssimativa '
        'o precisa.',
  );

  String get mapSaveDiscoveryLocation => _mapValue(
    en: 'Save location for new discoveries',
    it: 'Salva la posizione delle nuove scoperte',
  );

  String get mapRemoveLocation => _mapValue(
    en: 'Remove from map',
    it: 'Rimuovi dalla mappa',
  );

  String get mapRemoveLocationConfirmation => _mapValue(
    en: 'Remove the saved location from this discovery?',
    it: 'Rimuovere la posizione salvata da questa scoperta?',
  );

  String get mapRemoveAction => _mapValue(en: 'Remove', it: 'Rimuovi');

  String mapLocatedDiscoveryCount(int count) => _mapValue(
    en: '$count cats on the map',
    it: '$count gatti sulla mappa',
  );

  String mapMissingLocationCount(int count) => _mapValue(
    en: '$count discoveries do not have a location',
    it: '$count scoperte non hanno una posizione',
  );

  String get refreshAction => _localizedValue(
    en: 'Refresh',
    it: 'Aggiorna',
    es: 'Refresh',
    fr: 'Refresh',
    de: 'Refresh',
    ja: 'Refresh',
    zh: 'Refresh',
    ko: 'Refresh',
    hi: 'Refresh',
    ptBr: 'Refresh',
    ptPt: 'Refresh',
  );

  String get alphaInfoTitle => _localizedValue(
    en: 'Alpha tester info',
    it: 'Info alpha tester',
    es: 'Alpha tester info',
    fr: 'Alpha tester info',
    de: 'Alpha tester info',
    ja: 'Alpha tester info',
  );

  String get alphaBuildLabel => _localizedValue(
    en: 'Build',
    it: 'Versione',
    es: 'Build',
    fr: 'Build',
    de: 'Build',
    ja: 'Build',
  );

  String get alphaCurrentLanguageLabel => _localizedValue(
    en: 'Current language',
    it: 'Lingua attuale',
    es: 'Current language',
    fr: 'Current language',
    de: 'Current language',
    ja: 'Current language',
  );

  String get alphaPremiumDebugLabel => _localizedValue(
    en: 'Premium debug',
    it: 'Debug Premium',
    es: 'Premium debug',
    fr: 'Premium debug',
    de: 'Premium debug',
    ja: 'Premium debug',
  );

  String get alphaTesterMessage => _localizedValue(
    en:
        'This is an alpha version. If you find bugs, take a screenshot '
        'and report what you were doing.',
    it:
        'Questa è una versione alpha. Se trovi bug, fai uno screenshot '
        'e segnala cosa stavi facendo.',
    es:
        'This is an alpha version. If you find bugs, take a screenshot '
        'and report what you were doing.',
    fr:
        'This is an alpha version. If you find bugs, take a screenshot '
        'and report what you were doing.',
    de:
        'This is an alpha version. If you find bugs, take a screenshot '
        'and report what you were doing.',
    ja:
        'This is an alpha version. If you find bugs, take a screenshot '
        'and report what you were doing.',
  );

  String get noCatsFound => _localizedValue(
    en: 'No cats found.',
    it: 'Nessun gatto trovato.',
    es: 'No cats found.',
    fr: 'No cats found.',
    de: 'No cats found.',
    ja: 'No cats found.',
  );

  String get noCatsFoundHint => _localizedValue(
    en: 'Try another search or keep exploring to discover new cats.',
    it:
        'Prova un’altra ricerca o continua a esplorare per scoprire '
        'nuovi gatti.',
    es: 'Try another search or keep exploring to discover new cats.',
    fr: 'Try another search or keep exploring to discover new cats.',
    de: 'Try another search or keep exploring to discover new cats.',
    ja: 'Try another search or keep exploring to discover new cats.',
  );

  String get noGeneratedCards => _localizedValue(
    en: 'No generated cards yet.',
    it: 'Nessuna carta generata.',
    es: 'No generated cards yet.',
    fr: 'No generated cards yet.',
    de: 'No generated cards yet.',
    ja: 'No generated cards yet.',
  );

  String get cardsSubtitle => _localizedValue(
    en: 'Your deck of discovered cats',
    it: 'Il tuo mazzo di gatti scoperti',
    es: 'Tu mazo de gatos descubiertos',
    fr: 'Ton jeu de chats découverts',
    de: 'Dein Deck entdeckter Katzen',
    ja: '発見した猫のカードデッキ',
    zh: '你发现的猫咪卡组',
    ko: '발견한 고양이 카드 덱',
    hi: 'खोजी गई बिल्लियों का आपका डेक',
    ptBr: 'Seu baralho de gatos descobertos',
    ptPt: 'O teu baralho de gatos descobertos',
  );

  String get cardsFound => _localizedValue(
    en: 'Cards found',
    it: 'Carte trovate',
    es: 'Cartas encontradas',
    fr: 'Cartes trouvées',
    de: 'Gefundene Karten',
    ja: '見つけたカード',
    zh: '已找到卡牌',
    ko: '발견한 카드',
    hi: 'मिले कार्ड',
    ptBr: 'Cartas encontradas',
    ptPt: 'Cartas encontradas',
  );

  String get openAlbum => _localizedValue(
    en: 'Open album',
    it: 'Apri album',
    es: 'Abrir álbum',
    fr: 'Ouvrir l’album',
    de: 'Album öffnen',
    ja: 'アルバムを開く',
    zh: '打开图鉴',
    ko: '앨범 열기',
    hi: 'एल्बम खोलें',
    ptBr: 'Abrir álbum',
    ptPt: 'Abrir álbum',
  );

  String get regenerateCards => _localizedValue(
    en: 'Regenerate cards',
    it: 'Rigenera carte',
    es: 'Regenerar cartas',
    fr: 'Régénérer les cartes',
    de: 'Karten neu erstellen',
    ja: 'カードを再生成',
    zh: '重新生成卡牌',
    ko: '카드 다시 생성',
    hi: 'कार्ड फिर बनाएं',
    ptBr: 'Gerar cartas novamente',
    ptPt: 'Gerar cartas novamente',
  );

  String generatedCardsProgress(int generated, int total) => _localizedValue(
    en: '$generated generated out of $total cards',
    it: '$generated generate su $total carte',
    es: '$generated generadas de $total cartas',
    fr: '$generated générées sur $total cartes',
    de: '$generated von $total Karten erstellt',
    ja: '$total枚中$generated枚生成済み',
    zh: '已生成 $generated / $total 张卡牌',
    ko: '$total장 중 $generated장 생성됨',
    hi: '$total में से $generated कार्ड बने',
    ptBr: '$generated geradas de $total cartas',
    ptPt: '$generated geradas de $total cartas',
  );

  String get emptyRarityAlbum => _localizedValue(
    en: 'You do not have cards of this rarity yet',
    it: 'Non hai ancora carte di questa rarità',
    es: 'Aún no tienes cartas de esta rareza',
    fr: 'Tu n’as pas encore de cartes de cette rareté',
    de: 'Du hast noch keine Karten dieser Seltenheit',
    ja: 'このレア度のカードはまだありません',
    zh: '你还没有这个稀有度的卡牌',
    ko: '아직 이 희귀도의 카드가 없습니다',
    hi: 'इस दुर्लभता का कोई कार्ड अभी नहीं है',
    ptBr: 'Você ainda não tem cartas desta raridade',
    ptPt: 'Ainda não tens cartas desta raridade',
  );

  String get emptyRarityAlbumHint => _localizedValue(
    en: 'Take or upload new cat photos to find one',
    it: 'Scatta o carica nuove foto di gatti per trovarne una',
    es: 'Toma o sube nuevas fotos de gatos para encontrar una',
    fr: 'Prends ou importe des photos de chats pour en trouver une',
    de: 'Fotografiere oder lade Katzenfotos hoch, um eine zu finden',
    ja: '猫の写真を撮影または追加して見つけましょう',
    zh: '拍摄或上传新的猫咪照片来发现卡牌',
    ko: '새 고양이 사진을 촬영하거나 업로드해 보세요',
    hi: 'नई बिल्ली की तस्वीर लेकर या अपलोड करके खोजें',
    ptBr: 'Tire ou envie novas fotos de gatos para encontrar uma',
    ptPt: 'Tira ou envia novas fotografias de gatos para encontrar uma',
  );

  String get levelLabel => _localizedValue(
    en: 'Level',
    it: 'Livello',
    es: 'Nivel',
    fr: 'Niveau',
    de: 'Level',
    ja: 'レベル',
    zh: '等级',
    ko: '레벨',
    hi: 'स्तर',
    ptBr: 'Nível',
    ptPt: 'Nível',
  );

  String get totalXpLabel => _localizedValue(
    en: 'total XP',
    it: 'XP totali',
    es: 'XP totales',
    fr: 'XP totaux',
    de: 'XP gesamt',
    ja: '合計XP',
    zh: '总 XP',
    ko: '총 XP',
    hi: 'कुल XP',
    ptBr: 'XP total',
    ptPt: 'XP total',
  );

  String get foundLabel => _localizedValue(
    en: 'Found',
    it: 'Trovati',
    es: 'Encontrados',
    fr: 'Trouvés',
    de: 'Gefunden',
    ja: '発見',
    zh: '已发现',
    ko: '발견',
    hi: 'मिले',
    ptBr: 'Encontrados',
    ptPt: 'Encontrados',
  );

  String get completedLabelShort => _localizedValue(
    en: 'Completed',
    it: 'Completato',
    es: 'Completado',
    fr: 'Terminé',
    de: 'Abgeschlossen',
    ja: '完成',
    zh: '完成度',
    ko: '완료',
    hi: 'पूरा',
    ptBr: 'Concluído',
    ptPt: 'Concluído',
  );

  String get searchByName => _localizedValue(
    en: 'Search by name',
    it: 'Cerca per nome',
    es: 'Buscar por nombre',
    fr: 'Rechercher par nom',
    de: 'Nach Namen suchen',
    ja: '名前で検索',
    zh: '按名字搜索',
    ko: '이름으로 검색',
    hi: 'नाम से खोजें',
    ptBr: 'Buscar por nome',
    ptPt: 'Pesquisar por nome',
  );

  String get allLabel => _localizedValue(
    en: 'All',
    it: 'Tutti',
    es: 'Todos',
    fr: 'Tous',
    de: 'Alle',
    ja: 'すべて',
    zh: '全部',
    ko: '전체',
    hi: 'सभी',
    ptBr: 'Todos',
    ptPt: 'Todos',
  );

  String get favoritesLabel => _localizedValue(
    en: 'Favorites',
    it: 'Preferiti',
    es: 'Favoritos',
    fr: 'Favoris',
    de: 'Favoriten',
    ja: 'お気に入り',
    zh: '收藏',
    ko: '즐겨찾기',
    hi: 'पसंदीदा',
    ptBr: 'Favoritos',
    ptPt: 'Favoritos',
  );

  String get discoveredOnLabel => _localizedValue(
    en: 'Discovered on',
    it: 'Scoperto il',
    es: 'Descubierto el',
    fr: 'Découvert le',
    de: 'Entdeckt am',
    ja: '発見日',
    zh: '发现日期',
    ko: '발견일',
    hi: 'खोज की तारीख',
    ptBr: 'Descoberto em',
    ptPt: 'Descoberto em',
  );

  String get curiosityLabel => _localizedValue(
    en: 'Fun fact',
    it: 'Curiosità',
    es: 'Curiosidad',
    fr: 'Le saviez-vous',
    de: 'Wissenswertes',
    ja: '豆知識',
    zh: '趣味知识',
    ko: '재미있는 사실',
    hi: 'रोचक तथ्य',
    ptBr: 'Curiosidade',
    ptPt: 'Curiosidade',
  );

  String analysesRemainingToday(int remaining, int maximum, int credits) {
    final base = _localizedValue(
      en: 'Analyses left today: $remaining/$maximum',
      it: 'Analisi rimaste oggi: $remaining/$maximum',
      es: 'Análisis restantes hoy: $remaining/$maximum',
      fr: 'Analyses restantes aujourd’hui : $remaining/$maximum',
      de: 'Verbleibende Analysen heute: $remaining/$maximum',
      ja: '本日の残り分析回数：$remaining/$maximum',
      zh: '今日剩余分析次数：$remaining/$maximum',
      ko: '오늘 남은 분석: $remaining/$maximum',
      hi: 'आज शेष विश्लेषण: $remaining/$maximum',
      ptBr: 'Análises restantes hoje: $remaining/$maximum',
      ptPt: 'Análises restantes hoje: $remaining/$maximum',
    );
    return credits > 0 ? '$base · ${extraCreditsLabel(credits)}' : base;
  }

  String cardGenerationsRemainingToday(
    int remaining,
    int maximum,
    int credits,
  ) {
    final base = _localizedValue(
      en: 'Card generations left today: $remaining/$maximum',
      it: 'Generazioni carte rimaste oggi: $remaining/$maximum',
      es: 'Generaciones de cartas restantes hoy: $remaining/$maximum',
      fr: 'Générations de cartes restantes : $remaining/$maximum',
      de: 'Verbleibende Kartenerstellungen: $remaining/$maximum',
      ja: '本日の残りカード生成回数：$remaining/$maximum',
      zh: '今日剩余卡牌生成次数：$remaining/$maximum',
      ko: '오늘 남은 카드 생성: $remaining/$maximum',
      hi: 'आज शेष कार्ड निर्माण: $remaining/$maximum',
      ptBr: 'Gerações de cartas restantes hoje: $remaining/$maximum',
      ptPt: 'Gerações de cartas restantes hoje: $remaining/$maximum',
    );
    return credits > 0 ? '$base · ${extraCreditsLabel(credits)}' : base;
  }

  String extraCreditsLabel(int credits) => _localizedValue(
    en: 'Extra credits: $credits',
    it: 'Crediti extra: $credits',
    es: 'Créditos extra: $credits',
    fr: 'Crédits supplémentaires : $credits',
    de: 'Extra-Credits: $credits',
    ja: '追加クレジット：$credits',
    zh: '额外次数：$credits',
    ko: '추가 크레딧: $credits',
    hi: 'अतिरिक्त क्रेडिट: $credits',
    ptBr: 'Créditos extras: $credits',
    ptPt: 'Créditos extra: $credits',
  );

  String get premiumAnalysesUnlimited => _localizedValue(
    en: 'Premium active · Unlimited analyses',
    it: 'Premium attivo · Analisi illimitate',
    es: 'Premium activo · Análisis ilimitados',
    fr: 'Premium actif · Analyses illimitées',
    de: 'Premium aktiv · Unbegrenzte Analysen',
    ja: 'Premium有効 · 分析無制限',
    zh: 'Premium 已启用 · 无限分析',
    ko: 'Premium 활성 · 분석 무제한',
    hi: 'Premium सक्रिय · असीमित विश्लेषण',
    ptBr: 'Premium ativo · Análises ilimitadas',
    ptPt: 'Premium ativo · Análises ilimitadas',
  );

  String get premiumCardsUnlimited => _localizedValue(
    en: 'Premium active · Unlimited cards',
    it: 'Premium attivo · Carte illimitate',
    es: 'Premium activo · Cartas ilimitadas',
    fr: 'Premium actif · Cartes illimitées',
    de: 'Premium aktiv · Unbegrenzte Karten',
    ja: 'Premium有効 · カード無制限',
    zh: 'Premium 已启用 · 无限卡牌',
    ko: 'Premium 활성 · 카드 무제한',
    hi: 'Premium सक्रिय · असीमित कार्ड',
    ptBr: 'Premium ativo · Cartas ilimitadas',
    ptPt: 'Premium ativo · Cartas ilimitadas',
  );

  String get cardsUpdatedMessage => _localizedValue(
    en: 'Cards updated',
    it: 'Carte aggiornate',
    es: 'Cartas actualizadas',
    fr: 'Cartes mises à jour',
    de: 'Karten aktualisiert',
    ja: 'カードを更新しました',
    zh: '卡牌已更新',
    ko: '카드가 업데이트되었습니다',
    hi: 'कार्ड अपडेट हुए',
    ptBr: 'Cartas atualizadas',
    ptPt: 'Cartas atualizadas',
  );

  String get cardUpdatedMessage => _localizedValue(
    en: 'Card updated',
    it: 'Carta aggiornata',
    es: 'Carta actualizada',
    fr: 'Carte mise à jour',
    de: 'Karte aktualisiert',
    ja: 'カードを更新しました',
    zh: '卡牌已更新',
    ko: '카드가 업데이트되었습니다',
    hi: 'कार्ड अपडेट हुआ',
    ptBr: 'Carta atualizada',
    ptPt: 'Carta atualizada',
  );

  String get cardGenerationError => _localizedValue(
    en: 'Card generation error',
    it: 'Errore generazione carta',
    es: 'Error al generar la carta',
    fr: 'Erreur de génération de la carte',
    de: 'Fehler bei der Kartenerstellung',
    ja: 'カード生成エラー',
    zh: '卡牌生成错误',
    ko: '카드 생성 오류',
    hi: 'कार्ड बनाने में त्रुटि',
    ptBr: 'Erro ao gerar carta',
    ptPt: 'Erro ao gerar carta',
  );

  String get generatingIllustration => _localizedValue(
    en: 'Creating illustration...',
    it: 'Creo illustrazione...',
    es: 'Creando ilustración...',
    fr: 'Création de l’illustration...',
    de: 'Illustration wird erstellt...',
    ja: 'イラストを作成中...',
    zh: '正在生成插画...',
    ko: '일러스트 생성 중...',
    hi: 'चित्रण बनाया जा रहा है...',
    ptBr: 'Criando ilustração...',
    ptPt: 'A criar ilustração...',
  );

  String get wakingCardGenerator => _localizedValue(
    en: 'Preparing the generator...',
    it: 'Preparazione del generatore...',
    es: 'Preparando el generador...',
    fr: 'Préparation du générateur...',
    de: 'Generator wird vorbereitet...',
    ja: '生成器を準備中...',
    zh: '正在准备生成器...',
    ko: '생성기 준비 중...',
    hi: 'जनरेटर तैयार हो रहा है...',
    ptBr: 'Preparando o gerador...',
    ptPt: 'A preparar o gerador...',
  );

  String get savingCard => _localizedValue(
    en: 'Saving the card...',
    it: 'Salvataggio della carta...',
    es: 'Guardando la carta...',
    fr: 'Enregistrement de la carte...',
    de: 'Karte wird gespeichert...',
    ja: 'カードを保存中...',
    zh: '正在保存卡牌...',
    ko: '카드 저장 중...',
    hi: 'कार्ड सहेजा जा रहा है...',
    ptBr: 'Salvando a carta...',
    ptPt: 'A guardar a carta...',
  );

  String get generateCard => _localizedValue(
    en: 'Generate card',
    it: 'Genera carta',
    es: 'Generar carta',
    fr: 'Générer la carte',
    de: 'Karte erstellen',
    ja: 'カードを生成',
    zh: '生成卡牌',
    ko: '카드 생성',
    hi: 'कार्ड बनाएं',
    ptBr: 'Gerar carta',
    ptPt: 'Gerar carta',
  );

  String get regenerateCard => _localizedValue(
    en: 'Regenerate',
    it: 'Rigenera',
    es: 'Regenerar',
    fr: 'Régénérer',
    de: 'Neu erstellen',
    ja: '再生成',
    zh: '重新生成',
    ko: '다시 생성',
    hi: 'फिर बनाएं',
    ptBr: 'Gerar novamente',
    ptPt: 'Gerar novamente',
  );

  String get cardNotGenerated => _localizedValue(
    en: 'Card not generated',
    it: 'Carta non generata',
    es: 'Carta no generada',
    fr: 'Carte non générée',
    de: 'Karte nicht erstellt',
    ja: 'カード未生成',
    zh: '卡牌尚未生成',
    ko: '카드가 생성되지 않음',
    hi: 'कार्ड नहीं बना',
    ptBr: 'Carta não gerada',
    ptPt: 'Carta não gerada',
  );

  String get cardNoLongerAvailable => _localizedValue(
    en: 'This card is no longer available.',
    it: 'Questa carta non è più disponibile.',
    es: 'Esta carta ya no está disponible.',
    fr: 'Cette carte n’est plus disponible.',
    de: 'Diese Karte ist nicht mehr verfügbar.',
    ja: 'このカードは利用できなくなりました。',
    zh: '此卡牌已不可用。',
    ko: '이 카드는 더 이상 사용할 수 없습니다.',
    hi: 'यह कार्ड अब उपलब्ध नहीं है।',
    ptBr: 'Esta carta não está mais disponível.',
    ptPt: 'Esta carta já não está disponível.',
  );

  String get createFinalCardHint => _localizedValue(
    en: 'Create the final card to add it to your binder.',
    it: 'Crea la carta finale per aggiungerla al tuo raccoglitore.',
    es: 'Crea la carta final para añadirla a tu álbum.',
    fr: 'Crée la carte finale pour l’ajouter à ton album.',
    de: 'Erstelle die finale Karte für dein Album.',
    ja: '最終カードを作成してアルバムに追加しましょう。',
    zh: '生成最终卡牌并添加到图鉴。',
    ko: '최종 카드를 만들어 앨범에 추가하세요.',
    hi: 'अंतिम कार्ड बनाकर अपने एल्बम में जोड़ें।',
    ptBr: 'Crie a carta final para adicioná-la ao álbum.',
    ptPt: 'Cria a carta final para a adicionar ao álbum.',
  );

  String get retryAction => _localizedValue(
    en: 'Retry',
    it: 'Riprova',
    es: 'Reintentar',
    fr: 'Réessayer',
    de: 'Erneut versuchen',
    ja: '再試行',
    zh: '重试',
    ko: '다시 시도',
    hi: 'फिर कोशिश करें',
    ptBr: 'Tentar novamente',
    ptPt: 'Tentar novamente',
  );

  String get cardLabel => _localizedValue(
    en: 'Card',
    it: 'Carta',
    es: 'Carta',
    fr: 'Carte',
    de: 'Karte',
    ja: 'カード',
    zh: '卡牌',
    ko: '카드',
    hi: 'कार्ड',
    ptBr: 'Carta',
    ptPt: 'Carta',
  );

  String get discoveryLabel => _localizedValue(
    en: 'Discovery',
    it: 'Scoperta',
    es: 'Descubrimiento',
    fr: 'Découverte',
    de: 'Entdeckung',
    ja: '発見',
    zh: '发现',
    ko: '발견',
    hi: 'खोज',
    ptBr: 'Descoberta',
    ptPt: 'Descoberta',
  );

  String get shareAction => _localizedValue(
    en: 'Share',
    it: 'Condividi',
    es: 'Compartir',
    fr: 'Partager',
    de: 'Teilen',
    ja: '共有',
    zh: '分享',
    ko: '공유',
    hi: 'साझा करें',
    ptBr: 'Compartilhar',
    ptPt: 'Partilhar',
  );

  String get saveImageAction => _localizedValue(
    en: 'Save image',
    it: 'Salva immagine',
    es: 'Guardar imagen',
    fr: 'Enregistrer l’image',
    de: 'Bild speichern',
    ja: '画像を保存',
    zh: '保存图片',
    ko: '이미지 저장',
    hi: 'चित्र सहेजें',
    ptBr: 'Salvar imagem',
    ptPt: 'Guardar imagem',
  );

  String get coinsLabel => _localizedValue(
    en: 'Coins',
    it: 'Monete',
    es: 'Monedas',
    fr: 'Pièces',
    de: 'Münzen',
    ja: 'コイン',
    zh: '金币',
    ko: '코인',
    hi: 'सिक्के',
    ptBr: 'Moedas',
    ptPt: 'Moedas',
  );

  String get revealDiscoveryAction => _localizedValue(
    en: 'Reveal discovery',
    it: 'Rivela scoperta',
    es: 'Revelar descubrimiento',
    fr: 'Révéler la découverte',
    de: 'Entdeckung enthüllen',
    ja: '発見を公開',
    zh: '揭晓发现',
    ko: '발견 공개',
    hi: 'खोज दिखाएं',
    ptBr: 'Revelar descoberta',
    ptPt: 'Revelar descoberta',
  );

  String get backAction => _localizedValue(
    en: 'Back',
    it: 'Indietro',
    es: 'Atrás',
    fr: 'Retour',
    de: 'Zurück',
    ja: '戻る',
    zh: '返回',
    ko: '뒤로',
    hi: 'वापस',
    ptBr: 'Voltar',
    ptPt: 'Voltar',
  );

  String localizeDisplayValue(String value) {
    final key = value.trim().toLowerCase().replaceAll('_', ' ');
    const aliases = <String, String>{
      'common': 'common',
      'comune': 'common',
      'uncommon': 'uncommon',
      'non comune': 'uncommon',
      'rare': 'rare',
      'rara': 'rare',
      'epic': 'epic',
      'epica': 'epic',
      'epico': 'epic',
      'legendary': 'legendary',
      'leggendaria': 'legendary',
      'leggendario': 'legendary',
      'curious': 'curious',
      'curioso': 'curious',
      'sweet': 'sweet',
      'dolce': 'sweet',
      'shy': 'shy',
      'timido': 'shy',
      'playful': 'playful',
      'giocherellone': 'playful',
      'elegant': 'elegant',
      'elegante': 'elegant',
      'mysterious': 'mysterious',
      'misterioso': 'mysterious',
      'energetic': 'energetic',
      'energico': 'energetic',
      'calm': 'calm',
      'calmo': 'calm',
      'relaxed': 'relaxed',
      'tranquillo': 'relaxed',
      'lazy': 'lazy',
      'pigro': 'lazy',
      'normal': 'normal',
      'normale': 'normal',
      'unknown': 'unknown',
      'sconosciuto': 'unknown',
      'non rilevato': 'notDetected',
      'domestic cat': 'catDomestic',
      'gatto domestico': 'catDomestic',
      'domestic tabby cat': 'catDomesticTabby',
      'gatto domestico tigrato': 'catDomesticTabby',
      'domestic bicolor cat': 'catDomesticBicolor',
      'gatto domestico bicolore': 'catDomesticBicolor',
      'european shorthair': 'catEuropeanShorthair',
      'gatto europeo': 'catEuropeanShorthair',
      'siamese': 'catSiamese',
      'persian': 'catPersian',
      'persiano': 'catPersian',
      'maine coon': 'catMaineCoon',
      'british shorthair': 'catBritishShorthair',
    };
    final translationKey = aliases[key];
    if (translationKey != null) {
      return _coreValue(translationKey);
    }
    final visualKey = _visualAliases[key];
    final translations = visualKey == null
        ? null
        : _visualTranslations[visualKey];
    return translations == null ? value : translations[_translationIndex];
  }

  int get _translationIndex {
    return switch (_localeKey) {
      'it' => 1,
      'es' => 2,
      'fr' => 3,
      'de' => 4,
      'ja' => 5,
      'zh_CN' => 6,
      'ko' => 7,
      'hi_IN' => 8,
      'pt_BR' => 9,
      'pt_PT' => 10,
      _ => 0,
    };
  }

  static const _visualAliases = <String, String>{
    'nero': 'black',
    'black': 'black',
    'bianco': 'white',
    'white': 'white',
    'grigio': 'gray',
    'gray': 'gray',
    'grey': 'gray',
    'marrone': 'brown',
    'brown': 'brown',
    'arancione': 'orange',
    'orange': 'orange',
    'nero/bianco': 'blackWhite',
    'black white': 'blackWhite',
    'grigio/bianco': 'grayWhite',
    'gray white': 'grayWhite',
    'grey white': 'grayWhite',
    'marrone/bianco': 'brownWhite',
    'brown white': 'brownWhite',
    'arancione/bianco': 'orangeWhite',
    'orange white': 'orangeWhite',
    'arancione tigrato': 'orangeTabby',
    'orange tabby': 'orangeTabby',
    'marrone tigrato': 'brownTabby',
    'brown tabby': 'brownTabby',
    'grigio tigrato': 'grayTabby',
    'gray tabby': 'grayTabby',
    'calico': 'calico',
    'tricolore': 'tricolor',
    'tartarugato': 'tortoiseshell',
    'bicolore': 'bicolor',
    'solido': 'solid',
    'solid': 'solid',
    'tigrato': 'tabby',
    'tabby': 'tabby',
    'pezzato': 'patched',
    'colorpoint': 'colorpoint',
    'gialli': 'yellowEyes',
    'yellow': 'yellowEyes',
    'occhi gialli': 'yellowEyes',
    'verdi': 'greenEyes',
    'green': 'greenEyes',
    'occhi verdi': 'greenEyes',
    'azzurri': 'blueEyes',
    'blue': 'blueEyes',
    'occhi azzurri': 'blueEyes',
    'ambrati': 'amberEyes',
    'amber': 'amberEyes',
    'occhi ambrati': 'amberEyes',
    'eterocromia': 'heterochromia',
    'occhi eterocromi': 'heterochromia',
    'corto': 'short',
    'short': 'short',
    'pelo corto': 'short',
    'medio': 'medium',
    'medium': 'medium',
    'pelo medio': 'medium',
    'lungo': 'long',
    'long': 'long',
    'pelo lungo': 'long',
    'adult': 'adult',
    'adulto': 'adult',
    'kitten': 'kitten',
    'cucciolo': 'kitten',
    'senior': 'senior',
    'anziano': 'senior',
  };

  // Order: en, it, es, fr, de, ja, zh-CN, ko, hi-IN, pt-BR, pt-PT.
  static const _visualTranslations = <String, List<String>>{
    'black': [
      'Black',
      'Nero',
      'Negro',
      'Noir',
      'Schwarz',
      '黒',
      '黑色',
      '검정',
      'काला',
      'Preto',
      'Preto',
    ],
    'white': [
      'White',
      'Bianco',
      'Blanco',
      'Blanc',
      'Weiß',
      '白',
      '白色',
      '흰색',
      'सफेद',
      'Branco',
      'Branco',
    ],
    'gray': [
      'Gray',
      'Grigio',
      'Gris',
      'Gris',
      'Grau',
      'グレー',
      '灰色',
      '회색',
      'स्लेटी',
      'Cinza',
      'Cinzento',
    ],
    'brown': [
      'Brown',
      'Marrone',
      'Marrón',
      'Brun',
      'Braun',
      '茶色',
      '棕色',
      '갈색',
      'भूरा',
      'Marrom',
      'Castanho',
    ],
    'orange': [
      'Orange',
      'Arancione',
      'Naranja',
      'Roux',
      'Orange',
      'オレンジ',
      '橙色',
      '주황색',
      'नारंगी',
      'Laranja',
      'Laranja',
    ],
    'blackWhite': [
      'Black/white',
      'Nero/bianco',
      'Negro/blanco',
      'Noir/blanc',
      'Schwarz/weiß',
      '黒白',
      '黑白',
      '검정/흰색',
      'काला/सफेद',
      'Preto/branco',
      'Preto/branco',
    ],
    'grayWhite': [
      'Gray/white',
      'Grigio/bianco',
      'Gris/blanco',
      'Gris/blanc',
      'Grau/weiß',
      'グレー/白',
      '灰白',
      '회색/흰색',
      'स्लेटी/सफेद',
      'Cinza/branco',
      'Cinzento/branco',
    ],
    'brownWhite': [
      'Brown/white',
      'Marrone/bianco',
      'Marrón/blanco',
      'Brun/blanc',
      'Braun/weiß',
      '茶色/白',
      '棕白',
      '갈색/흰색',
      'भूरा/सफेद',
      'Marrom/branco',
      'Castanho/branco',
    ],
    'orangeWhite': [
      'Orange/white',
      'Arancione/bianco',
      'Naranja/blanco',
      'Roux/blanc',
      'Orange/weiß',
      'オレンジ/白',
      '橙白',
      '주황/흰색',
      'नारंगी/सफेद',
      'Laranja/branco',
      'Laranja/branco',
    ],
    'orangeTabby': [
      'Orange tabby',
      'Arancione tigrato',
      'Naranja atigrado',
      'Roux tigré',
      'Orange getigert',
      '茶トラ',
      '橙色虎斑',
      '주황 태비',
      'नारंगी धारीदार',
      'Laranja tigrado',
      'Laranja tigrado',
    ],
    'brownTabby': [
      'Brown tabby',
      'Marrone tigrato',
      'Marrón atigrado',
      'Brun tigré',
      'Braun getigert',
      '茶色のトラ柄',
      '棕色虎斑',
      '갈색 태비',
      'भूरा धारीदार',
      'Marrom tigrado',
      'Castanho tigrado',
    ],
    'grayTabby': [
      'Gray tabby',
      'Grigio tigrato',
      'Gris atigrado',
      'Gris tigré',
      'Grau getigert',
      'グレーのトラ柄',
      '灰色虎斑',
      '회색 태비',
      'स्लेटी धारीदार',
      'Cinza tigrado',
      'Cinzento tigrado',
    ],
    'calico': [
      'Calico',
      'Calico',
      'Calicó',
      'Calico',
      'Calico',
      '三毛',
      '三花',
      '삼색',
      'कैलिको',
      'Calico',
      'Calico',
    ],
    'tricolor': [
      'Tricolor',
      'Tricolore',
      'Tricolor',
      'Tricolore',
      'Dreifarbig',
      '三色',
      '三色',
      '삼색',
      'तिरंगा',
      'Tricolor',
      'Tricolor',
    ],
    'tortoiseshell': [
      'Tortoiseshell',
      'Tartarugato',
      'Carey',
      'Écaille de tortue',
      'Schildpatt',
      'サビ柄',
      '玳瑁',
      '카오스',
      'कछुआ-खोल',
      'Escama de tartaruga',
      'Escama de tartaruga',
    ],
    'bicolor': [
      'Bicolor',
      'Bicolore',
      'Bicolor',
      'Bicolore',
      'Zweifarbig',
      '二色',
      '双色',
      '바이컬러',
      'दो रंग',
      'Bicolor',
      'Bicolor',
    ],
    'solid': [
      'Solid',
      'Solido',
      'Sólido',
      'Uni',
      'Einfarbig',
      '単色',
      '纯色',
      '단색',
      'ठोस रंग',
      'Sólido',
      'Sólido',
    ],
    'tabby': [
      'Tabby',
      'Tigrato',
      'Atigrado',
      'Tigré',
      'Getigert',
      'トラ柄',
      '虎斑',
      '태비',
      'धारीदार',
      'Tigrado',
      'Tigrado',
    ],
    'patched': [
      'Patched',
      'Pezzato',
      'Manchado',
      'Tacheté',
      'Gefleckt',
      '斑模様',
      '斑块',
      '얼룩',
      'चितकबरा',
      'Malhado',
      'Malhado',
    ],
    'colorpoint': [
      'Colorpoint',
      'Colorpoint',
      'Colorpoint',
      'Colourpoint',
      'Colourpoint',
      'ポイント柄',
      '重点色',
      '포인트',
      'कलरपॉइंट',
      'Colorpoint',
      'Colorpoint',
    ],
    'yellowEyes': [
      'Yellow',
      'Gialli',
      'Amarillos',
      'Jaunes',
      'Gelb',
      '黄色',
      '黄色',
      '노란색',
      'पीली',
      'Amarelos',
      'Amarelos',
    ],
    'greenEyes': [
      'Green',
      'Verdi',
      'Verdes',
      'Verts',
      'Grün',
      '緑',
      '绿色',
      '초록색',
      'हरी',
      'Verdes',
      'Verdes',
    ],
    'blueEyes': [
      'Blue',
      'Azzurri',
      'Azules',
      'Bleus',
      'Blau',
      '青',
      '蓝色',
      '파란색',
      'नीली',
      'Azuis',
      'Azuis',
    ],
    'amberEyes': [
      'Amber',
      'Ambrati',
      'Ámbar',
      'Ambrés',
      'Bernstein',
      '琥珀色',
      '琥珀色',
      '호박색',
      'अंबर',
      'Âmbar',
      'Âmbar',
    ],
    'heterochromia': [
      'Heterochromia',
      'Eterocromia',
      'Heterocromía',
      'Hétérochromie',
      'Heterochromie',
      'オッドアイ',
      '异色瞳',
      '오드아이',
      'विषमवर्णता',
      'Heterocromia',
      'Heterocromia',
    ],
    'short': [
      'Short',
      'Corto',
      'Corto',
      'Court',
      'Kurz',
      '短毛',
      '短毛',
      '단모',
      'छोटे',
      'Curto',
      'Curto',
    ],
    'medium': [
      'Medium',
      'Medio',
      'Medio',
      'Mi-long',
      'Mittellang',
      '中毛',
      '中长毛',
      '중모',
      'मध्यम',
      'Médio',
      'Médio',
    ],
    'long': [
      'Long',
      'Lungo',
      'Largo',
      'Long',
      'Lang',
      '長毛',
      '长毛',
      '장모',
      'लंबे',
      'Longo',
      'Comprido',
    ],
    'adult': [
      'Adult',
      'Adulto',
      'Adulto',
      'Adulte',
      'Erwachsen',
      '成猫',
      '成年',
      '성묘',
      'वयस्क',
      'Adulto',
      'Adulto',
    ],
    'kitten': [
      'Kitten',
      'Cucciolo',
      'Gatito',
      'Chaton',
      'Jungtier',
      '子猫',
      '幼猫',
      '아기 고양이',
      'बिल्ली का बच्चा',
      'Filhote',
      'Gatinho',
    ],
    'senior': [
      'Senior',
      'Anziano',
      'Mayor',
      'Âgé',
      'Senior',
      'シニア猫',
      '老年',
      '노령묘',
      'वरिष्ठ',
      'Idoso',
      'Sénior',
    ],
  };

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

  String _eventValue({required String en, required String it}) =>
      _localizedValue(en: en, it: it, es: en, fr: en, de: en, ja: en);

  String get eventHalloweenTitle =>
      _eventValue(en: 'Halloween CatDex', it: 'Halloween CatDex');
  String get eventHalloweenDescription => _eventValue(
    en: 'Create limited Halloween cards with your discovered cats.',
    it: 'Crea carte Halloween limitate con i gatti che hai scoperto.',
  );
  String get eventTestBadge => _eventValue(en: 'TEST EVENT', it: 'EVENTO TEST');
  String get eventDiscoverAction =>
      _eventValue(en: 'Discover the event', it: "Scopri l'evento");
  String get eventGenerations =>
      _eventValue(en: 'Event generations', it: 'Generazioni evento');
  String get eventPremiumGenerations => _eventValue(
    en: 'Premium event generations',
    it: 'Generazioni evento Premium',
  );
  String eventUsage(int used, int limit) => _eventValue(
    en: '$used of $limit used',
    it: '$used di $limit utilizzate',
  );
  String eventRemaining(int count) =>
      _eventValue(en: '$count remaining', it: '$count rimaste');
  String eventDaysRemaining(int count) => _eventValue(
    en: '$count days remaining',
    it: '$count giorni rimanenti',
  );
  String get eventFreeArtworks =>
      _eventValue(en: 'Free artwork', it: 'Artwork gratuiti');
  String get eventPremiumArtworks =>
      _eventValue(en: 'Premium artwork', it: 'Artwork Premium');
  String get eventPumpkinsName =>
      _eventValue(en: 'Enchanted pumpkins', it: 'Zucche incantate');
  String get eventPumpkinsDescription => _eventValue(
    en: 'Warm lanterns and enchanted pumpkins.',
    it: 'Lanterne calde e zucche incantate.',
  );
  String get eventMoonlightName =>
      _eventValue(en: 'Moonlit night', it: 'Notte di luna');
  String get eventMoonlightDescription => _eventValue(
    en: 'A mysterious scene under the Halloween moon.',
    it: 'Una scena misteriosa sotto la luna di Halloween.',
  );
  String get eventHauntedName =>
      _eventValue(en: 'Haunted house', it: 'Casa infestata');
  String get eventHauntedDescription => _eventValue(
    en:
        'An illuminated haunted mansion wrapped in purple fog, '
        'lanterns and Halloween magic.',
    it:
        'Una villa stregata illuminata, avvolta da nebbia viola, '
        'lanterne e magia di Halloween.',
  );
  String get eventWitchName =>
      _eventValue(en: 'Witch cat', it: 'Gatto stregone');
  String get eventWitchDescription => _eventValue(
    en: 'An exclusive magical portrait with hat and cape.',
    it: 'Un ritratto magico esclusivo con cappello e mantello.',
  );
  String get eventPumpkinKingName =>
      _eventValue(en: 'Pumpkin King', it: 'Re delle zucche');
  String get eventPumpkinKingDescription => _eventValue(
    en:
        'A royal version with a crown, cape and a throne of '
        'illuminated pumpkins.',
    it:
        'Una versione regale con corona, mantello e un trono di '
        'zucche illuminate.',
  );
  String get eventNightSpiritName =>
      _eventValue(en: 'Night Spirit', it: 'Spirito della notte');
  String get eventNightSpiritDescription => _eventValue(
    en:
        'A mystical artwork with moonlight, spirit flames and '
        'violet and cyan glows.',
    it:
        'Un artwork mistico con luna, fiamme spirituali e '
        'bagliori viola e azzurri.',
  );
  String get eventCollected => _eventValue(en: 'Collected', it: 'Raccolto');
  String get eventNotCollected =>
      _eventValue(en: 'Not collected yet', it: 'Non ancora raccolto');
  String get eventFreeBadge => _eventValue(en: 'FREE', it: 'FREE');
  String get eventPremiumBadge => _eventValue(en: 'PREMIUM', it: 'PREMIUM');
  String get eventChooseCat =>
      _eventValue(en: 'Choose your cat', it: 'Scegli il gatto');
  String get eventFreeVariantsAutomatic => _eventValue(
    en: 'Free variants are assigned automatically.',
    it: 'Le varianti gratuite vengono assegnate automaticamente.',
  );
  String get eventChooseArtwork =>
      _eventValue(en: 'Choose your artwork', it: 'Scegli il tuo artwork');
  String get eventArtworkSelected =>
      _eventValue(en: 'Artwork selected', it: 'Artwork selezionato');
  String eventGenerateVariant(String variantName) => _eventValue(
    en: 'Generate: $variantName',
    it: 'Genera: $variantName',
  );
  String get eventSelectArtworkFirst => _eventValue(
    en: 'Select an artwork before continuing.',
    it: 'Seleziona un artwork prima di continuare.',
  );
  String get eventVariantAlreadyOwned => _eventValue(
    en: 'This cat already owns this variant.',
    it: 'Questo gatto possiede già questa variante.',
  );
  String get eventOpenExistingCard =>
      _eventValue(en: 'Open existing card', it: 'Apri la carta esistente');
  String get eventSelectedVariantInvalid => _eventValue(
    en: 'The selected artwork is not valid for this event.',
    it: "L'artwork selezionato non è valido per questo evento.",
  );
  String get eventSelectedVariantDisabled => _eventValue(
    en: 'The selected artwork is not available right now.',
    it: "L'artwork selezionato non è disponibile in questo momento.",
  );
  String get eventGenerateCard => _eventValue(
    en: 'Generate event card',
    it: 'Genera carta evento',
  );
  String get eventPreparingMagic => _eventValue(
    en: 'Preparing the magic...',
    it: 'Prepariamo la magia...',
  );
  String get eventCatEntering => _eventValue(
    en: 'Your cat is entering the event...',
    it: "Il tuo gatto sta entrando nell'evento...",
  );
  String get eventCreatingCard =>
      _eventValue(en: 'Creating the card...', it: 'Creiamo la carta...');
  String get eventAlmostReady =>
      _eventValue(en: 'Almost ready...', it: 'Quasi pronta...');
  String get eventLongWait => _eventValue(
    en: 'It is taking longer than expected, but creation is still running.',
    it:
        'La creazione sta richiedendo più tempo del previsto, '
        'ma è ancora in corso.',
  );
  String get eventOpenCard => _eventValue(en: 'Open card', it: 'Apri la carta');
  String get eventBackToEvent =>
      _eventValue(en: 'Back to event', it: "Torna all'evento");
  String get eventEnded =>
      _eventValue(en: 'Event ended', it: 'Evento terminato');
  String get eventDiscoverCatFirst => _eventValue(
    en: 'Discover a cat first',
    it: 'Prima scopri un gatto',
  );
  String get eventDiscoverCatHint => _eventValue(
    en: 'Capture or import a cat to join the event.',
    it: "Scatta o importa un gatto per partecipare all'evento.",
  );
  String get eventDiscoverPremium =>
      _eventValue(en: 'Discover Premium', it: 'Scopri Premium');
  String get eventAttemptNotConsumed => _eventValue(
    en: 'Attempt not consumed',
    it: 'Tentativo non consumato',
  );
  String get eventAlreadyCreating => _eventValue(
    en: 'This card is already being created.',
    it: 'Questa carta è già in fase di creazione.',
  );
  String get eventAlbumTitle =>
      _eventValue(en: 'Event album', it: 'Album evento');
  String get eventNoOwnedCards => _eventValue(
    en: 'You have not collected event cards yet.',
    it: 'Non hai ancora raccolto carte evento.',
  );
  String eventFreeCollectionSummary(int count) => _eventValue(
    en: '$count of 3 Free artworks collected',
    it: '$count artwork su 3 Free raccolti',
  );
  String get eventPremiumCollected => _eventValue(
    en: 'Premium artwork collected',
    it: 'Artwork Premium raccolto',
  );
  String get eventPremiumNotCollected => _eventValue(
    en: 'Premium artwork not collected yet',
    it: 'Artwork Premium non ancora raccolto',
  );
  String eventCardsOwned(int count) => _eventValue(
    en: '$count event cards',
    it: '$count carte evento',
  );
  String get eventRendererUnavailable => _eventValue(
    en: 'The card generator is not available right now.',
    it: 'Il generatore carte non è disponibile in questo momento.',
  );
  String get eventInactiveError => _eventValue(
    en: 'The event is no longer active.',
    it: "L'evento non è più attivo.",
  );
  String get eventFreeLimitError => _eventValue(
    en: 'You used all 3 free event generations.',
    it: "Hai utilizzato tutte le 3 generazioni gratuite dell'evento.",
  );
  String eventLimitError(int limit) => _eventValue(
    en: 'You used all $limit event generations.',
    it: "Hai utilizzato tutte le $limit generazioni dell'evento.",
  );
  String get eventPremiumRequiredError => _eventValue(
    en: 'This artwork is reserved for Premium subscribers.',
    it: 'Questo artwork è riservato agli abbonati Premium.',
  );
  String get eventPremiumVerificationError => _eventValue(
    en: 'We cannot verify Premium right now. Try again later.',
    it: 'Non possiamo verificare Premium in questo momento. Riprova più tardi.',
  );
  String get eventQualityError => _eventValue(
    en:
        'The artwork did not pass quality checks. '
        'The attempt was not consumed.',
    it:
        "L'artwork non ha superato il controllo qualità. "
        'Il tentativo non è stato consumato.',
  );
  String get eventPersistenceError => _eventValue(
    en: 'We could not save the card. The attempt was not consumed.',
    it:
        'Non siamo riusciti a salvare la carta. '
        'Il tentativo non è stato consumato.',
  );
  String get eventMissingPhotoError => _eventValue(
    en: 'We cannot prepare this cat photo. Try again or choose another cat.',
    it:
        'Non riusciamo a preparare la foto di questo gatto. '
        'Riprova o scegli un altro gatto.',
  );
  String get eventPhotoUploadError => _eventValue(
    en: 'We could not upload the cat photo. The attempt was not consumed.',
    it:
        'Non siamo riusciti a caricare la foto del gatto. '
        'Il tentativo non è stato consumato.',
  );
  String get eventStoragePermissionError => _eventValue(
    en: 'We cannot upload this photo right now. Check access and try again.',
    it:
        'Non possiamo caricare questa foto in questo momento. '
        "Controlla l'accesso e riprova.",
  );
  String get eventSignedUrlError => _eventValue(
    en:
        'We could not prepare the photo for the card. '
        'The attempt was not consumed.',
    it:
        'Non siamo riusciti a preparare la foto per la carta. '
        'Il tentativo non è stato consumato.',
  );
  String get eventNetworkError => _eventValue(
    en: 'No connection. Check your network and try again.',
    it: 'Connessione non disponibile. Controlla la rete e riprova.',
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
    ja: '撮影',
    zh: '拍摄',
    ko: '촬영',
    hi: 'कैप्चर',
    ptBr: 'Capturar',
    ptPt: 'Capturar',
  );

  String get captureHeading => _localizedValue(
    en: 'Choose a cat photo',
    it: 'Scegli una foto di gatto',
    es: 'Elige una foto de gato',
    fr: 'Choisis une photo de chat',
    de: 'Wahle ein Katzenfoto',
    ja: '猫の写真を選択',
    zh: '选择一张猫咪照片',
    ko: '고양이 사진을 선택하세요',
    hi: 'बिल्ली की तस्वीर चुनें',
    ptBr: 'Escolha uma foto de gato',
    ptPt: 'Escolhe uma fotografia de gato',
  );

  String get captureEmptyMessage => _localizedValue(
    en: 'Take a new photo or import one from your gallery.',
    it: 'Scatta una nuova foto o importane una dalla galleria.',
    es: 'Toma una foto nueva o importala desde tu galeria.',
    fr: 'Prends une nouvelle photo ou importe-en une.',
    de: 'Mach ein neues Foto oder importiere eines.',
    ja: '新しい写真を撮るか、ギャラリーからインポートしてください。',
    zh: '拍摄新照片或从相册导入。',
    ko: '새 사진을 찍거나 갤러리에서 가져오세요.',
    hi: 'नई तस्वीर लें या गैलरी से चुनें।',
    ptBr: 'Tire uma foto ou importe da galeria.',
    ptPt: 'Tira uma fotografia ou importa da galeria.',
  );

  String get takePhotoAction => _localizedValue(
    en: 'Take Photo',
    it: 'Scatta Foto',
    es: 'Tomar Foto',
    fr: 'Prendre Photo',
    de: 'Foto Machen',
    ja: '写真を撮る',
    zh: '拍照',
    ko: '사진 촬영',
    hi: 'तस्वीर लें',
    ptBr: 'Tirar foto',
    ptPt: 'Tirar fotografia',
  );

  String get importFromGalleryAction => _localizedValue(
    en: 'Import from Gallery',
    it: 'Importa dalla Galleria',
    es: 'Importar de Galeria',
    fr: 'Importer de la Galerie',
    de: 'Aus Galerie Importieren',
    ja: 'ギャラリーからインポート',
    zh: '从相册导入',
    ko: '갤러리에서 가져오기',
    hi: 'गैलरी से चुनें',
    ptBr: 'Importar da galeria',
    ptPt: 'Importar da galeria',
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
    zh: '继续',
    ko: '계속',
    hi: 'जारी रखें',
    ptBr: 'Continuar',
    ptPt: 'Continuar',
  );

  String get analysisTitle => _localizedValue(
    en: 'Analysis',
    it: 'Analisi',
    es: 'Analisis',
    fr: 'Analyse',
    de: 'Analyse',
    ja: '分析',
    zh: '分析',
    ko: '분석',
    hi: 'विश्लेषण',
    ptBr: 'Análise',
    ptPt: 'Análise',
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
    en: 'CatDex is checking the photo and preparing your discovery.',
    it: 'CatDex sta controllando la foto e preparando la scoperta.',
    es: 'CatDex revisa la foto y prepara tu hallazgo.',
    fr: 'CatDex analyse la photo et prepare ta decouverte.',
    de: 'CatDex pruft das Foto und bereitet deine Entdeckung vor.',
    ja: 'CatDex is checking the photo and preparing your discovery.',
  );

  String get analysisResultTitle => _localizedValue(
    en: 'New discovery!',
    it: 'Nuova scoperta!',
    es: 'Nueva descoberta!',
    fr: 'Nouvelle decouverte!',
    de: 'Neue Entdeckung!',
    ja: 'New discovery!',
    zh: '新发现！',
    ko: '새로운 발견!',
    hi: 'नई खोज!',
    ptBr: 'Nova descoberta!',
    ptPt: 'Nova descoberta!',
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

  String get coatColorLabel => _localizedValue(
    en: 'Coat color',
    it: 'Colore mantello',
    es: 'Color del pelaje',
    fr: 'Couleur du pelage',
    de: 'Fellfarbe',
    ja: 'Coat color',
  );

  String get coatPatternLabel => _localizedValue(
    en: 'Coat pattern',
    it: 'Pattern mantello',
    es: 'Patron del pelaje',
    fr: 'Motif du pelage',
    de: 'Fellmuster',
    ja: '毛柄',
    zh: '花纹',
    ko: '무늬',
    hi: 'पैटर्न',
    ptBr: 'Padrão da pelagem',
    ptPt: 'Padrão da pelagem',
  );

  String get eyeColorLabel => _localizedValue(
    en: 'Eye color',
    it: 'Colore occhi',
    es: 'Color de ojos',
    fr: 'Couleur des yeux',
    de: 'Augenfarbe',
    ja: 'Eye color',
  );

  String get hairLengthLabel => _localizedValue(
    en: 'Hair length',
    it: 'Lunghezza pelo',
    es: 'Longitud del pelo',
    fr: 'Longueur du poil',
    de: 'Felllange',
    ja: '毛の長さ',
    zh: '毛发长度',
    ko: '털 길이',
    hi: 'बालों की लंबाई',
    ptBr: 'Comprimento do pelo',
    ptPt: 'Comprimento do pelo',
  );

  String get estimatedAgeLabel => _localizedValue(
    en: 'Estimated age',
    it: 'Eta stimata',
    es: 'Edad estimada',
    fr: 'Age estime',
    de: 'Geschatztes Alter',
    ja: '推定年齢',
    zh: '估计年龄',
    ko: '추정 나이',
    hi: 'अनुमानित आयु',
    ptBr: 'Idade estimada',
    ptPt: 'Idade estimada',
  );

  String get funFactLabel => _localizedValue(
    en: 'Fun fact',
    it: 'Curiosita',
    es: 'Dato curioso',
    fr: 'Info amusante',
    de: 'Fun Fact',
    ja: 'Fun fact',
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
    ja: '物語',
    zh: '故事',
    ko: '이야기',
    hi: 'कहानी',
    ptBr: 'História',
    ptPt: 'História',
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
    zh: '保存到 CatDex',
    ko: 'CatDex에 저장',
    hi: 'CatDex में सहेजें',
    ptBr: 'Salvar no CatDex',
    ptPt: 'Guardar no CatDex',
  );

  String get addToCatDexAction => _localizedValue(
    en: 'Add to CatDex',
    it: 'Aggiungi al CatDex',
    es: 'Anadir al CatDex',
    fr: 'Ajouter au CatDex',
    de: 'Zu CatDex Hinzufugen',
    ja: 'Add to CatDex',
    zh: '添加到 CatDex',
    ko: 'CatDex에 추가',
    hi: 'CatDex में जोड़ें',
    ptBr: 'Adicionar ao CatDex',
    ptPt: 'Adicionar ao CatDex',
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
    ja: '選択した画像のプレビュー',
    zh: '所选图片预览',
    ko: '선택한 이미지 미리보기',
    hi: 'चुनी गई तस्वीर का पूर्वावलोकन',
    ptBr: 'Prévia da imagem selecionada',
    ptPt: 'Pré-visualização da imagem selecionada',
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
    zh: 'CatDex',
    ko: 'CatDex',
    hi: 'CatDex',
    ptBr: 'CatDex',
    ptPt: 'CatDex',
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
    it: 'Curioso, Amichevole, Vivace',
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
    ja: 'プロフィール',
    zh: '个人资料',
    ko: '프로필',
    hi: 'प्रोफ़ाइल',
    ptBr: 'Perfil',
    ptPt: 'Perfil',
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

  String _mapValue({required String en, required String it}) {
    return _localizedValue(
      en: en,
      it: it,
      es: en,
      fr: en,
      de: en,
      ja: en,
    );
  }

  String _localizedValue({
    required String en,
    required String it,
    required String es,
    required String fr,
    required String de,
    required String ja,
    String? zh,
    String? ko,
    String? hi,
    String? ptBr,
    String? ptPt,
  }) {
    return switch (locale.languageCode) {
      'it' => it,
      'es' => es,
      'fr' => fr,
      'de' => de,
      'ja' => ja,
      'zh' => zh ?? en,
      'ko' => ko ?? en,
      'hi' => hi ?? en,
      'pt' when locale.countryCode == 'PT' => ptPt ?? ptBr ?? en,
      'pt' => ptBr ?? ptPt ?? en,
      _ => en,
    };
  }

  String _coreValue(String key) {
    final translations =
        _coreTranslations[_localeKey] ?? _coreTranslations['en_US']!;
    return translations[key] ?? _coreTranslations['en_US']![key] ?? key;
  }

  String get _localeKey {
    final countryCode = locale.countryCode;
    return countryCode == null || countryCode.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_$countryCode';
  }

  static const _coreTranslations = <String, Map<String, String>>{
    'en_US': {
      'cardsTitle': 'Cards',
      'albumTitle': 'Album',
      'settingsLanguage': 'Language',
      'editDetails': 'Edit details',
      'details': 'Details',
      'editDetailsSubtitle': 'Correct the details before saving to CatDex.',
      'saveChanges': 'Save changes',
      'cancel': 'Cancel',
      'nameDiscoveryTitle': 'Name your discovery',
      'nameDiscoverySubtitle':
          'Choose a name for this cat or keep the suggested one.',
      'species': 'Species',
      'personality': 'Personality',
      'rarity': 'Rarity',
      'fur': 'Coat',
      'eyes': 'Eyes',
      'unknown': 'Unknown',
      'notDetected': 'Not detected',
      'common': 'Common',
      'uncommon': 'Uncommon',
      'rare': 'Rare',
      'epic': 'Epic',
      'legendary': 'Legendary',
      'curious': 'Curious',
      'sweet': 'Sweet',
      'shy': 'Shy',
      'playful': 'Playful',
      'elegant': 'Elegant',
      'mysterious': 'Mysterious',
      'energetic': 'Energetic',
      'relaxed': 'Calm',
      'calm': 'Calm',
      'lazy': 'Lazy',
      'normal': 'Normal',
      'catDomestic': 'Domestic cat',
      'catDomesticTabby': 'Domestic tabby cat',
      'catDomesticBicolor': 'Domestic bicolor cat',
      'catEuropeanShorthair': 'European Shorthair',
      'catSiamese': 'Siamese',
      'catPersian': 'Persian',
      'catMaineCoon': 'Maine Coon',
      'catBritishShorthair': 'British Shorthair',
    },
    'it': {
      'cardsTitle': 'Carte',
      'albumTitle': 'Album',
      'settingsLanguage': 'Lingua',
      'editDetails': 'Modifica dettagli',
      'details': 'Dettagli',
      'editDetailsSubtitle': 'Correggi i dati prima di salvare nel CatDex.',
      'saveChanges': 'Salva modifiche',
      'cancel': 'Annulla',
      'nameDiscoveryTitle': 'Dai un nome alla scoperta',
      'nameDiscoverySubtitle':
          'Scegli un nome per questo gatto o mantieni quello suggerito.',
      'species': 'Specie',
      'personality': 'Personalità',
      'rarity': 'Rarità',
      'fur': 'Mantello',
      'eyes': 'Occhi',
      'unknown': 'Sconosciuto',
      'notDetected': 'Non rilevato',
      'common': 'Comune',
      'uncommon': 'Non comune',
      'rare': 'Rara',
      'epic': 'Epica',
      'legendary': 'Leggendaria',
      'curious': 'Curioso',
      'sweet': 'Dolce',
      'shy': 'Timido',
      'playful': 'Giocherellone',
      'elegant': 'Elegante',
      'mysterious': 'Misterioso',
      'energetic': 'Energico',
      'relaxed': 'Tranquillo',
      'calm': 'Tranquillo',
      'lazy': 'Pigro',
      'normal': 'Normale',
      'catDomestic': 'Gatto domestico',
      'catDomesticTabby': 'Gatto domestico tigrato',
      'catDomesticBicolor': 'Gatto domestico bicolore',
      'catEuropeanShorthair': 'Gatto europeo',
      'catSiamese': 'Siamese',
      'catPersian': 'Persiano',
      'catMaineCoon': 'Maine Coon',
      'catBritishShorthair': 'British Shorthair',
    },
    'es': {
      'cardsTitle': 'Cartas',
      'albumTitle': 'Álbum',
      'settingsLanguage': 'Idioma',
      'editDetails': 'Editar detalles',
      'details': 'Detalles',
      'editDetailsSubtitle': 'Corrige los datos antes de guardar en CatDex.',
      'saveChanges': 'Guardar cambios',
      'cancel': 'Cancelar',
      'nameDiscoveryTitle': 'Pon nombre a tu descubrimiento',
      'nameDiscoverySubtitle': 'Elige un nombre o conserva el nombre sugerido.',
      'species': 'Especie',
      'personality': 'Personalidad',
      'rarity': 'Rareza',
      'fur': 'Pelaje',
      'eyes': 'Ojos',
      'unknown': 'Desconocido',
      'notDetected': 'No detectado',
      'common': 'Común',
      'uncommon': 'Poco común',
      'rare': 'Rara',
      'epic': 'Épica',
      'legendary': 'Legendaria',
      'curious': 'Curioso',
      'sweet': 'Dulce',
      'shy': 'Tímido',
      'playful': 'Juguetón',
      'elegant': 'Elegante',
      'mysterious': 'Misterioso',
      'energetic': 'Enérgico',
      'relaxed': 'Tranquilo',
      'calm': 'Tranquilo',
      'lazy': 'Perezoso',
      'normal': 'Normal',
      'catDomestic': 'Gato doméstico',
      'catDomesticTabby': 'Gato doméstico atigrado',
      'catDomesticBicolor': 'Gato doméstico bicolor',
    },
    'fr': {
      'cardsTitle': 'Cartes',
      'albumTitle': 'Album',
      'settingsLanguage': 'Langue',
      'editDetails': 'Modifier les détails',
      'details': 'Détails',
      'editDetailsSubtitle':
          'Corrige les données avant de les enregistrer dans CatDex.',
      'saveChanges': 'Enregistrer',
      'cancel': 'Annuler',
      'nameDiscoveryTitle': 'Nomme ta découverte',
      'nameDiscoverySubtitle': 'Choisis un nom ou garde celui proposé.',
      'species': 'Espèce',
      'personality': 'Personnalité',
      'rarity': 'Rareté',
      'fur': 'Pelage',
      'eyes': 'Yeux',
      'unknown': 'Inconnu',
      'notDetected': 'Non détecté',
      'common': 'Commune',
      'uncommon': 'Peu commune',
      'rare': 'Rare',
      'epic': 'Épique',
      'legendary': 'Légendaire',
      'curious': 'Curieux',
      'sweet': 'Doux',
      'shy': 'Timide',
      'playful': 'Joueur',
      'elegant': 'Élégant',
      'mysterious': 'Mystérieux',
      'energetic': 'Énergique',
      'relaxed': 'Calme',
      'calm': 'Calme',
      'lazy': 'Paresseux',
      'normal': 'Normal',
      'catDomestic': 'Chat domestique',
      'catDomesticTabby': 'Chat domestique tigré',
      'catDomesticBicolor': 'Chat domestique bicolore',
    },
    'de': {
      'cardsTitle': 'Karten',
      'albumTitle': 'Album',
      'settingsLanguage': 'Sprache',
      'editDetails': 'Details bearbeiten',
      'details': 'Details',
      'editDetailsSubtitle':
          'Korrigiere die Daten vor dem Speichern im CatDex.',
      'saveChanges': 'Änderungen speichern',
      'cancel': 'Abbrechen',
      'nameDiscoveryTitle': 'Benenne deine Entdeckung',
      'nameDiscoverySubtitle': 'Wähle einen Namen oder behalte den Vorschlag.',
      'species': 'Art',
      'personality': 'Persönlichkeit',
      'rarity': 'Seltenheit',
      'fur': 'Fell',
      'eyes': 'Augen',
      'unknown': 'Unbekannt',
      'notDetected': 'Nicht erkannt',
      'common': 'Gewöhnlich',
      'uncommon': 'Ungewöhnlich',
      'rare': 'Selten',
      'epic': 'Episch',
      'legendary': 'Legendär',
      'curious': 'Neugierig',
      'sweet': 'Lieb',
      'shy': 'Schüchtern',
      'playful': 'Verspielt',
      'elegant': 'Elegant',
      'mysterious': 'Geheimnisvoll',
      'energetic': 'Energiegeladen',
      'relaxed': 'Ruhig',
      'calm': 'Ruhig',
      'lazy': 'Faul',
      'normal': 'Normal',
      'catDomestic': 'Hauskatze',
      'catDomesticTabby': 'Getigerte Hauskatze',
      'catDomesticBicolor': 'Zweifarbige Hauskatze',
    },
    'ja': {
      'cardsTitle': 'カード',
      'albumTitle': 'アルバム',
      'settingsLanguage': '言語',
      'editDetails': '詳細を編集',
      'details': '詳細',
      'editDetailsSubtitle': 'CatDexに保存する前に内容を修正できます。',
      'saveChanges': '変更を保存',
      'cancel': 'キャンセル',
      'nameDiscoveryTitle': '発見した猫に名前をつける',
      'nameDiscoverySubtitle': '名前を選ぶか、候補の名前をそのまま使えます。',
      'species': '種類',
      'personality': '性格',
      'rarity': 'レア度',
      'fur': '毛色',
      'eyes': '目',
      'unknown': '不明',
      'notDetected': '検出されませんでした',
      'common': 'コモン',
      'uncommon': 'アンコモン',
      'rare': 'レア',
      'epic': 'エピック',
      'legendary': 'レジェンダリー',
      'curious': '好奇心旺盛',
      'sweet': '優しい',
      'shy': '恥ずかしがり',
      'playful': '遊び好き',
      'elegant': '上品',
      'mysterious': 'ミステリアス',
      'energetic': '元気',
      'relaxed': '穏やか',
      'calm': '穏やか',
      'lazy': 'のんびり',
      'normal': 'ノーマル',
      'catDomestic': 'イエネコ',
      'catDomesticTabby': 'トラ柄のイエネコ',
      'catDomesticBicolor': '二色柄のイエネコ',
    },
    'zh_CN': {
      'cardsTitle': '卡牌',
      'albumTitle': '图鉴',
      'settingsLanguage': '语言',
      'editDetails': '编辑详情',
      'details': '详情',
      'editDetailsSubtitle': '保存到 CatDex 前可以更正信息。',
      'saveChanges': '保存修改',
      'cancel': '取消',
      'nameDiscoveryTitle': '为新发现命名',
      'nameDiscoverySubtitle': '选择一个名字，或保留建议的名字。',
      'species': '种类',
      'personality': '性格',
      'rarity': '稀有度',
      'fur': '毛色',
      'eyes': '眼睛',
      'unknown': '未知',
      'notDetected': '未检测到',
      'common': '普通',
      'uncommon': '不常见',
      'rare': '稀有',
      'epic': '史诗',
      'legendary': '传说',
      'curious': '好奇',
      'sweet': '温柔',
      'shy': '害羞',
      'playful': '爱玩',
      'elegant': '优雅',
      'mysterious': '神秘',
      'energetic': '活泼',
      'relaxed': '平静',
      'calm': '平静',
      'lazy': '慵懒',
      'normal': '普通',
      'catDomestic': '家猫',
      'catDomesticTabby': '虎斑家猫',
      'catDomesticBicolor': '双色家猫',
    },
    'ko': {
      'cardsTitle': '카드',
      'albumTitle': '앨범',
      'settingsLanguage': '언어',
      'editDetails': '세부 정보 수정',
      'details': '세부 정보',
      'editDetailsSubtitle': 'CatDex에 저장하기 전에 정보를 수정하세요.',
      'saveChanges': '변경 저장',
      'cancel': '취소',
      'nameDiscoveryTitle': '새로운 발견에 이름 짓기',
      'nameDiscoverySubtitle': '이름을 선택하거나 추천 이름을 유지하세요.',
      'species': '종류',
      'personality': '성격',
      'rarity': '희귀도',
      'fur': '털색',
      'eyes': '눈',
      'unknown': '알 수 없음',
      'notDetected': '감지되지 않음',
      'common': '일반',
      'uncommon': '고급',
      'rare': '희귀',
      'epic': '영웅',
      'legendary': '전설',
      'curious': '호기심 많음',
      'sweet': '다정함',
      'shy': '수줍음',
      'playful': '장난꾸러기',
      'elegant': '우아함',
      'mysterious': '신비로움',
      'energetic': '활기참',
      'relaxed': '차분함',
      'calm': '차분함',
      'lazy': '느긋함',
      'normal': '일반',
      'catDomestic': '집고양이',
      'catDomesticTabby': '태비 집고양이',
      'catDomesticBicolor': '바이컬러 집고양이',
    },
    'hi_IN': {
      'cardsTitle': 'कार्ड',
      'albumTitle': 'एल्बम',
      'settingsLanguage': 'भाषा',
      'editDetails': 'विवरण बदलें',
      'details': 'विवरण',
      'editDetailsSubtitle': 'CatDex में सहेजने से पहले जानकारी सुधारें।',
      'saveChanges': 'बदलाव सहेजें',
      'cancel': 'रद्द करें',
      'nameDiscoveryTitle': 'अपनी खोज को नाम दें',
      'nameDiscoverySubtitle': 'नाम चुनें या सुझाया गया नाम रखें।',
      'species': 'प्रजाति',
      'personality': 'स्वभाव',
      'rarity': 'दुर्लभता',
      'fur': 'रोम',
      'eyes': 'आँखें',
      'unknown': 'अज्ञात',
      'notDetected': 'पता नहीं चला',
      'common': 'सामान्य',
      'uncommon': 'असामान्य',
      'rare': 'दुर्लभ',
      'epic': 'महाकाव्य',
      'legendary': 'पौराणिक',
      'curious': 'जिज्ञासु',
      'sweet': 'प्यारा',
      'shy': 'शर्मीला',
      'playful': 'खेलप्रिय',
      'elegant': 'शानदार',
      'mysterious': 'रहस्यमय',
      'energetic': 'ऊर्जावान',
      'relaxed': 'शांत',
      'calm': 'शांत',
      'lazy': 'आलसी',
      'normal': 'सामान्य',
      'catDomestic': 'घरेलू बिल्ली',
      'catDomesticTabby': 'धारीदार घरेलू बिल्ली',
      'catDomesticBicolor': 'दो रंगों वाली घरेलू बिल्ली',
    },
    'pt_BR': {
      'cardsTitle': 'Cartas',
      'albumTitle': 'Álbum',
      'settingsLanguage': 'Idioma',
      'editDetails': 'Editar detalhes',
      'details': 'Detalhes',
      'editDetailsSubtitle': 'Corrija os dados antes de salvar no CatDex.',
      'saveChanges': 'Salvar alterações',
      'cancel': 'Cancelar',
      'nameDiscoveryTitle': 'Dê um nome à descoberta',
      'nameDiscoverySubtitle': 'Escolha um nome ou mantenha o sugerido.',
      'species': 'Espécie',
      'personality': 'Personalidade',
      'rarity': 'Raridade',
      'fur': 'Pelagem',
      'eyes': 'Olhos',
      'unknown': 'Desconhecido',
      'notDetected': 'Não detectado',
      'common': 'Comum',
      'uncommon': 'Incomum',
      'rare': 'Rara',
      'epic': 'Épica',
      'legendary': 'Lendária',
      'curious': 'Curioso',
      'sweet': 'Doce',
      'shy': 'Tímido',
      'playful': 'Brincalhão',
      'elegant': 'Elegante',
      'mysterious': 'Misterioso',
      'energetic': 'Enérgico',
      'relaxed': 'Tranquilo',
      'calm': 'Tranquilo',
      'lazy': 'Preguiçoso',
      'normal': 'Normal',
      'catDomestic': 'Gato doméstico',
      'catDomesticTabby': 'Gato doméstico tigrado',
      'catDomesticBicolor': 'Gato doméstico bicolor',
    },
    'pt_PT': {
      'cardsTitle': 'Cartas',
      'albumTitle': 'Álbum',
      'settingsLanguage': 'Idioma',
      'editDetails': 'Editar detalhes',
      'details': 'Detalhes',
      'editDetailsSubtitle': 'Corrige os dados antes de guardar no CatDex.',
      'saveChanges': 'Guardar alterações',
      'cancel': 'Cancelar',
      'nameDiscoveryTitle': 'Dá um nome à descoberta',
      'nameDiscoverySubtitle': 'Escolhe um nome ou mantém o sugerido.',
      'species': 'Espécie',
      'personality': 'Personalidade',
      'rarity': 'Raridade',
      'fur': 'Pelagem',
      'eyes': 'Olhos',
      'unknown': 'Desconhecido',
      'notDetected': 'Não detetado',
      'common': 'Comum',
      'uncommon': 'Incomum',
      'rare': 'Rara',
      'epic': 'Épica',
      'legendary': 'Lendária',
      'curious': 'Curioso',
      'sweet': 'Doce',
      'shy': 'Tímido',
      'playful': 'Brincalhão',
      'elegant': 'Elegante',
      'mysterious': 'Misterioso',
      'energetic': 'Energético',
      'relaxed': 'Tranquilo',
      'calm': 'Tranquilo',
      'lazy': 'Preguiçoso',
      'normal': 'Normal',
      'catDomestic': 'Gato doméstico',
      'catDomesticTabby': 'Gato doméstico tigrado',
      'catDomesticBicolor': 'Gato doméstico bicolor',
    },
  };
}

class AppLanguageOption {
  const AppLanguageOption({
    required this.locale,
    required this.nativeName,
  });

  final Locale locale;
  final String nativeName;
}

class _CatDexLocalizationsDelegate
    extends LocalizationsDelegate<CatDexLocalizations> {
  const _CatDexLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return CatDexLocalizations.supportedLocales.any(
      (supportedLocale) =>
          supportedLocale.languageCode == locale.languageCode &&
          (supportedLocale.countryCode == null ||
              locale.countryCode == null ||
              supportedLocale.countryCode == locale.countryCode),
    );
  }

  @override
  Future<CatDexLocalizations> load(Locale locale) {
    return SynchronousFuture<CatDexLocalizations>(CatDexLocalizations(locale));
  }

  @override
  bool shouldReload(_CatDexLocalizationsDelegate old) => false;
}
