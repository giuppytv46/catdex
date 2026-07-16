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
    this.variantTemplateKeys = const <String, String>{},
    this.variantInstructionKeys = const <String, String>{},
    this.variantWeights = const <String, int>{},
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
      variantTemplateKeys: _stringMap(json['variantTemplateKeys']),
      variantInstructionKeys: _stringMap(json['variantInstructionKeys']),
      variantWeights: _intMap(json['variantWeights']),
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
  final Map<String, String> variantTemplateKeys;
  final Map<String, String> variantInstructionKeys;
  final Map<String, int> variantWeights;
  final bool premiumGuaranteedOnce;
  final bool consumesNormalCardCredit;
  final int freeGenerationLimit;
  final int premiumGenerationLimit;
  final Map<String, Object?> metadata;

  bool isActiveAt(DateTime now) {
    return !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  List<String> get enabledStandardVariantIds => standardVariantIds.isEmpty
      ? <String>[standardVariantId]
      : List<String>.unmodifiable(standardVariantIds);

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
      'variantTemplateKeys': variantTemplateKeys,
      'variantInstructionKeys': variantInstructionKeys,
      'variantWeights': variantWeights,
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
