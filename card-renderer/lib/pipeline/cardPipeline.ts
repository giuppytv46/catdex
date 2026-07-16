import { analyzeCatPhoto } from './catAnalysisService';
import { createCatIllustration } from './catIllustrationService';
import {
  EventArtworkValidationError,
  validateEventArtwork,
  validateFinalCard,
} from './eventArtworkValidation';
import { createCardText, fallbackCardText } from './cardTextService';
import { PipelinePerformanceTrace } from './performanceInstrumentation';
import { renderProgrammaticCard } from './programmaticCardRenderer';
import {
  publicCardUrl,
  readImageBuffer,
  saveAnalysis,
  saveImageFromUrl,
  saveIllustrationReference,
  saveMetadata,
  saveOriginalPhotoReference,
  savePngArtifact,
} from './storage';
import { selectTemplate } from './templateSelection';
import type { CardTextJson, GenerateCardInput, GenerateCardOutput, StoredGeneratedCard } from './types';

const starCountByRarity = {
  common: 1,
  uncommon: 2,
  rare: 3,
  epic: 4,
  legendary: 5,
};

export class AIIllustrationFailedError extends Error {
  constructor(message = 'AI illustration generation failed. Card was not generated.') {
    super(message);
    this.name = 'AIIllustrationFailedError';
  }
}

function cardNumberFromDiscovery(discoveryId: string): string {
  const numeric = discoveryId.replace(/\D/g, '').slice(-4).padStart(4, '0');
  return `#${numeric || '0000'}`;
}

function isBillingOrLimitError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error);
  const normalized = message.toLowerCase();
  return (
    normalized.includes('billing') ||
    normalized.includes('quota') ||
    normalized.includes('hard limit') ||
    normalized.includes('insufficient_quota') ||
    normalized.includes('insufficient quota') ||
    normalized.includes('rate limit') ||
    normalized.includes('rate_limit')
  );
}

