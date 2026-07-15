import { analyzeCatPhoto } from './catAnalysisService';
import { createCatIllustration } from './catIllustrationService';
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
  const performanceTrace = new PipelinePerformanceTrace({
    discoveryId: input.discoveryId,
    idempotencyKey: input.idempotencyKey,
  });
  const totalStartedAt = Date.now();
  try {
    console.log('CATDEX_GENERATE_CARD_STARTED', input.discoveryId);
    console.log('CATDEX_GENERATE_CARD_ORIGINAL_PHOTO_URL', input.photoUrl);
    await saveOriginalPhotoReference(input.discoveryId, input.photoUrl);
    await performanceTrace.measure('IMAGE_DOWNLOAD', 'Download', () =>
      saveImageFromUrl(
        input.discoveryId,
        'original-photo.png',
        input.photoUrl,
        input.publicBaseUrl,
      ),
    );

    const analysisJson = await analyzeCatPhoto(input);
    const analysisPath = await saveAnalysis(input.discoveryId, analysisJson);
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

    const selectedTemplate = await selectTemplate(input.rarity, input.eventKey);

    let illustratedCatUrl: string;
    const illustrationStartedAt = Date.now();
    try {
      console.log('CATDEX_RENDERER_OPENAI_STARTED');
      console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_STARTED');
      illustratedCatUrl = await createCatIllustration({
        discoveryId: input.discoveryId,
        photoUrl: input.photoUrl,
        analysis: analysisJson,
        cardStyle: selectedTemplate.key,
        publicBaseUrl: input.publicBaseUrl,
        performanceTrace,
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
    console.log('CATDEX_CARD_GENERATION_AI_MS', Date.now() - illustrationStartedAt);
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_URL', illustratedCatUrl);

    const starCount = starCountByRarity[input.rarity];
    console.log('CATDEX_STAR_COUNT_SELECTED', starCount);

    const savedIllustration = await saveImageFromUrl(
      input.discoveryId,
      'illustrated-cat.png',
      illustratedCatUrl,
      input.publicBaseUrl,
    );
    const illustrationReference =
      savedIllustration ??
      (await saveIllustrationReference(input.discoveryId, illustratedCatUrl));
    const artworkBuffer = savedIllustration?.data ?? await readImageBuffer(illustratedCatUrl);
    const compositionStartedAt = Date.now();
    console.log('CATDEX_RENDERER_COMPOSITION_STARTED');
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
      () => savePngArtifact(input.discoveryId, 'final-card.png', finalCardBytes),
    );
    console.log('CATDEX_RENDERER_COMPOSITION_COMPLETED');
    console.log('CATDEX_CARD_GENERATION_COMPOSITION_MS', Date.now() - compositionStartedAt);

    const output: GenerateCardOutput = {
      finalCardUrl: publicCardUrl(
        input.discoveryId,
        'final-card.png',
        input.publicBaseUrl,
      ),
      illustratedCatUrl: savedIllustration?.url ?? illustratedCatUrl,
      analysisJson,
      selectedTemplateKey: selectedTemplate.key,
    };
    console.log('CATDEX_GENERATE_CARD_FINAL_URL', output.finalCardUrl);

    const metadata: StoredGeneratedCard = {
      ...output,
      discoveryId: input.discoveryId,
      originalPhotoUrl: input.photoUrl,
      cardText,
      finalCardPath,
      illustratedCatPath: illustrationReference.path,
      analysisPath,
      metadataPath: publicCardUrl(
        input.discoveryId,
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

    console.log('CATDEX_GENERATE_CARD_SUCCESS', true);
    console.log('CATDEX_CARD_GENERATION_TOTAL_MS', Date.now() - totalStartedAt);
    return output;
  } finally {
    performanceTrace.finish();
  }
}
