import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Cards runtime uses external render API output', () {
    final page = File(
      'lib/features/cards/presentation/catdex_trading_card_page.dart',
    ).readAsStringSync();
    final binder = File(
      'lib/features/cards/presentation/cards_binder_page.dart',
    ).readAsStringSync();
    final preview = File(
      'lib/features/cards/presentation/widgets/catdex_card_preview.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/cards/application/card_render_api_service.dart',
    ).readAsStringSync();
    final remoteService = File(
      'lib/features/cards/application/remote_card_generation_service.dart',
    ).readAsStringSync();
    final pipeline = File(
      'lib/features/cards/application/card_generation_pipeline.dart',
    ).readAsStringSync();
    final illustrationService = File(
      'lib/features/cards/application/cat_illustration_service.dart',
    ).readAsStringSync();

    expect(service, contains('class CardRenderApiService'));
    expect(illustrationService, contains('class CatIllustrationService'));
    expect(illustrationService, contains('CAT_ILLUSTRATION_API_URL'));
    expect(
      illustrationService,
      contains('CATDEX_AI_ILLUSTRATION_STARTED'),
    );
    expect(
      illustrationService,
      contains('CATDEX_AI_ILLUSTRATION_ORIGINAL_PHOTO_URL'),
    );
    expect(
      illustrationService,
      contains('CATDEX_AI_ILLUSTRATION_SUCCESS'),
    );
    expect(
      illustrationService,
      contains('createSignedUrl'),
    );
    expect(service, contains('CARD_RENDER_API_URL'));
    expect(service, contains('CATDEX_CARD_RENDER_API_MISSING_URL'));
    expect(service, contains('debugFallbackCatImageUrl'));
    expect(
      service,
      contains('http://localhost:3000/cards/test_illustrated_cat.png'),
    );
    expect(service, contains('CATDEX_CARD_IMAGE_SOURCE_SELECTED'));
    expect(service, contains('CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL'));
    expect(
      service,
      contains('CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL_EMPTY'),
    );
    expect(
      service,
      contains('CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL_VALID'),
    );
    expect(service, contains('CATDEX_CARD_RENDERER external_api'));
    expect(
      service,
      contains('CATDEX_CARD_IMAGE_SOURCE_SELECTED ai_illustration'),
    );
    expect(service, contains('CATDEX_CARD_RENDER_API_STARTED'));
    expect(service, contains('imageUrl'));
    expect(service, contains('pngBase64'));
    expect(service, contains('HttpClient'));
    expect(remoteService, contains('CARD_GENERATION_API_URL'));
    expect(remoteService, contains('CATDEX_REMOTE_GENERATE_CARD_STARTED'));
    expect(remoteService, contains('CATDEX_REMOTE_GENERATE_CARD_FINAL_URL'));
    expect(remoteService, contains('CATDEX_REMOTE_GENERATE_CARD_SUCCESS'));
    expect(pipeline, contains('remoteCardGenerationServiceProvider'));
    expect(pipeline, contains('regenerateCardWithAiIllustration'));
    expect(pipeline, isNot(contains('cardRenderApiServiceProvider')));
    expect(pipeline, isNot(contains('catIllustrationServiceProvider')));
    expect(binder, contains('cardGenerationPipelineProvider'));
    expect(binder, contains('CATDEX_CARD_GENERATION_USER_TAP'));
    expect(binder, contains('CATDEX_CARD_GENERATION_AUTO_START_BLOCKED'));
    expect(binder, isNot(contains('_scheduleAutoGeneration')));
    expect(binder, contains('onRegenerateCard: (entry)'));
    expect(binder, contains('callback: widget.onRegenerateCard'));
    expect(binder, contains('CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED'));
    expect(binder, contains('l10n.generatingIllustration'));
    expect(binder, contains('l10n.generateCard'));
    expect(preview, contains('l10n.regenerateCard'));
    expect(binder, contains('l10n.generateCard'));
    expect(preview, contains('Image.network'));
    expect(preview, contains('Image.file'));
    expect(page, contains('Image.network'));
    expect(page, contains('Image.file'));

    expect(page, isNot(contains('CatDexCardWidget')));
    expect(preview, isNot(contains('CatDexCardWidget')));
    expect(binder, isNot(contains('CardComposerService')));
    expect(binder, isNot(contains('generateCardImage')));
    expect(page, isNot(contains('package:image')));
    expect(preview, isNot(contains('package:image')));
  });
}
