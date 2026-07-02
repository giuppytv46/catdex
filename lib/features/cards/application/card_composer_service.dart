import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

final cardComposerProvider = Provider<CardComposer>((_) {
  return const RealCardComposerService();
});

// A narrow interface keeps card generation replaceable in widget tests.
// ignore: one_member_abstracts
abstract class CardComposer {
  Future<String> generateCardImage({
    required CatDiscovery discovery,
    required CatDisplayData display,
    int collectionNumber = 1,
  });
}

class RealCardComposerService implements CardComposer {
  const RealCardComposerService({
    this.outputDirectory,
    this.artworkAsset = 'assets/cards/card_artwork_test.png',
    this.canvasWidth = defaultCanvasWidth,
    this.canvasHeight = defaultCanvasHeight,
  });

  static const defaultCanvasWidth = 1500;
  static const defaultCanvasHeight = 2100;

  final Directory? outputDirectory;
  final String artworkAsset;
  final int canvasWidth;
  final int canvasHeight;

  @override
  Future<String> generateCardImage({
    required CatDiscovery discovery,
    required CatDisplayData display,
    int collectionNumber = 1,
  }) async {
    debugPrint('CATDEX_CARD_MODE artwork_plus_text_v1');
    debugPrint('CATDEX_TEXT_RENDERER TextPainter');
    final base = await _loadImage(artworkAsset);
    final canvas = img.copyResize(
      base,
      width: canvasWidth,
      height: canvasHeight,
      interpolation: img.Interpolation.average,
    );

    await _drawCardText(canvas, discovery, display, collectionNumber);

    final directory = await _cardsDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final version = discovery.card?.cardVersion ?? 1;
    final output = File('${directory.path}/card_${discovery.id}_v$version.png');
    await output.writeAsBytes(img.encodePng(canvas), flush: true);

    return output.path;
  }

  Future<img.Image> _loadImage(String path) async {
    final bytes = await _loadBytes(path);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const CardComposerException('Could not decode card image.');
    }

