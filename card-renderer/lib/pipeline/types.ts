export type CatRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';

export type CatAnalysisJson = {
  customName: string;
  suggestedName: string;
  displaySpecies: string;
  coatColor: string;
  coatPattern: string;
  eyeColor: string;
  hairLength: string;
  estimatedAge: string;
  personality: string;
  rarity: CatRarity;
  variant: string;
  shortDescription: string;
  story: string;
  funFact: string;
};

export type CardTextJson = {
  cardTitle: string;
  speciesLine: string;
  abilityName: string;
  abilityDescription: string;
  flavorText: string;
  funFact: string;
};

export type TextBlockLayout = {
  enabled?: boolean;
  x: number;
  y: number;
  width: number;
  height: number;
  fontSize: number;
  fontFamily: string;
  color: string;
  shadowColor?: string;
  align: 'left' | 'center' | 'right';
  letterSpacing: number;
};

export type StarsLayout = {
  x: number;
  y: number;
  width: number;
  height: number;
  starSize: number;
  gap: number;
};

export type ArtworkLayout = {
  x: number;
  y: number;
  width: number;
  height: number;
  fit: 'contain' | 'cover';
  anchor: 'center' | 'top' | 'bottom';
  offsetY: number;
};

export type CardTemplateLayout = {
  cardNumber: TextBlockLayout;
  catName: TextBlockLayout;
  stars: StarsLayout;
  species: TextBlockLayout;
  artwork: ArtworkLayout;
};

export type SelectedTemplate = {
  key: string;
  templatePath: string;
  layoutPath: string;
  layout: CardTemplateLayout;
};

export type GenerateCardInput = {
  discoveryId: string;
  idempotencyKey?: string;
  photoUrl: string;
  rarity: CatRarity;
  publicBaseUrl?: string;
  eventKey?: string;
  eventEdition?: string;
  eventArtworkVariantId?: string;
  eventArtworkTier?: 'free' | 'premium';
  eventTemplateKey?: string;
  eventInstructionKey?: string;
  eventGenerationRequestId?: string;
  isEventCard?: boolean;
  eventArtworkInstructions?: readonly string[];
  eventArtworkNegativeConstraints?: readonly string[];
  artifactStorageId?: string;
  displayName?: string;
  displaySpecies?: string;
  displayCoatColor?: string;
  displayCoatPattern?: string;
  displayEyeColor?: string;
  displayHairLength?: string;
  displayPersonality?: string;
  displayRarity?: string;
  displayStory?: string;
  displayFunFact?: string;
};

export type GenerateCardOutput = {
  finalCardUrl: string;
  illustratedCatUrl: string;
  analysisJson: CatAnalysisJson;
  selectedTemplateKey: string;
  templateKey?: string;
  eventKey?: string;
  eventEdition?: string;
  eventArtworkVariantId?: string;
  eventArtworkTier?: 'free' | 'premium';
  eventTemplateKey?: string;
  isEventCard?: boolean;
  generationStatus?: 'completed';
  transformationValidation?: 'passed' | 'uncertain' | 'failed';
};

export type StoredGeneratedCard = GenerateCardOutput & {
  discoveryId: string;
  originalPhotoUrl: string;
  cardText: CardTextJson;
  finalCardPath: string;
  illustratedCatPath: string;
  analysisPath: string;
  metadataPath: string;
  createdAt: string;
  artifactStorageId?: string;
};
