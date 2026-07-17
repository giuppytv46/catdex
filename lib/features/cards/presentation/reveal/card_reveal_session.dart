import 'dart:io';
import 'dart:math' as math;

import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter/material.dart';

enum CardRevealSessionType { normal, event, premiumEvent }

@immutable
class CardRevealSession {
  const CardRevealSession({
    required this.sessionId,
    required this.cardId,
    required this.discoveryId,
    required this.cardType,
    required this.rarity,
    required this.localizedRarityLabel,
    required this.finalImageProvider,
    required this.finalImageUrl,
    required this.decodeWidth,
    required this.decodeHeight,
    this.eventKey,
    this.eventVariant,
    this.xpResult = 0,
    this.missionResults = const <String>[],
    this.previousLevel,
    this.updatedLevel,
    this.rewardCue,
  });

  factory CardRevealSession.fromRecord({
    required CatCardRecord card,
    required String localizedRarityLabel,
    required MediaQueryData mediaQuery,
    CardRevealRewardCue? rewardCue,
  }) {
    assert(card.isCompleted, 'A reveal requires a persisted completed card.');
    final target = cardRevealDecodeTarget(mediaQuery);
    final stableImageSource = stableCardRevealSource(
      card.finalCardUrl,
      version: card.updatedAt.millisecondsSinceEpoch,
    );
    final provider = stableCardRevealImageProvider(
      stableImageSource,
      targetWidth: target.width,
      targetHeight: target.height,
    );
    final revision = card.updatedAt.microsecondsSinceEpoch.toRadixString(36);
    final session = CardRevealSession(
      sessionId: '${card.cardId}:$revision',
      cardId: card.cardId,
      discoveryId: card.discoveryId,
      cardType: card.cardType == CatCardType.normal
          ? CardRevealSessionType.normal
          : card.isPremiumArtwork
          ? CardRevealSessionType.premiumEvent
          : CardRevealSessionType.event,
      eventKey: card.eventKey,
      eventVariant: card.eventArtworkVariantId,
      rarity: card.rarity,
      localizedRarityLabel: localizedRarityLabel,
      finalImageProvider: provider,
      finalImageUrl: stableImageSource,
      decodeWidth: target.width,
      decodeHeight: target.height,
      xpResult: rewardCue?.earnedXp ?? 0,
      missionResults: rewardCue?.missionCompleted == true
          ? const <String>['daily_mission_completed']
          : const <String>[],
      previousLevel: rewardCue?.newLevel == null
          ? null
          : math.max(1, rewardCue!.newLevel! - 1),
      updatedLevel: rewardCue?.newLevel,
      rewardCue: rewardCue,
    );
    final safeCardId = _safeIdentifier(card.cardId);
    debugPrint('CATDEX_CARD_REVEAL_SESSION_CREATED cardId=$safeCardId');
    debugPrint(
      'CATDEX_CELEBRATION_IMAGE_DECODE_TARGET '
      'width=${target.width} height=${target.height}',
    );
    return session;
  }

  final String sessionId;
  final String cardId;
  final String discoveryId;
  final CardRevealSessionType cardType;
  final String? eventKey;
  final String? eventVariant;
  final CatRarity rarity;
  final String localizedRarityLabel;
  final ImageProvider<Object> finalImageProvider;
  final String finalImageUrl;
  final int decodeWidth;
  final int decodeHeight;
  final int xpResult;
  final List<String> missionResults;
  final int? previousLevel;
  final int? updatedLevel;
  final CardRevealRewardCue? rewardCue;
}

@immutable
class CardRevealDecodeTarget {
  const CardRevealDecodeTarget({required this.width, required this.height});

  final int width;
  final int height;
}

CardRevealDecodeTarget cardRevealDecodeTarget(MediaQueryData mediaQuery) {
  final logicalWidth = math.min(420, math.max(220, mediaQuery.size.width - 48));
  final physicalWidth = (logicalWidth * mediaQuery.devicePixelRatio)
      .round()
      .clamp(440, 1500);
  final physicalHeight = (physicalWidth * 2100 / 1500).round();
  return CardRevealDecodeTarget(
    width: physicalWidth,
    height: physicalHeight,
  );
}

ImageProvider<Object> stableCardRevealImageProvider(
  String source, {
  required int targetWidth,
  required int targetHeight,
}) {
  final ImageProvider<Object> base;
  if (isNetworkCardImageUrl(source)) {
    base = NetworkImage(source);
  } else {
    base = FileImage(File(source));
  }
  return ResizeImage.resizeIfNeeded(
    targetWidth,
    targetHeight,
    base,
  );
}

String stableCardRevealSource(String source, {required int version}) {
  if (!isNetworkCardImageUrl(source)) return source;
  final uri = Uri.parse(source);
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'v': version.toString(),
        },
      )
      .toString();
}

String _safeIdentifier(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 80) return trimmed;
  return '${trimmed.substring(0, 77)}...';
}