    return decoded;
  }

  Future<Uint8List> _loadBytes(String path) async {
    final normalized = path.replaceFirst('asset:', '');
    if (normalized.startsWith('assets/')) {
      final data = await rootBundle.load(normalized);
      return data.buffer.asUint8List();
    }

    final file = File(normalized);
    if (!file.existsSync()) {
      throw CardComposerException('Missing image file: $normalized');
    }

    return file.readAsBytes();
  }

  Future<void> _drawCardText(
    img.Image canvas,
    CatDiscovery discovery,
    CatDisplayData display,
    int collectionNumber,
  ) async {
    final recorder = ui.PictureRecorder();
    final textCanvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
    );
    final number = '#${collectionNumber.toString().padLeft(4, '0')}';
    final name = display.displayName.toUpperCase();
    final species = display.displaySpecies;
    const white = ui.Color(0xFFFFFFFF);
    const navy = ui.Color(0xFF162033);

    _drawFittedText(
      canvas: textCanvas,
      text: number,
      rect: _rect(135, 145, 260, 80),
      style: painting.TextStyle(
        color: white,
        fontSize: _fontSize(56),
        fontWeight: ui.FontWeight.w900,
        letterSpacing: 1,
        shadows: const [
          ui.Shadow(
            color: ui.Color(0x59000000),
            offset: ui.Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      align: ui.TextAlign.left,
    );
    _drawFittedText(
      canvas: textCanvas,
      text: name,
      rect: _rect(520, 135, 460, 90),
      style: painting.TextStyle(
        color: white,
        fontSize: _fontSize(62),
        fontWeight: ui.FontWeight.w900,
        letterSpacing: 2,
        shadows: const [
          ui.Shadow(
            color: ui.Color(0x59000000),
            offset: ui.Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
    _drawRarityIcons(
      canvas: textCanvas,
      rect: _rect(1030, 145, 300, 80),
      rarity: discovery.rarity,
    );
    _drawFittedText(
      canvas: textCanvas,
      text: species,
      rect: _rect(310, 1320, 880, 100),
      style: painting.TextStyle(
        color: navy,
        fontSize: _fontSize(50),
        fontWeight: ui.FontWeight.w900,
        letterSpacing: 0.2,
        shadows: const [
          ui.Shadow(
            color: ui.Color(0x59FFFFFF),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasWidth, canvasHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    if (byteData == null) {
      throw const CardComposerException('Could not render card text.');
    }

    final textLayer = img.decodePng(byteData.buffer.asUint8List());
    if (textLayer == null) {
      throw const CardComposerException('Could not decode card text layer.');
    }

    img.compositeImage(canvas, textLayer);
  }

  void _drawFittedText({
    required ui.Canvas canvas,
    required String text,
    required ui.Rect rect,
    required painting.TextStyle style,
    ui.TextAlign align = ui.TextAlign.center,
    int maxLines = 1,
  }) {
    const minFontSize = 28.0;
    final scale = canvasWidth / defaultCanvasWidth;
    var fontSize = style.fontSize ?? minFontSize;
    final minimum = minFontSize * scale;
    late painting.TextPainter painter;

    while (true) {
      painter = painting.TextPainter(
        text: painting.TextSpan(
          text: text,
          style: style.copyWith(fontSize: fontSize),
        ),
        textAlign: align,
        textDirection: ui.TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: '…',
      )..layout(maxWidth: rect.width);

      if ((!painter.didExceedMaxLines && painter.height <= rect.height) ||
          fontSize <= minimum) {
        break;
      }

      fontSize -= 2 * scale;
    }

    final dy = rect.top + ((rect.height - painter.height) / 2);
    painter.paint(canvas, ui.Offset(rect.left, dy));
  }

  void _drawRarityIcons({
    required ui.Canvas canvas,
    required ui.Rect rect,
    required CatRarity rarity,
  }) {
    final activeStars = _activeStarsFor(rarity);
    final starSize = _sx(42).toDouble();
    final spacing = _sx(10).toDouble();
    final totalWidth = (starSize * 5) + (spacing * 4);
    final startX = rect.right - totalWidth;
    final centerY = rect.top + (rect.height / 2);

    for (var index = 0; index < 5; index++) {
      final center = ui.Offset(
        startX + (index * (starSize + spacing)) + (starSize / 2),
        centerY,
      );
      final isActive = index < activeStars;
      _drawStarIcon(
        canvas,
        center: center,
        radius: starSize / 2,
        active: isActive,
      );
    }
  }

  void _drawStarIcon(
    ui.Canvas canvas, {
    required ui.Offset center,
    required double radius,
    required bool active,
  }) {
    final outerRadius = radius;
    final innerRadius = radius * 0.46;
    final path = ui.Path();

    for (var point = 0; point < 10; point++) {
      final angle = (-math.pi / 2) + (point * math.pi / 5);
      final currentRadius = point.isEven ? outerRadius : innerRadius;
      final offset = ui.Offset(
        center.dx + (math.cos(angle) * currentRadius),
        center.dy + (math.sin(angle) * currentRadius),
      );
      if (point == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x33000000)
      ..style = ui.PaintingStyle.fill;
    canvas.drawPath(path.shift(const ui.Offset(0, 2)), shadowPaint);

    final fillPaint = ui.Paint()
      ..color = active ? const ui.Color(0xFFF5B52D) : const ui.Color(0x33F5B52D)
      ..style = ui.PaintingStyle.fill;
    final strokePaint = ui.Paint()
      ..color = active ? const ui.Color(0xFFFFE28A) : const ui.Color(0x99C8962F)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _sx(3).toDouble()
      ..strokeJoin = ui.StrokeJoin.round;

    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint);
  }

  ui.Rect _rect(int x, int y, int width, int height) {
    return ui.Rect.fromLTWH(
      _sx(x).toDouble(),
      _sy(y).toDouble(),
      _sx(width).toDouble(),
      _sy(height).toDouble(),
    );
  }

  double _fontSize(double value) {
    return value * canvasWidth / defaultCanvasWidth;
  }

  int _activeStarsFor(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => 1,
      CatRarity.uncommon => 2,
      CatRarity.rare => 3,
      CatRarity.epic => 4,
      CatRarity.legendary || CatRarity.mythic => 5,
    };
  }

  int _sx(int value) {
    return (value * canvasWidth / defaultCanvasWidth).round().clamp(
      1,
      canvasWidth,
    );
  }

  int _sy(int value) {
    return (value * canvasHeight / defaultCanvasHeight).round().clamp(
      1,
      canvasHeight,
    );
  }

  Future<Directory> _cardsDirectory() async {
    if (outputDirectory != null) {
      return outputDirectory!;
    }

    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/catdex/cards');
  }
}

@Deprecated('Use RealCardComposerService or CardComposer instead.')
class CardComposerService extends RealCardComposerService {
  @Deprecated('Use RealCardComposerService or CardComposer instead.')
  const CardComposerService({
    super.outputDirectory,
    super.artworkAsset,
    super.canvasWidth,
    super.canvasHeight,
  });
}

class CardComposerException implements Exception {
  const CardComposerException(this.message);

  final String message;

  @override
  String toString() => message;
}

CatDiscovery discoveryWithGeneratedCard({
  required CatDiscovery discovery,
  required String cardImagePath,
  String? cutoutImagePath,
  DateTime? generatedAt,
}) {
  final previousCard = discovery.card;
  final cardGeneratedAt = generatedAt ?? DateTime.now().toUtc();
  final card = CatDiscoveryCard(
    cardId: previousCard?.cardId ?? 'card-${discovery.id}',
    discoveryId: discovery.id,
    cardFrameStyle: previousCard?.cardFrameStyle ?? 'green_simple_frame',
    cardBackgroundStyle: previousCard?.cardBackgroundStyle ?? 'default',
    cardRarityStyle: previousCard?.cardRarityStyle ?? discovery.rarity.name,
    isEventCard: previousCard?.isEventCard ?? false,
    originalPhotoPath:
        previousCard?.originalPhotoPath ??
        discovery.originalPhotoPath ??
        discovery.displayPhotoPath,
    generatedAt: cardGeneratedAt,
    eventThemeId: previousCard?.eventThemeId,
    cardImageUrl: previousCard?.cardImageUrl,
    cardImagePath: cardImagePath,
    aiIllustrationUrl: previousCard?.aiIllustrationUrl,
    aiIllustrationPath: previousCard?.aiIllustrationPath,
    illustratedCatImageUrl: previousCard?.illustratedCatImageUrl,
    illustratedCatImagePath: previousCard?.illustratedCatImagePath,
    cutoutImagePath: cutoutImagePath ?? previousCard?.cutoutImagePath,
    illustratedCatPath: previousCard?.illustratedCatPath,
    cardTemplateId: previousCard?.cardTemplateId ?? 'common_clean',
    cardVersion: previousCard?.cardVersion ?? 1,
  );

  return CatDiscovery(
    id: discovery.id,
    playerId: discovery.playerId,
    speciesId: discovery.speciesId,
    variantId: discovery.variantId,
    rarity: discovery.rarity,
    personality: discovery.personality,
    traits: discovery.traits,
    discoveredAt: discovery.discoveredAt,
    friendshipPoints: discovery.friendshipPoints,
    customName: discovery.customName,
    suggestedName: discovery.suggestedName,
    city: discovery.city,
    country: discovery.country,
    originalPhotoPath: discovery.originalPhotoPath,
    displayPhotoPath: discovery.displayPhotoPath,
    story: discovery.story,
    funFact: discovery.funFact,
    coatColor: discovery.coatColor,
    coatPattern: discovery.coatPattern,
    eyeColor: discovery.eyeColor,
    hairLength: discovery.hairLength,
    estimatedAge: discovery.estimatedAge,
    xpEarned: discovery.xpEarned,
    coinsEarned: discovery.coinsEarned,
    confidenceScore: discovery.confidenceScore,
    card: card,
    favorite: discovery.favorite,
  );
}

CatDiscovery discoveryWithGeneratedCutout({
  required CatDiscovery discovery,
  required String cutoutImagePath,
  DateTime? generatedAt,
}) {
  final previousCard = discovery.card;
  final cardGeneratedAt =
      previousCard?.generatedAt ?? generatedAt ?? DateTime.now().toUtc();
  final card = CatDiscoveryCard(
    cardId: previousCard?.cardId ?? 'card-${discovery.id}',
    discoveryId: discovery.id,
    cardFrameStyle: previousCard?.cardFrameStyle ?? 'green_simple_frame',
    cardBackgroundStyle: previousCard?.cardBackgroundStyle ?? 'default',
    cardRarityStyle: previousCard?.cardRarityStyle ?? discovery.rarity.name,
    isEventCard: previousCard?.isEventCard ?? false,
    originalPhotoPath:
        previousCard?.originalPhotoPath ??
        discovery.originalPhotoPath ??
        discovery.displayPhotoPath,
    generatedAt: cardGeneratedAt,
    eventThemeId: previousCard?.eventThemeId,
    cardImageUrl: previousCard?.cardImageUrl,
    cardImagePath: previousCard?.cardImagePath,
    aiIllustrationUrl: previousCard?.aiIllustrationUrl,
    aiIllustrationPath: previousCard?.aiIllustrationPath,
    illustratedCatImageUrl: previousCard?.illustratedCatImageUrl,
    illustratedCatImagePath: previousCard?.illustratedCatImagePath,
    cutoutImagePath: cutoutImagePath,
    illustratedCatPath: previousCard?.illustratedCatPath,
    cardTemplateId: previousCard?.cardTemplateId ?? 'common_clean',
    cardVersion: previousCard?.cardVersion ?? 1,
  );

  return CatDiscovery(
    id: discovery.id,
    playerId: discovery.playerId,
    speciesId: discovery.speciesId,
    variantId: discovery.variantId,
    rarity: discovery.rarity,
    personality: discovery.personality,
    traits: discovery.traits,
    discoveredAt: discovery.discoveredAt,
    friendshipPoints: discovery.friendshipPoints,
    customName: discovery.customName,
    suggestedName: discovery.suggestedName,
    city: discovery.city,
    country: discovery.country,
    originalPhotoPath: discovery.originalPhotoPath,
    displayPhotoPath: discovery.displayPhotoPath,
    story: discovery.story,
    funFact: discovery.funFact,
    coatColor: discovery.coatColor,
    coatPattern: discovery.coatPattern,
    eyeColor: discovery.eyeColor,
    hairLength: discovery.hairLength,
    estimatedAge: discovery.estimatedAge,
    xpEarned: discovery.xpEarned,
    coinsEarned: discovery.coinsEarned,
    confidenceScore: discovery.confidenceScore,
    card: card,
    favorite: discovery.favorite,
  );
}

CatDexCollectionEntry entryWithGeneratedCard({
  required CatDexCollectionEntry entry,
  required String cardImagePath,
}) {
  final discovery = entry.discovery;
  if (discovery == null) {
    return entry;
  }

  final nextDiscovery = discoveryWithGeneratedCard(
    discovery: discovery,
    cardImagePath: cardImagePath,
  );

  return CatDexCollectionEntry(
    species: entry.species,
    variantName: entry.variantName,
    variantId: entry.variantId,
    discovered: entry.discovered,
    collectionNumber: entry.collectionNumber,
    discovery: nextDiscovery,
    displayName: entry.displayName,
    discoveredPhotoPath: entry.discoveredPhotoPath,
  );
}
