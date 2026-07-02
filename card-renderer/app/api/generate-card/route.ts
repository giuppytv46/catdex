import type { NextRequest } from 'next/server';
import { generateCatDexCard } from '../../../lib/pipeline/cardPipeline';
import type { CatRarity, GenerateCardInput } from '../../../lib/pipeline/types';

export const runtime = 'nodejs';

const rarities: CatRarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

function isRarity(value: unknown): value is CatRarity {
  return typeof value === 'string' && rarities.includes(value as CatRarity);
}

function cleanRequiredString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

function cleanOptionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

export async function POST(request: NextRequest) {
  let body: Partial<GenerateCardInput>;

  try {
    body = (await request.json()) as Partial<GenerateCardInput>;
  } catch {
    return Response.json({ error: 'Invalid JSON body.' }, { status: 400 });
  }

  const discoveryId = cleanRequiredString(body.discoveryId);
  const photoUrl = cleanRequiredString(body.photoUrl);
  const rarity = body.rarity;
  const displayName = cleanOptionalString(body.displayName);
  const displaySpecies = cleanOptionalString(body.displaySpecies);
  const displayCoatColor = cleanOptionalString(body.displayCoatColor);
  const displayCoatPattern = cleanOptionalString(body.displayCoatPattern);

  if (!discoveryId || !photoUrl || !isRarity(rarity)) {
    return Response.json(
      {
        error: 'Missing or invalid input. Required: discoveryId, photoUrl, rarity.',
        allowedRarities: rarities,
      },
      { status: 400 },
    );
  }

  try {
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_NAME', displayName ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_SPECIES', displaySpecies ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_COAT', displayCoatColor ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_PATTERN', displayCoatPattern ?? '-');

    const result = await generateCatDexCard({
      discoveryId,
      photoUrl,
      rarity,
      eventKey: cleanRequiredString(body.eventKey),
      displayName,
      displaySpecies,
      displayCoatColor,
      displayCoatPattern,
      displayEyeColor: cleanOptionalString(body.displayEyeColor),
      displayHairLength: cleanOptionalString(body.displayHairLength),
      displayPersonality: cleanOptionalString(body.displayPersonality),
      displayRarity: cleanOptionalString(body.displayRarity),
      displayStory: cleanOptionalString(body.displayStory),
      displayFunFact: cleanOptionalString(body.displayFunFact),
    });

    return Response.json(result);
  } catch (error) {
    console.error('CATDEX_GENERATE_CARD_ERROR', error);
    console.log('CATDEX_GENERATE_CARD_SUCCESS', false);
    return Response.json({ error: 'Failed to generate CatDex card.' }, { status: 500 });
  }
}
