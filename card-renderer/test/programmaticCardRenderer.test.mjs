import assert from 'node:assert/strict';
import { readFile, rm } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import sharp from 'sharp';

import { generateCatDexCard } from '../lib/pipeline/cardPipeline.ts';
import {
  compositionAssetCacheStatsForTests,
  resetCompositionAssetCachesForTests,
} from '../lib/pipeline/compositionAssetCache.ts';
import { renderProgrammaticCard } from '../lib/pipeline/programmaticCardRenderer.tsx';
import { discoveryStorageDirectory } from '../lib/pipeline/storage.ts';
import { selectTemplate } from '../lib/pipeline/templateSelection.ts';

const mockArtworkPath = path.join(
  process.cwd(),
  'assets/cards/mock/mock-cat-artwork.png',
);
const cardText = {
  cardTitle: 'MAINCOONINO',
  speciesLine: 'Gatto domestico arancione tigrato',
  abilityName: '',
  abilityDescription: '',
  flavorText: '',
  funFact: '',
};

test('optimized composition is a valid 1500x2100 PNG with transparent artwork composited', async () => {
  resetCompositionAssetCachesForTests();
  const selected = await selectTemplate('common');
  const artworkBuffer = await transparentArtworkFixture();
  const layout = {
    ...selected.layout,
    artwork: {
      ...selected.layout.artwork,
      x: 600,
      y: 600,
      width: 300,
      height: 300,
      offsetY: 0,
    },
  };

  const output = await renderProgrammaticCard({
    templateKey: selected.key,
    templatePath: selected.templatePath,
    layout,
    artworkBuffer,
    cardNumber: '#0001',
    starCount: 1,
    text: cardText,
  });
  const outputImage = await rawImage(output);
  const resizedTemplate = await rawImage(
    await sharp(selected.templatePath)
      .resize(1500, 2100, { fit: 'fill' })
      .ensureAlpha()
      .png()
      .toBuffer(),
  );

  assert.equal(output.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  assert.equal(outputImage.info.format, 'raw');
  assert.equal(outputImage.info.width, 1500);
  assert.equal(outputImage.info.height, 2100);
  assert.deepEqual(
    pixelAt(outputImage, 610, 610),
    pixelAt(resizedTemplate, 610, 610),
    'transparent artwork pixels must leave the rarity template visible',
  );
  assert.deepEqual(
    pixelAt(outputImage, 750, 750).slice(0, 3),
    [255, 0, 0],
    'opaque artwork pixels must be composited into the artwork slot',
  );
});

test('static assets are cached without leaking discovery-specific text', async () => {
  resetCompositionAssetCachesForTests();
  const firstTemplate = await selectTemplate('common');
  const artworkBuffer = await readFile(mockArtworkPath);
  const first = await renderProgrammaticCard({
    templateKey: firstTemplate.key,
    templatePath: firstTemplate.templatePath,
    layout: firstTemplate.layout,
    artworkBuffer,
    cardNumber: '#0001',
    starCount: 1,
    text: { ...cardText, cardTitle: 'FIRST CAT' },
  });

  const secondTemplate = await selectTemplate('common');
  const second = await renderProgrammaticCard({
    templateKey: secondTemplate.key,
    templatePath: secondTemplate.templatePath,
    layout: secondTemplate.layout,
    artworkBuffer,
    cardNumber: '#0002',
    starCount: 1,
    text: { ...cardText, cardTitle: 'SECOND CAT' },
  });
  const stats = compositionAssetCacheStatsForTests();

  assert.equal(stats.layoutMisses, 1);
  assert.equal(stats.layoutHits, 1);
  assert.equal(stats.templateMisses, 1);
  assert.equal(stats.templateHits, 1);
  assert.equal(stats.fontMisses, 1);
  assert.equal(stats.fontHits, 1);
  assert.notDeepEqual(first, second, 'dynamic card text must never enter the static asset cache');
});

test('different rarity templates remain part of the final composition', async () => {
  resetCompositionAssetCachesForTests();
  const artworkBuffer = await readFile(mockArtworkPath);
  const common = await selectTemplate('common');
  const rare = await selectTemplate('rare');
  const commonOutput = await renderProgrammaticCard({
    templateKey: common.key,
    templatePath: common.templatePath,
    layout: common.layout,
    artworkBuffer,
    cardNumber: '#0003',
    starCount: 1,
    text: cardText,
  });
  const rareOutput = await renderProgrammaticCard({
    templateKey: rare.key,
    templatePath: rare.templatePath,
    layout: rare.layout,
    artworkBuffer,
    cardNumber: '#0003',
    starCount: 3,
    text: cardText,
  });

  assert.notDeepEqual(commonOutput, rareOutput);
});

test('composition does not write intermediate files', async () => {
  const source = await readFile(
    path.join(process.cwd(), 'lib/pipeline/programmaticCardRenderer.tsx'),
    'utf8',
  );

  assert.doesNotMatch(source, /\bwriteFile\b|\bmkdtemp\b|\btmpdir\b/);
});

test('optimized pipeline preserves the generate-card response shape', async () => {
  resetCompositionAssetCachesForTests();
  const discoveryId = `composition-response-shape-${process.pid}`;
  const sourceBytes = await readFile(mockArtworkPath);
  const sourceUrl = `data:image/png;base64,${sourceBytes.toString('base64')}`;
  const previousMockMode = process.env.CATDEX_MOCK_AI_ARTWORK;
  const previousStorageMode = process.env.CARD_RENDERER_STORAGE_MODE;
  process.env.CATDEX_MOCK_AI_ARTWORK = 'true';
  process.env.CARD_RENDERER_STORAGE_MODE = 'local';

  try {
    const output = await generateCatDexCard({
      discoveryId,
      idempotencyKey: discoveryId,
      photoUrl: sourceUrl,
      rarity: 'common',
      displayName: 'Response Cat',
      displaySpecies: 'Gatto domestico',
    });

    assert.deepEqual(Object.keys(output).sort(), [
      'analysisJson',
      'finalCardUrl',
      'illustratedCatUrl',
      'selectedTemplateKey',
    ]);
    assert.equal(output.selectedTemplateKey, 'default/common');
    assert.match(output.finalCardUrl, /\/final-card\.png$/);
  } finally {
    if (previousMockMode === undefined) {
      delete process.env.CATDEX_MOCK_AI_ARTWORK;
    } else {
      process.env.CATDEX_MOCK_AI_ARTWORK = previousMockMode;
    }
    if (previousStorageMode === undefined) {
      delete process.env.CARD_RENDERER_STORAGE_MODE;
    } else {
      process.env.CARD_RENDERER_STORAGE_MODE = previousStorageMode;
    }
    await rm(discoveryStorageDirectory(discoveryId), {
      recursive: true,
      force: true,
    });
  }
});

async function transparentArtworkFixture() {
  const redSquare = Buffer.from(
    '<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">' +
      '<rect x="30" y="30" width="40" height="40" fill="#ff0000"/>' +
      '</svg>',
  );
  return sharp({
    create: {
      width: 100,
      height: 100,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{ input: redSquare }])
    .png()
    .toBuffer();
}

async function rawImage(input) {
  return sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
}

function pixelAt(image, x, y) {
  const offset = (y * image.info.width + x) * image.info.channels;
  return Array.from(image.data.subarray(offset, offset + image.info.channels));
}
