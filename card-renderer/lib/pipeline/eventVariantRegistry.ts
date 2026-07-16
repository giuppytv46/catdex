import {
  isEventPremiumTestModeEnabled,
  isEventTestModeEnabled,
} from './config';

export type EventArtworkTier = 'free' | 'premium';

export type EventVariantDefinition = {
  eventKey: string;
  eventEdition: string;
  variantId: string;
  tier: EventArtworkTier;
  templateKey: string;
  instructionKey: string;
  enabled: boolean;
  startsAt: string;
  endsAt: string;
  artworkInstructions: readonly string[];
  negativeConstraints: readonly string[];
  compositionSettings: {
    preserveMetadataRegions: true;
    background: 'composition-safe' | 'transparent';
  };
  transformsCatAppearance: boolean;
};

export type EventRequestIdentifiers = {
  eventKey?: string;
  eventEdition?: string;
  eventArtworkVariantId?: string;
  eventArtworkTier?: EventArtworkTier;
  eventTemplateKey?: string;
  eventInstructionKey?: string;
  eventGenerationRequestId?: string;
  isEventCard?: boolean;
};

export function containsForbiddenArtworkFields(
  body: Record<string, unknown>,
): boolean {
  return (
    body.prompt !== undefined ||
    body.eventPrompt !== undefined ||
    body.artworkInstructions !== undefined
  );
}

export class EventRequestError extends Error {
  constructor(
    public readonly code:
      | 'eventInactive'
      | 'eventVariantInvalid'
      | 'eventVariantDisabled'
      | 'premiumRequired'
      | 'premiumVerificationUnavailable'
      | 'eventReservationConflict',
    message: string,
    public readonly status: number,
  ) {
    super(message);
    this.name = 'EventRequestError';
  }
}

const commonNegativeConstraints = [
  'multiple cats',
  'duplicated face',
  'malformed paws',
  'extra limbs',
  'second tail',
  'human body',
  'changed coat pattern',
  'changed breed',
  'text, letters, watermark, logo',
] as const;

const preserveCat = [
  'Preserve the individual cat faithfully and keep it recognizably the same cat.',
  'Preserve coat color, markings, face shape, eye color when visible, ear shape and body proportions.',
  'Render one cat only with no text and a composition-safe or transparent background.',
] as const;

export const eventVariantRegistry: Readonly<
  Record<string, Readonly<Record<string, EventVariantDefinition>>>
> = {
  halloween_2026: {
    halloween_pumpkins: variant({
      variantId: 'halloween_pumpkins',
      tier: 'free',
      templateKey: 'halloween_pumpkins',
      instructionKey: 'halloween_pumpkins',
      instructions: [
        ...preserveCat,
        'Create a cute premium Halloween illustration with pumpkins, autumn leaves and warm orange magical light.',
        'Do not put a costume on the cat.',
      ],
    }),
    halloween_moonlight: variant({
      variantId: 'halloween_moonlight',
      tier: 'free',
      templateKey: 'halloween_moonlight',
      instructionKey: 'halloween_moonlight',
      instructions: [
        ...preserveCat,
        'Create a moonlit Halloween atmosphere with a full moon, subtle bats and blue-purple light.',
        'Do not put a costume on the cat.',
      ],
    }),
    halloween_haunted_frame: variant({
      variantId: 'halloween_haunted_frame',
      tier: 'free',
      templateKey: 'halloween_haunted_frame',
      instructionKey: 'halloween_haunted_frame',
      instructions: [
        ...preserveCat,
        'Create an elegant haunted-house atmosphere with light fog and subtle spooky details.',
        'No horror, gore or costume on the cat.',
      ],
    }),
    halloween_witch_cat: variant({
      variantId: 'halloween_witch_cat',
      tier: 'premium',
      templateKey: 'halloween_witch_cat_premium',
      instructionKey: 'halloween_witch_hat',
      transformsCatAppearance: true,
      instructions: [
        ...preserveCat,
        'Add a small elegant witch hat fitted naturally to the cat head without covering the eyes or face; keep the ears readable where possible.',
        'An optional short magical cape is allowed.',
        'Use premium fantasy Halloween lighting with purple, gold and orange accents.',
      ],
      extraNegative: ['oversized hat', 'hat covering the face'],
    }),
  },
};

function variant(input: {
  variantId: string;
  tier: EventArtworkTier;
  templateKey: string;
  instructionKey: string;
  instructions: readonly string[];
  transformsCatAppearance?: boolean;
  extraNegative?: readonly string[];
}): EventVariantDefinition {
  return {
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    variantId: input.variantId,
    tier: input.tier,
    templateKey: input.templateKey,
    instructionKey: input.instructionKey,
    enabled: true,
    startsAt: '2026-10-01T00:00:00.000Z',
    endsAt: '2026-11-04T00:00:00.000Z',
    artworkInstructions: input.instructions,
    negativeConstraints: [
      ...commonNegativeConstraints,
      ...(input.extraNegative ?? []),
    ],
    compositionSettings: {
      preserveMetadataRegions: true,
      background: 'composition-safe',
    },
    transformsCatAppearance: input.transformsCatAppearance ?? false,
  };
}

export function resolveEventVariant(
  request: EventRequestIdentifiers,
  now = new Date(),
): EventVariantDefinition | undefined {
  if (!request.isEventCard && !request.eventKey) return undefined;
  if (!request.isEventCard || !request.eventKey) {
    throw new EventRequestError(
      'eventReservationConflict',
      'Incomplete event request.',
      400,
    );
  }
  const variants = eventVariantRegistry[request.eventKey];
  if (!variants) {
    throw new EventRequestError('eventVariantInvalid', 'Unknown event.', 400);
  }
  const variantId = request.eventArtworkVariantId;
  const selected = variantId ? variants[variantId] : undefined;
  if (!selected) {
    throw new EventRequestError('eventVariantInvalid', 'Unknown event variant.', 400);
  }
  if (selected.tier === 'premium' && request.eventArtworkTier !== 'premium') {
    throw new EventRequestError(
      'premiumRequired',
      'Premium is required for this event variant.',
      403,
    );
  }
  if (!selected.enabled) {
    throw new EventRequestError('eventVariantDisabled', 'Event variant is disabled.', 409);
  }
  if (
    request.eventEdition !== selected.eventEdition ||
    request.eventArtworkTier !== selected.tier ||
    request.eventTemplateKey !== selected.templateKey ||
    request.eventInstructionKey !== selected.instructionKey ||
    !request.eventGenerationRequestId
  ) {
    throw new EventRequestError(
      'eventReservationConflict',
      'Event request metadata does not match the registry.',
      409,
    );
  }
  const active =
    now >= new Date(selected.startsAt) && now < new Date(selected.endsAt);
  if (!active && !isEventTestModeEnabled()) {
    throw new EventRequestError('eventInactive', 'Event is not active.', 409);
  }
  if (selected.tier === 'premium' && !isEventPremiumTestModeEnabled()) {
    throw new EventRequestError(
      'premiumVerificationUnavailable',
      'Premium event verification is unavailable.',
      403,
    );
  }
  return selected;
}

export function eventArtifactStorageId(
  discoveryId: string,
  variant: EventVariantDefinition | undefined,
  generationRequestId?: string,
): string {
  if (!variant) return discoveryId;
  const request = generationRequestId?.replace(/[^a-zA-Z0-9_-]/g, '_');
  return [
    discoveryId,
    variant.eventKey,
    variant.eventEdition,
    variant.variantId,
    request,
  ]
    .filter(Boolean)
    .join('--');
}
