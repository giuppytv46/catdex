import { ImageResponse } from '@vercel/og';
import type { NextRequest } from 'next/server';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { CardRenderer } from '../../../lib/CardRenderer';
import { CARD_HEIGHT, CARD_LAYOUT, CARD_TEMPLATE_PATH, CARD_WIDTH, CAT_IMAGE_Y_OFFSET, STAR_TOTAL } from '../../../lib/cardLayout';

export const runtime = 'nodejs';
const cinzelFontPath = 'public/fonts/CinzelDecorative-Bold.ttf';

type CardPayload = {
  cardNumber?: string;
  catName?: string;
  species?: string;
  rarity?: string;
  starCount?: number;
  template?: string;
  catImageUrl?: string;
};

function cleanText(value: unknown, fallback: string): string {
  if (typeof value !== 'string') {
    return fallback;
  }

  const normalized = value.replace(/\s+/g, ' ').trim();
  return normalized.length > 0 ? normalized.slice(0, 80) : fallback;
}

function cleanStarCount(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return 0;
  }

  return Math.max(0, Math.min(STAR_TOTAL, Math.round(value)));
}

function cleanImageUrl(value: unknown): string | undefined {
  if (typeof value !== 'string' || value.trim().length === 0) {
    return undefined;
  }

  try {
    const url = new URL(value.trim());
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.toString() : undefined;
  } catch {
    return undefined;
  }
}

async function loadCinzelFont(): Promise<Buffer | undefined> {
  try {
    const cinzelFont = await readFile(path.join(process.cwd(), cinzelFontPath));
    console.log('CATDEX_FONT_PRIMARY', 'CinzelDecorative');
    console.log('CATDEX_CINZEL_FONT_LOADED', true);
    console.log('CATDEX_CINZEL_FONT_BYTES', cinzelFont.byteLength);
    return cinzelFont;
  } catch (error) {
    console.log('CATDEX_FONT_PRIMARY', 'CinzelDecorative');
    console.log('CATDEX_CINZEL_FONT_LOADED', false);
    console.log('CATDEX_FONT_ERROR', error);
    return undefined;
  }
}

export async function POST(request: NextRequest) {
  let payload: CardPayload;

  try {
    payload = (await request.json()) as CardPayload;
  } catch {
    return Response.json({ error: 'Invalid JSON body.' }, { status: 400 });
  }

  const templateUrl = new URL(CARD_TEMPLATE_PATH, request.url).toString();
  console.log('CATDEX_API_TEMPLATE_PATH', CARD_TEMPLATE_PATH);
  console.log('CATDEX_RENDERER_FONT', 'CinzelDecorative');
  console.log('CATDEX_RENDERER_LAYOUT_VERSION', 'final_v1');
  console.log('CATDEX_RENDERER_USING_FINAL_LAYOUT', true);
  console.log('CATDEX_CAT_IMAGE_Y_OFFSET', CAT_IMAGE_Y_OFFSET);
  const cinzelFontData = await loadCinzelFont();

  return new ImageResponse(
    (
      <CardRenderer
        templateUrl={templateUrl}
        layout={CARD_LAYOUT}
        data={{
          cardNumber: cleanText(payload.cardNumber, '#0000'),
          catName: cleanText(payload.catName, 'UNKNOWN').toUpperCase(),
          species: cleanText(payload.species, 'Gatto domestico'),
          starCount: cleanStarCount(payload.starCount),
          catImageUrl: cleanImageUrl(payload.catImageUrl),
        }}
      />
    ),
    {
      width: CARD_WIDTH,
      height: CARD_HEIGHT,
      fonts: cinzelFontData
        ? [
            {
              name: 'CinzelDecorative',
              data: cinzelFontData,
              weight: 700,
              style: 'normal',
            },
          ]
        : undefined,
      headers: {
        'cache-control': 'public, max-age=31536000, immutable',
      },
    },
  );
}