export async function generateCatDexCard(input: GenerateCardInput): Promise<GenerateCardOutput> {
  const storageId = input.artifactStorageId ?? input.discoveryId;
  const performanceTrace = new PipelinePerformanceTrace({
    discoveryId: input.discoveryId,
    idempotencyKey: input.idempotencyKey,
  });
  const totalStartedAt = Date.now();
  try {
    console.log('CATDEX_GENERATE_CARD_STARTED', input.discoveryId);
    console.log(
      'CATDEX_GENERATE_CARD_ORIGINAL_PHOTO_URL',
      input.isEventCard ? '[redacted_event_photo_url]' : input.photoUrl,
    );
    await saveOriginalPhotoReference(storageId, input.photoUrl);
    await performanceTrace.measure('IMAGE_DOWNLOAD', 'Download', () =>
      saveImageFromUrl(
        storageId,
        'original-photo.png',
        input.photoUrl,
        input.publicBaseUrl,
      ),
    );

    const analysisJson = await analyzeCatPhoto(input);
    const analysisPath = await saveAnalysis(storageId, analysisJson);
    const textSource = input.displayName || input.displaySpecies ? 'flutter_display_data' : 'fallback';

    let cardText: CardTextJson;
    try {
      cardText = await createCardText(analysisJson);
    } catch {
      cardText = fallbackCardText(analysisJson);
    }
  console.log('CATDEX_GENERATE_CARD_TEXT_SOURCE', textSource);
  console.log('CATDEX_GENERATE_CARD_TEXT_NAME', cardText.cardTitle);
  console.log('CATDEX_GENERATE_CARD_TEXT_SPECIES', cardText.speciesLine);

    const selectedTemplate = await selectTemplate(
      input.rarity,
      input.eventKey,
      input.eventTemplateKey,
    );

    let illustratedCatUrl: string;
    const illustrationStartedAt = Date.now();
    try {
      console.log('CATDEX_RENDERER_OPENAI_STARTED');
      console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_STARTED');
      if (input.isEventCard) console.log('CATDEX_RENDER_EVENT_OPENAI_STARTED');
      illustratedCatUrl = await createCatIllustration({
        discoveryId: storageId,
        photoUrl: input.photoUrl,
        analysis: analysisJson,
        cardStyle: selectedTemplate.key,
        publicBaseUrl: input.publicBaseUrl,
        performanceTrace,
        eventArtworkInstructions: input.eventArtworkInstructions,
        eventArtworkNegativeConstraints:
          input.eventArtworkNegativeConstraints,
      });
    } catch (error) {
    console.log(
      'CATDEX_GENERATE_CARD_ILLUSTRATION_ERROR',
      error instanceof Error ? error.message : String(error),
    );
    if (isBillingOrLimitError(error)) {
      console.log('CATDEX_GENERATE_CARD_OPENAI_BILLING_OR_LIMIT_ERROR');
    }
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_FAILED_NO_FALLBACK');
    console.log('CATDEX_GENERATE_CARD_ABORTED_AI_ILLUSTRATION_FAILED');
    console.log('CATDEX_GENERATE_CARD_FINAL_CARD_NOT_CREATED');
    console.log('CATDEX_GENERATE_CARD_SUCCESS', false);
      throw new AIIllustrationFailedError();
    }
    console.log('CATDEX_RENDERER_OPENAI_COMPLETED');
    if (input.isEventCard) console.log('CATDEX_RENDER_EVENT_OPENAI_COMPLETED');
    console.log('CATDEX_CARD_GENERATION_AI_MS', Date.now() - illustrationStartedAt);
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_URL', illustratedCatUrl);

    const starCount = starCountByRarity[input.rarity];
    console.log('CATDEX_STAR_COUNT_SELECTED', starCount);

    const savedIllustration = await saveImageFromUrl(
      storageId,
      'illustrated-cat.png',
      illustratedCatUrl,
      input.publicBaseUrl,
    );
    const illustrationReference =
      savedIllustration ??
      (await saveIllustrationReference(storageId, illustratedCatUrl));
    const artworkBuffer = savedIllustration?.data ?? await readImageBuffer(illustratedCatUrl);
    let transformationValidation: 'passed' | 'uncertain' | 'failed' | undefined;
    if (input.isEventCard) {
      const validation = await validateEventArtwork(
        artworkBuffer,
        input.eventArtworkTier === 'premium',
      );
      transformationValidation = validation.transformation;
      console.log(
        'CATDEX_RENDER_EVENT_VALIDATION_RESULT',
        `technical=${validation.technical}`,
        `transformation=${validation.transformation}`,
      );
      if (validation.technical === 'failed') {
        throw new EventArtworkValidationError();
      }
    }
    const compositionStartedAt = Date.now();
    console.log('CATDEX_RENDERER_COMPOSITION_STARTED');
    if (input.isEventCard) console.log('CATDEX_RENDER_EVENT_COMPOSITION_STARTED');
    const finalCardBytes = await performanceTrace.measure(
      'CARD_COMPOSITION',
      'Composition',
      async () => {
        return renderProgrammaticCard({
          templateKey: selectedTemplate.key,
          templatePath: selectedTemplate.templatePath,
          layout: selectedTemplate.layout,
          artworkBuffer,
          cardNumber: cardNumberFromDiscovery(input.discoveryId),
          starCount,
          text: cardText,
        });
      },
    );
    const finalCardPath = await performanceTrace.measure(
      'UPLOAD_FINAL_ARTWORK',
      'Upload',
      () => savePngArtifact(storageId, 'final-card.png', finalCardBytes),
    );
    console.log('CATDEX_RENDERER_COMPOSITION_COMPLETED');
    if (input.isEventCard) console.log('CATDEX_RENDER_EVENT_COMPOSITION_COMPLETED');
    console.log('CATDEX_CARD_GENERATION_COMPOSITION_MS', Date.now() - compositionStartedAt);
    if (input.isEventCard) {
      if (!(await validateFinalCard(finalCardBytes, finalCardPath))) {
        throw new EventArtworkValidationError();
      }
      console.log('CATDEX_RENDER_EVENT_UPLOAD_COMPLETED');
    }

    const output: GenerateCardOutput = {
      finalCardUrl: publicCardUrl(
        storageId,
        'final-card.png',
        input.publicBaseUrl,
      ),
      illustratedCatUrl: savedIllustration?.url ?? illustratedCatUrl,
      analysisJson,
      selectedTemplateKey: selectedTemplate.key,
      ...(input.isEventCard
        ? {
            templateKey: input.eventTemplateKey,
            eventKey: input.eventKey,
            eventEdition: input.eventEdition,
            eventArtworkVariantId: input.eventArtworkVariantId,
            eventArtworkTier: input.eventArtworkTier,
            eventTemplateKey: input.eventTemplateKey,
            isEventCard: true,
            generationStatus: 'completed' as const,
            transformationValidation,
          }
        : {}),
    };
    console.log('CATDEX_GENERATE_CARD_FINAL_URL', output.finalCardUrl);

    const metadata: StoredGeneratedCard = {
      ...output,
      discoveryId: storageId,
      artifactStorageId: storageId,
      originalPhotoUrl: input.photoUrl,
      cardText,
      finalCardPath,
      illustratedCatPath: illustrationReference.path,
      analysisPath,
      metadataPath: publicCardUrl(
        storageId,
        'metadata.json',
        input.publicBaseUrl,
      ),
      createdAt: new Date().toISOString(),
    };
    const metadataPath = await performanceTrace.measure(
      'SAVE_METADATA',
      'Persistence',
      () => saveMetadata(metadata),
    );
    void metadataPath;
    if (input.isEventCard) console.log('CATDEX_RENDER_EVENT_SUCCESS');

    console.log('CATDEX_GENERATE_CARD_SUCCESS', true);
    console.log('CATDEX_CARD_GENERATION_TOTAL_MS', Date.now() - totalStartedAt);
    return output;
  } catch (error) {
    if (input.isEventCard) {
      console.log(
        'CATDEX_RENDER_EVENT_FAILURE',
        `reason=${error instanceof EventArtworkValidationError ? 'eventArtworkValidationFailed' : 'generation_failed'}`,
      );
    }
    throw error;
  } finally {
    performanceTrace.finish();
  }
}
