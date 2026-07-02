import { analyzeCatPhoto } from './catAnalysisService';
import { createCatIllustration, fallbackCatIllustration } from './catIllustrationService';
import { createCardText, fallbackCardText } from './cardTextService';
import { renderProgrammaticCard } from './programmaticCardRenderer';
import {
  fileToDataUrl,
  publicCardUrl,
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

function cardNumberFromDiscovery(discoveryId: string): string {
  const numeric = discoveryId.replace(/\D/g, '').slice(-4).padStart(4, '0');
  return `#${numeric || '0000'}`;
}

export async function generateCatDexCard(input: GenerateCardInput): Promise<GenerateCardOutput> {
  console.log('CATDEX_GENERATE_CARD_STARTED', input.discoveryId);
  console.log('CATDEX_GENERATE_CARD_ORIGINAL_PHOTO_URL', input.photoUrl);
  await saveOriginalPhotoReference(input.discoveryId, input.photoUrl);
  await saveImageFromUrl(input.discoveryId, 'original-photo.png', input.photoUrl);

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
  try {
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_STARTED');
    illustratedCatUrl = await createCatIllustration({
      discoveryId: input.discoveryId,
      photoUrl: input.photoUrl,
      analysis: analysisJson,
      cardStyle: selectedTemplate.key,
    });
  } catch (error) {
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_SOURCE', 'original_photo_fallback');
    console.log(
      'CATDEX_GENERATE_CARD_ILLUSTRATION_ERROR',
      error instanceof Error ? error.message : String(error),
    );
    illustratedCatUrl = fallbackCatIllustration(input.photoUrl);
  }
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_URL', illustratedCatUrl);

  const savedIllustration = await saveImageFromUrl(input.discoveryId, 'illustrated-cat.png', illustratedCatUrl);
  const illustrationReference = savedIllustration ?? (await saveIllustrationReference(input.discoveryId, illustratedCatUrl));
  const artworkImageUrl = savedIllustration
    ? await fileToDataUrl(savedIllustration.path, savedIllustration.contentType)
    : illustratedCatUrl;
  const cardImageResponse = await renderProgrammaticCard({
    templatePath: selectedTemplate.templatePath,
    layout: selectedTemplate.layout,
    artworkImageUrl,
    cardNumber: cardNumberFromDiscovery(input.discoveryId),
    starCount: starCountByRarity[input.rarity],
    text: cardText,
  });
  const finalCardPath = await savePngArtifact(input.discoveryId, 'final-card.png', await cardImageResponse.arrayBuffer());

  const output: GenerateCardOutput = {
    finalCardUrl: publicCardUrl(input.discoveryId, 'final-card.png'),
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
    metadataPath: publicCardUrl(input.discoveryId, 'metadata.json'),
    createdAt: new Date().toISOString(),
  };
  const metadataPath = await saveMetadata(metadata);
  void metadataPath;

  console.log('CATDEX_GENERATE_CARD_SUCCESS', true);
  return output;
}
