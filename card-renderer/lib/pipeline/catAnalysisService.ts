import type { CatAnalysisJson, GenerateCardInput } from './types';

export async function analyzeCatPhoto(input: GenerateCardInput): Promise<CatAnalysisJson> {
  const fallbackName = `CAT-${input.discoveryId.slice(-4).toUpperCase() || '0001'}`;
  const displayName = input.displayName?.trim();
  const displaySpecies = input.displaySpecies?.trim();
  const coatColor = input.displayCoatColor?.trim();
  const coatPattern = input.displayCoatPattern?.trim();
  const eyeColor = input.displayEyeColor?.trim();
  const hairLength = input.displayHairLength?.trim();
  const personality = input.displayPersonality?.trim();
  const story = input.displayStory?.trim();
  const funFact = input.displayFunFact?.trim();

  return {
    customName: displayName ?? '',
    suggestedName: displayName ?? fallbackName,
    displaySpecies: displaySpecies ?? 'Gatto domestico',
    coatColor: coatColor ?? 'unknown',
    coatPattern: coatPattern ?? 'unknown',
    eyeColor: eyeColor ?? 'unknown',
    hairLength: hairLength ?? 'unknown',
    estimatedAge: 'unknown',
    personality: personality ?? 'curious',
    rarity: input.rarity,
    variant: 'standard',
    shortDescription: 'A newly discovered CatDex companion.',
    story: story ?? 'This cat joined the CatDex from a captured photo and awaits a richer AI analysis.',
    funFact: funFact ?? 'Every CatDex card is composed with deterministic layout slots.',
  };
}
