import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI deployment foundation', () {
    test('deployment docs and scripts exist', () {
      const paths = [
        'docs/AI_DEPLOYMENT.md',
        'scripts/deploy_ai_function.sh',
        'scripts/test_ai_function.sh',
      ];

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test('scripts do not contain committed secrets', () {
      final scriptText = [
        File('scripts/deploy_ai_function.sh').readAsStringSync(),
        File('scripts/test_ai_function.sh').readAsStringSync(),
      ].join('\n');

      expect(scriptText, isNot(contains('sk-')));
      expect(scriptText, isNot(contains('service_role=')));
      expect(scriptText, isNot(contains('OPENAI_API_KEY=')));
    });

    test('Edge Function keeps OpenAI failures safe and debuggable', () {
      final functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();

      expect(functionText, contains('/v1/chat/completions'));
      expect(functionText, contains('response_format'));
      expect(functionText, contains('catdex_cat_visual_inspection'));
      expect(functionText, contains('observationJsonSchema()'));
      expect(functionText, contains('type: "image_url"'));
      expect(functionText, contains(r'Authorization: `Bearer ${openAiKey}`'));
      expect(functionText, contains('openAiFallbackReason'));
      expect(functionText, contains('safeForLog(errorBody'));
      expect(functionText, contains('throw new OpenAiRequestError'));
      expect(functionText, contains('throw new MalformedAiResponseError'));
      expect(functionText, contains('mockReason: safeForLog'));
      expect(
        functionText,
        contains('CATDEX_EDGE_MOCK_ANALYSIS_RETURNED_SAFE_UNKNOWN'),
      );
      expect(functionText, contains('CATDEX_EDGE_MOCK_BROWN_TABBY_DISABLED'));
      expect(functionText, isNot(contains('ai_failed')));
      expect(functionText, isNot(contains('502')));

      final mockFallback = _functionBody(functionText, 'mockAnalysisResult');
      expect(mockFallback, contains('breed: "domestic_cat"'));
      expect(mockFallback, contains('confidence: 0.2'));
      expect(mockFallback, contains('coatColor: "Non rilevato"'));
      expect(mockFallback, contains('coatPattern: "Non rilevato"'));
      expect(mockFallback, contains('needsReview: true'));
      expect(mockFallback, isNot(contains('domestic_tabby_cat')));
      expect(mockFallback, isNot(contains('coatColor: "marrone"')));
      expect(mockFallback, isNot(contains('coatPattern: "tigrato"')));
    });

    test('Edge Function uses observation first and local CatDex rules', () {
      final functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();

      final visualInspectionIndex = functionText.indexOf(
        'const inspection = parseCatVisualInspection(aiJson);',
      );
      final retryIndex = functionText.indexOf(
        'const finalInspection = await visualInspectionWithRetries',
      );
      final observationIndex = functionText.indexOf(
        'const observation = observationFromVisualInspection(finalInspection);',
      );
      final analysisIndex = functionText.indexOf(
        'const analysis = analysisFromObservation(observation, {',
      );
      final analysisBody = _functionBody(
        functionText,
        'analysisFromObservation',
      );
      final classificationIndex = analysisBody.indexOf(
        'const classification = classifyWithRuleEngine(observation, context);',
      );
      final loreIndex = analysisBody.indexOf(
        'const lore = generateLoreWithLoreEngine(observation, classification);',
      );
      final successResponseIndex = functionText.indexOf(
        'return jsonResponse(toResultEnvelope(analysis), 200);',
      );
      final mockFallbackIndex = functionText.indexOf(
        'mockAnalysisResult(openAiFallbackReason(error))',
      );

      expect(visualInspectionIndex, isNonNegative);
      expect(retryIndex, isNonNegative);
      expect(observationIndex, isNonNegative);
      expect(analysisIndex, isNonNegative);
      expect(loreIndex, isNonNegative);
      expect(visualInspectionIndex, lessThan(retryIndex));
      expect(retryIndex, lessThan(observationIndex));
      expect(observationIndex, lessThan(analysisIndex));
      expect(classificationIndex, isNonNegative);
      expect(loreIndex, isNonNegative);
      expect(classificationIndex, lessThan(loreIndex));
      expect(functionText, contains('function parseCatVisualInspection('));
      expect(
        functionText,
        contains('function observationFromVisualInspection('),
      );
      expect(functionText, contains('function analysisFromObservation('));
      expect(functionText, contains('function classifyWithRuleEngine('));
      expect(functionText, contains('breedFromObservationRules('));
      expect(functionText, contains('rarityFromObservationRules('));
      expect(functionText, contains('function generateLoreWithLoreEngine('));
      expect(functionText, contains('storyFromObservation('));
      expect(successResponseIndex, isNonNegative);
      expect(mockFallbackIndex, isNonNegative);
      expect(successResponseIndex, lessThan(mockFallbackIndex));
      expect(functionText, contains('backend: {'));
      expect(functionText, contains('mock: true'));
    });
  });
}

String _functionBody(String source, String functionName) {
  final start = source.indexOf('function $functionName');
  expect(start, isNonNegative, reason: '$functionName should exist');

  final parameterStart = source.indexOf('(', start);
  expect(
    parameterStart,
    isNonNegative,
    reason: '$functionName should have parameters',
  );

  var parameterDepth = 0;
  var signatureEnd = -1;
  for (var index = parameterStart; index < source.length; index++) {
    final char = source[index];
    if (char == '(') {
      parameterDepth++;
    } else if (char == ')') {
      parameterDepth--;
      if (parameterDepth == 0) {
        signatureEnd = index;
        break;
      }
    }
  }
  expect(
    signatureEnd,
    isNonNegative,
    reason: '$functionName signature should end',
  );

  final openBrace = source.indexOf('{', signatureEnd);
  expect(openBrace, isNonNegative, reason: '$functionName should have a body');

  var depth = 0;
  for (var index = openBrace; index < source.length; index++) {
    final char = source[index];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(openBrace, index + 1);
      }
    }
  }

  fail('Could not read $functionName body');
}
