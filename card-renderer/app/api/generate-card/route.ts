import type { NextRequest } from 'next/server';
import { AIIllustrationFailedError, generateCatDexCard } from '../../../lib/pipeline/cardPipeline';
import { corsHeaders, logRendererRuntimeConfig, resolvePublicBaseUrl } from '../../../lib/pipeline/config';
import {
  assertSafeDiscoveryId,
  assertSafeJsonPayloadSize,
  RequestSafetyError,
  withTimeout,
} from '../../../lib/pipeline/requestSafety';
import { resolveRenderJob } from '../../../lib/pipeline/renderJobLifecycle';
import { PerformanceStep } from '../../../lib/pipeline/performanceInstrumentation';
import { hasFinalCardArtifact, readStoredGeneratedCard } from '../../../lib/pipeline/storage';
import type { CatRarity, GenerateCardInput, GenerateCardOutput } from '../../../lib/pipeline/types';

export const runtime = 'nodejs';

const rarities: CatRarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
const activeRenderJobs = new Map<string, Promise<GenerateCardOutput>>();
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
  const responseTiming = new PerformanceStep('RESPONSE_SENT');
  try {
    return Response.json(body, {
      ...init,
      headers: {
        ...corsHeaders(request),
        ...init?.headers,
      },
    });
  } finally {
    responseTiming.end();
  }
}

export async function OPTIONS(request: NextRequest) {
  return new Response(null, {
    status: 204,
    headers: corsHeaders(request),
  });
}

export async function POST(request: NextRequest) {
  const requestTiming = new PerformanceStep('REQUEST_RECEIVED');
  requestTiming.end();
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
  const idempotencyKey = cleanOptionalString(body.idempotencyKey) ?? `card:${discoveryId ?? 'unknown'}:v1`;

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

  try {
    console.log('CATDEX_RENDERER_REQUEST_STARTED', discoveryId);
    console.log('CATDEX_RENDERER_IDEMPOTENCY_KEY', idempotencyKey);
    logRendererRuntimeConfig(publicBaseUrl);
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_NAME', displayName ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_SPECIES', displaySpecies ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_COAT', displayCoatColor ?? '-');
    console.log('CATDEX_GENERATE_CARD_REQUEST_DISPLAY_PATTERN', displayCoatPattern ?? '-');

    const jobResolution = await resolveRenderJob({
      jobs: activeRenderJobs,
      key: idempotencyKey,
      readCompleted: () => readCompletedResult(discoveryId),
      createJob: () =>
        generateCatDexCard({
          discoveryId,
          idempotencyKey,
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
      onExistingResult: () => {
        console.log(
          'CATDEX_RENDERER_EXISTING_RESULT_FOUND',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
        );
      },
      onCreated: () => {
        console.log(
          'CATDEX_RENDERER_JOB_CREATED',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
        );
      },
      onReused: () => {
        console.log(
          'CATDEX_RENDERER_JOB_REUSED',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
        );
      },
      onCompleted: () => {
        console.log(
          'CATDEX_RENDERER_JOB_COMPLETED',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
        );
      },
      onFailed: (error) => {
        console.log(
          'CATDEX_RENDERER_JOB_FAILED',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
          error instanceof Error ? error.message : String(error),
        );
      },
      onRemoved: () => {
        console.log(
          'CATDEX_RENDERER_JOB_REMOVED',
          `discoveryId=${discoveryId}`,
          `idempotencyKey=${idempotencyKey}`,
        );
      },
    });

    if (jobResolution.kind === 'completed') {
      console.log('CATDEX_RENDERER_RESPONSE_SENT', discoveryId);
      return json(request, jobResolution.result);
    }

    const result = await withTimeout(jobResolution.job, generationTimeoutMs, 'CARD_GENERATION_TIMEOUT');

    console.log('CATDEX_RENDERER_OUTPUT_URL', result.finalCardUrl);
    console.log('CATDEX_RENDERER_REQUEST_SUCCEEDED', discoveryId);
    console.log('CATDEX_RENDERER_RESPONSE_SENT', discoveryId);
    return json(request, result);
  } catch (error) {
    if (error instanceof RequestSafetyError && error.code === 'CARD_GENERATION_TIMEOUT') {
      console.log(
        'CATDEX_RENDERER_REQUEST_TIMEOUT_JOB_CONTINUES',
        `discoveryId=${discoveryId}`,
        `idempotencyKey=${idempotencyKey}`,
      );
    }
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
  }
}

async function readCompletedResult(discoveryId: string): Promise<GenerateCardOutput | undefined> {
  const metadata = await readStoredGeneratedCard(discoveryId);
  if (!metadata) {
    return undefined;
  }
  if (!(await hasFinalCardArtifact(discoveryId))) {
    return undefined;
  }

  return {
    finalCardUrl: metadata.finalCardUrl,
    illustratedCatUrl: metadata.illustratedCatUrl,
    analysisJson: metadata.analysisJson,
    selectedTemplateKey: metadata.selectedTemplateKey,
  };
}
