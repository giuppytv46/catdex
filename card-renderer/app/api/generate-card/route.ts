import type { NextRequest } from 'next/server';
import { AIIllustrationFailedError, generateCatDexCard } from '../../../lib/pipeline/cardPipeline';
import { corsHeaders, logRendererRuntimeConfig, resolvePublicBaseUrl } from '../../../lib/pipeline/config';
import {
  assertSafeDiscoveryId,
  assertSafeJsonPayloadSize,
  RequestSafetyError,
  withTimeout,
} from '../../../lib/pipeline/requestSafety';
import type { CatRarity, GenerateCardInput } from '../../../lib/pipeline/types';

export const runtime = 'nodejs';

const rarities: CatRarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
const activeRenderIds = new Set<string>();
const generationTimeoutMs = Number(process.env.CARD_RENDERER_GENERATION_TIMEOUT_MS ?? '120000');

function isRarity(value: unknown): value is CatRarity {
  return typeof value === 'string' && rarities.includes(value as CatRarity);
}

function cleanRequiredString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

function cleanOptionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

function json(request: NextRequest, body: unknown, init?: ResponseInit): Response {
  return Response.json(body, {
    ...init,
    headers: {
      ...corsHeaders(request),
      ...init?.headers,
    },
  });
}

export async function OPTIONS(request: NextRequest) {
  return new Response(null, {
    status: 204,
    headers: corsHeaders(request),
  });
}

export async function POST(request: NextRequest) {
  let body: Partial<GenerateCardInput>;
  const publicBaseUrl = resolvePublicBaseUrl(request);

  try {
    assertSafeJsonPayloadSize(request);
    body = (await request.json()) as Partial<GenerateCardInput>;
  } catch (error) {
    if (error instanceof RequestSafetyError) {
      console.log('CATDEX_RENDERER_REQUEST_FAILED', error.code);
      return json(request, { success: false, error: error.code, message: error.message }, { status: error.status });
    }

    console.log('CATDEX_RENDERER_REQUEST_FAILED', 'INVALID_JSON');
    return json(request, { success: false, error: 'INVALID_JSON', message: 'Invalid JSON body.' }, { status: 400 });
  }

  const discoveryId = cleanRequiredString(body.discoveryId);
  const photoUrl = cleanRequiredString(body.photoUrl);
  const rarity = body.rarity;
  const displayName = cleanOptionalString(body.displayName);
  const displaySpecies = cleanOptionalString(body.displaySpecies);
  const displayCoatColor = cleanOptionalString(body.displayCoatColor);
  const displayCoatPattern = cleanOptionalString(body.displayCoatPattern);

  if (!discoveryId || !photoUrl || !isRarity(rarity)) {
    console.log('CATDEX_RENDERER_REQUEST_FAILED', 'INVALID_INPUT');
    return json(
      request,
      {
        success: false,
        error: 'INVALID_INPUT',
        message: 'Missing or invalid input. Required: discoveryId, photoUrl, rarity.',
        allowedRarities: rarities,
      },
      { status: 400 },
    );
  }

  try {
    assertSafeDiscoveryId(discoveryId);
  } catch (error) {
    if (error instanceof RequestSafetyError) {
      console.log('CATDEX_RENDERER_REQUEST_FAILED', error.code);
      return json(request, { success: false, error: error.code, message: error.message }, { status: error.status });
    }

    throw error;
  }

  if (activeRenderIds.has(discoveryId)) {
    console.log('CATDEX_RENDERER_REQUEST_FAILED', 'CARD_RENDER_IN_PROGRESS');
    return json(
      request,
      {
        success: false,
        error: 'CARD_RENDER_IN_PROGRESS',
        message: 'A render is already running for this discovery.',
      },
      { status: 409 },
    );
  }

  try {
    activeRenderIds.add(discoveryId);
    console.log('CATDEX_RENDERER_REQUEST_STARTED', discoveryId);
    logRendererRuntimeConfig(publicBaseUrl);
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_NAME', displayName ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_SPECIES', displaySpecies ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_COAT', displayCoatColor ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_PATTERN', displayCoatPattern ?? '-');

    const result = await withTimeout(
      generateCatDexCard({
        discoveryId,
        photoUrl,
        rarity,
        publicBaseUrl,
        eventKey: cleanOptionalString(body.eventKey),
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
      }),
      generationTimeoutMs,
      'CARD_GENERATION_TIMEOUT',
    );

    console.log('CATDEX_RENDERER_OUTPUT_URL', result.finalCardUrl);
    console.log('CATDEX_RENDERER_REQUEST_SUCCEEDED', discoveryId);
    return json(request, result);
  } catch (error) {
    console.log('CATDEX_RENDERER_REQUEST_FAILED', error instanceof Error ? error.message : String(error));
    console.error('CATDEX_GENERATE_CARD_ERROR', error);
    console.log('CATDEX_GENERATE_CARD_SUCCESS', false);
    if (error instanceof AIIllustrationFailedError) {
      return json(
        request,
        {
          success: false,
          error: 'AI_ILLUSTRATION_FAILED',
          message: 'AI illustration generation failed. Card was not generated.',
        },
        { status: 500 },
      );
    }

    if (error instanceof RequestSafetyError) {
      return json(request, { success: false, error: error.code, message: error.message }, { status: error.status });
    }

    return json(
      request,
      { success: false, error: 'CARD_GENERATION_FAILED', message: 'Failed to generate CatDex card.' },
      { status: 500 },
    );
  } finally {
    activeRenderIds.delete(discoveryId);
  }
}
