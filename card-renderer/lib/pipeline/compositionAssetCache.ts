import { readFile } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
import { CARD_HEIGHT, CARD_WIDTH } from '../cardLayout';
import type { CardTemplateLayout } from './types';

export type PreparedTemplateImage = {
  data: Buffer;
  width: number;
  height: number;
  channels: 4;
};

type CacheStats = {
  templateHits: number;
  templateMisses: number;
  layoutHits: number;
  layoutMisses: number;
  fontHits: number;
  fontMisses: number;
};

const templateCache = new Map<string, Promise<PreparedTemplateImage>>();
const layoutCache = new Map<string, Promise<CardTemplateLayout>>();
const fontCache = new Map<string, Promise<Buffer | undefined>>();
const cacheStats: CacheStats = createEmptyStats();

const fontPaths: Record<string, string> = {
  CinzelDecorative: 'public/fonts/CinzelDecorative-Bold.ttf',
  Fredoka: 'public/fonts/Fredoka-Bold.ttf',
};

export async function loadCachedTemplate(
  templateKey: string,
  templatePath: string,
): Promise<PreparedTemplateImage> {
  const existing = templateCache.get(templateKey);
  if (existing) {
    cacheStats.templateHits += 1;
    console.log('CATDEX_TEMPLATE_CACHE_HIT', templateKey);
    console.log('CATDEX_PERF_COMPOSITION_TEMPLATE_READ_MS', 0);
    return existing;
  }

  cacheStats.templateMisses += 1;
  console.log('CATDEX_TEMPLATE_CACHE_MISS', templateKey);
  const loading = prepareTemplate(templatePath);
  templateCache.set(templateKey, loading);
  try {
    return await loading;
  } catch (error) {
    if (templateCache.get(templateKey) === loading) {
      templateCache.delete(templateKey);
    }
    throw error;
  }
}

export async function loadCachedLayout(
  templateKey: string,
  layoutPath: string,
): Promise<CardTemplateLayout> {
  const existing = layoutCache.get(templateKey);
  if (existing) {
    cacheStats.layoutHits += 1;
    console.log('CATDEX_LAYOUT_CACHE_HIT', templateKey);
    console.log('CATDEX_PERF_COMPOSITION_LAYOUT_READ_MS', 0);
    return existing;
  }

  cacheStats.layoutMisses += 1;
  console.log('CATDEX_LAYOUT_CACHE_MISS', templateKey);
  const loading = measureMs('CATDEX_PERF_COMPOSITION_LAYOUT_READ_MS', async () => {
    const source = await readFile(layoutPath, 'utf8');
    return JSON.parse(source) as CardTemplateLayout;
  });
  layoutCache.set(templateKey, loading);
  try {
    return await loading;
  } catch (error) {
    if (layoutCache.get(templateKey) === loading) {
      layoutCache.delete(templateKey);
    }
    throw error;
  }
}

export async function loadCachedFont(fontName: string): Promise<Buffer | undefined> {
  const existing = fontCache.get(fontName);
  if (existing) {
    cacheStats.fontHits += 1;
    console.log('CATDEX_FONT_CACHE_HIT', fontName);
    return existing;
  }

  cacheStats.fontMisses += 1;
  console.log('CATDEX_FONT_CACHE_MISS', fontName);
  const fontPath = fontPaths[fontName];
  const loading = fontPath
    ? readFile(path.join(process.cwd(), fontPath)).catch(() => undefined)
    : Promise.resolve(undefined);
  fontCache.set(fontName, loading);
  return loading;
}

export function resetCompositionAssetCachesForTests(): void {
  templateCache.clear();
  layoutCache.clear();
  fontCache.clear();
  Object.assign(cacheStats, createEmptyStats());
}

export function compositionAssetCacheStatsForTests(): Readonly<CacheStats> {
  return { ...cacheStats };
}

async function prepareTemplate(templatePath: string): Promise<PreparedTemplateImage> {
  const templateBuffer = await measureMs(
    'CATDEX_PERF_COMPOSITION_TEMPLATE_READ_MS',
    () => readFile(templatePath),
  );
  const prepared = await measureMs(
    'CATDEX_PERF_COMPOSITION_TEMPLATE_DECODE_RESIZE_MS',
    () =>
      sharp(templateBuffer, { failOn: 'error' })
        .resize(CARD_WIDTH, CARD_HEIGHT, { fit: 'fill' })
        .ensureAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true }),
  );

  return {
    data: prepared.data,
    width: prepared.info.width,
    height: prepared.info.height,
    channels: 4,
  };
}

async function measureMs<T>(label: string, operation: () => Promise<T>): Promise<T> {
  const startedAt = performance.now();
  try {
    return await operation();
  } finally {
    console.log(label, Math.round(performance.now() - startedAt));
  }
}

function createEmptyStats(): CacheStats {
  return {
    templateHits: 0,
    templateMisses: 0,
    layoutHits: 0,
    layoutMisses: 0,
    fontHits: 0,
    fontMisses: 0,
  };
}
