import type { NextRequest } from 'next/server';

export const CARD_RENDERER_VERSION = 'alpha';
export const CARD_RENDERER_SERVICE = 'catdex-card-renderer';

export type StorageMode = 'local' | 'supabase';

export function isMockArtworkEnabled(): boolean {
  return process.env.CATDEX_MOCK_AI_ARTWORK !== 'false';
}

export function storageMode(): StorageMode {
  return process.env.CARD_RENDERER_STORAGE_MODE === 'supabase' ? 'supabase' : 'local';
}

export function resolvePublicBaseUrl(request?: NextRequest): string | undefined {
  const configured = process.env.CARD_RENDERER_PUBLIC_BASE_URL?.trim();
  if (configured) {
    return configured.replace(/\/+$/, '');
  }

  if (process.env.NODE_ENV === 'production') {
    console.warn('CATDEX_RENDERER_PUBLIC_URL_WARNING missing_CARD_RENDERER_PUBLIC_BASE_URL');
  }

  const origin = request?.headers.get('origin') ?? request?.nextUrl?.origin;
  if (origin) {
    return origin.replace(/\/+$/, '');
  }

  return undefined;
}

export function logRendererRuntimeConfig(publicBaseUrl?: string): void {
  console.log('CATDEX_RENDERER_PUBLIC_URL', publicBaseUrl ?? '-');
  console.log('CATDEX_RENDERER_STORAGE_MODE', storageMode());
  console.log('CATDEX_MOCK_AI_ARTWORK_ENABLED', isMockArtworkEnabled());
}

export function allowedOrigins(): string[] {
  return (process.env.CARD_RENDERER_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

export function corsHeaders(request: NextRequest): HeadersInit {
  const requestOrigin = request.headers.get('origin');
  const configuredOrigins = allowedOrigins();
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers': 'content-type',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  };

  if (!requestOrigin) {
    return headers;
  }

  if (configuredOrigins.includes(requestOrigin)) {
    headers['Access-Control-Allow-Origin'] = requestOrigin;
    headers.Vary = 'Origin';
    return headers;
  }

  if (configuredOrigins.length === 0 && process.env.NODE_ENV !== 'production') {
    headers['Access-Control-Allow-Origin'] = requestOrigin;
    headers.Vary = 'Origin';
  }

  return headers;
}

export function isSupabaseStorageConfigured(): boolean {
  return Boolean(
    process.env.SUPABASE_URL?.trim() &&
      process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() &&
      process.env.SUPABASE_CARD_BUCKET?.trim(),
  );
}
