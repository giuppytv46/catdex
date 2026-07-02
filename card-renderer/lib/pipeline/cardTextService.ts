import type { CardTextJson, CatAnalysisJson } from './types';

export async function createCardText(analysis: CatAnalysisJson): Promise<CardTextJson> {
  const cardTitle = (analysis.customName || analysis.suggestedName || 'UNKNOWN').toUpperCase();

  return {
    cardTitle,
    speciesLine: analysis.displaySpecies || 'Gatto domestico',
    abilityName: `${analysis.personality || 'Curious'} Instinct`,
    abilityDescription: analysis.shortDescription || 'A faithful CatDex companion.',
    flavorText: analysis.story || analysis.shortDescription || 'A mysterious feline presence.',
    funFact: analysis.funFact || 'Cats can recognize familiar human voices.',
  };
}

export function fallbackCardText(analysis: CatAnalysisJson): CardTextJson {
  return {
    cardTitle: (analysis.customName || analysis.suggestedName || 'UNKNOWN').toUpperCase(),
    speciesLine: analysis.displaySpecies || 'Gatto domestico',
    abilityName: 'CatDex Instinct',
    abilityDescription: analysis.shortDescription || 'A faithful CatDex companion.',
    flavorText: analysis.story || '',
    funFact: analysis.funFact || '',
  };
}
