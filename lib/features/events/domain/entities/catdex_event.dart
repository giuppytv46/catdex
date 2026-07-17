import 'package:flutter/foundation.dart';

@immutable
class CatDexEvent {
  const CatDexEvent({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.standardVariantId,
    required this.premiumVariantId,
    required this.premiumGenerationLimit,
    this.edition = '1',
    this.standardVariantIds = const <String>[],
    this.premiumVariantIds = const <String>[],
    this.variantTemplateKeys = const <String, String>{},
    this.variantInstructionKeys = const <String, String>{},
    this.variantWeights = const <String, int>{},
    this.variantSortOrders = const <String, int>{},
    this.variantTransformsCatAppearance = const <String, bool>{},
    this.disabledVariantIds = const <String>[],
    this.premiumGuaranteedOnce = true,
    this.consumesNormalCardCredit = false,
    this.freeGenerationLimit = 3,
    this.metadata = const <String, Object?>{},
  });

  factory CatDexEvent.fromJson(Map<String, Object?> json) {
    return CatDexEvent(
      id: json['id']! as String,
      startsAt: DateTime.parse(json['startsAt']! as String),
      endsAt: DateTime.parse(json['endsAt']! as String),
      standardVariantId: json['standardVariantId']! as String,
      premiumVariantId: json['premiumVariantId']! as String,
      edition: json['edition'] as String? ?? '1',
      standardVariantIds:
          (json['standardVariantIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      premiumVariantIds:
          (json['premiumVariantIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      variantTemplateKeys: _stringMap(json['variantTemplateKeys']),
      variantInstructionKeys: _stringMap(json['variantInstructionKeys']),
      variantWeights: _intMap(json['variantWeights']),
      variantSortOrders: _intMap(json['variantSortOrders']),
      variantTransformsCatAppearance: _boolMap(
        json['variantTransformsCatAppearance'],
      ),
      disabledVariantIds:
          (json['disabledVariantIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      premiumGuaranteedOnce: json['premiumGuaranteedOnce'] as bool? ?? true,
      consumesNormalCardCredit:
          json['consumesNormalCardCredit'] as bool? ?? false,
      freeGenerationLimit: json['freeGenerationLimit'] as int? ?? 3,
      premiumGenerationLimit: json['premiumGenerationLimit']! as int,
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map<Object?, Object?>? ?? const {},
      ),
    );
  }

  final String id;
  final String edition;
  final DateTime startsAt;
  final DateTime endsAt;
  final String standardVariantId;
  final List<String> standardVariantIds;
  final String premiumVariantId;
  final List<String> premiumVariantIds;
  final Map<String, String> variantTemplateKeys;
  final Map<String, String> variantInstructionKeys;
  final Map<String, int> variantWeights;
  final Map<String, int> variantSortOrders;
  final Map<String, bool> variantTransformsCatAppearance;
  final List<String> disabledVariantIds;
  final bool premiumGuaranteedOnce;
  final bool consumesNormalCardCredit;
  final int freeGenerationLimit;
  final int premiumGenerationLimit;
  final Map<String, Object?> metadata;

  bool isActiveAt(DateTime now) {
    return !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  List<String> get enabledStandardVariantIds => standardVariantIds.isEmpty
      ? isVariantEnabled(standardVariantId)
            ? <String>[standardVariantId]
            : const <String>[]
      : List<String>.unmodifiable(
          standardVariantIds.where(isVariantEnabled),
        );

  List<String> get allPremiumVariantIds {
    final variants = <String>{premiumVariantId, ...premiumVariantIds}.toList()
      ..sort(
        (left, right) => (variantSortOrders[left] ?? 0).compareTo(
          variantSortOrders[right] ?? 0,
        ),
      );
    return List<String>.unmodifiable(variants);
  }

  List<String> get enabledPremiumVariantIds => List<String>.unmodifiable(
    allPremiumVariantIds.where(isVariantEnabled),
  );

  List<String> get allVariantIds => List<String>.unmodifiable({
    ...standardVariantIds,
    standardVariantId,
    ...allPremiumVariantIds,
  });

  bool containsVariant(String variantId) => allVariantIds.contains(variantId);

  bool isVariantEnabled(String variantId) =>
      containsVariant(variantId) && !disabledVariantIds.contains(variantId);

  bool isPremiumVariant(String variantId) =>
      allPremiumVariantIds.contains(variantId);

  bool transformsCatAppearance(String variantId) =>
      variantTransformsCatAppearance[variantId] ?? false;

  String templateKeyFor(String variantId) =>
      variantTemplateKeys[variantId] ?? variantId;

  String instructionKeyFor(String variantId) =>
      variantInstructionKeys[variantId] ?? variantId;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'edition': edition,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'standardVariantId': standardVariantId,
      'standardVariantIds': standardVariantIds,
      'premiumVariantId': premiumVariantId,
      'premiumVariantIds': premiumVariantIds,
      'variantTemplateKeys': variantTemplateKeys,
      'variantInstructionKeys': variantInstructionKeys,
      'variantWeights': variantWeights,
      'variantSortOrders': variantSortOrders,
      'variantTransformsCatAppearance': variantTransformsCatAppearance,
      'disabledVariantIds': disabledVariantIds,
      'premiumGuaranteedOnce': premiumGuaranteedOnce,
      'consumesNormalCardCredit': consumesNormalCardCredit,
      'freeGenerationLimit': freeGenerationLimit,
      'premiumGenerationLimit': premiumGenerationLimit,
      'metadata': metadata,
    };
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const <String, String>{};
  return Map<String, String>.fromEntries(
    value.entries
        .where((entry) => entry.key is String && entry.value is String)
        .map(
          (entry) => MapEntry(entry.key as String, entry.value as String),
        ),
  );
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const <String, int>{};
  return Map<String, int>.fromEntries(
    value.entries
        .where((entry) => entry.key is String && entry.value is num)
        .map(
          (entry) =>
              MapEntry(entry.key as String, (entry.value as num).toInt()),
        ),
  );
}

Map<String, bool> _boolMap(Object? value) {
  if (value is! Map) return const <String, bool>{};
  return Map<String, bool>.fromEntries(
    value.entries
        .where((entry) => entry.key is String && entry.value is bool)
        .map(
          (entry) => MapEntry(entry.key as String, entry.value as bool),
        ),
  );
}
