import type { NextRequest } from 'next/server';
import {
  CARD_RENDERER_SERVICE,
  CARD_RENDERER_VERSION,
  corsHeaders,
  isMockArtworkEnabled,
  logRendererRuntimeConfig,
  resolvePublicBaseUrl,
  storageMode,
} from '../../../lib/pipeline/config';

export const runtime = 'nodejs';

function response(request: NextRequest): Response {
  const publicBaseUrl = resolvePublicBaseUrl(request);
  logRendererRuntimeConfig(publicBaseUrl);

  return Response.json(
    {
      ok: true,
      service: CARD_RENDERER_SERVICE,
      mockArtwork: isMockArtworkEnabled(),
      storageMode: storageMode(),
      version: CARD_RENDERER_VERSION,
    },
    {
      headers: corsHeaders(request),
    },
  );
}

export async function GET(request: NextRequest) {
  return response(request);
}

export async function OPTIONS(request: NextRequest) {
  return new Response(null, {
    status: 204,
    headers: corsHeaders(request),
  });
}
