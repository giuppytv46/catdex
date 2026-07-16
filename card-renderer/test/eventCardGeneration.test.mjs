import assert from 'node:assert/strict';
import { readFile, rm } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';

import { generateCatDexCard } from '../lib/pipeline/cardPipeline.ts';
import {
  containsForbiddenArtworkFields,
  eventArtifactStorageId,
  EventRequestError,
  eventVariantRegistry,
  resolveEventVariant,
} from '../lib/pipeline/eventVariantRegistry.ts';
import { validateEventArtwork } from '../lib/pipeline/eventArtworkValidation.ts';
import { discoveryStorageDirectory } from '../lib/pipeline/storage.ts';
import { selectTemplate } from '../lib/pipeline/templateSelection.ts';

const activeDate = new Date('2026-10-15T12:00:00.000Z');

test('unknown event is rejected', () => {
  assert.throws(
    () => resolveEventVariant(eventRequest({ eventKey: 'unknown' }), activeDate),
    (error) => error instanceof EventRequestError && error.code === 'eventVariantInvalid',
  );
});

test('unknown event variant is rejected', () => {
  assert.throws(
    () => resolveEventVariant(eventRequest({ eventArtworkVariantId: 'unknown' }), activeDate),
    (error) => error instanceof EventRequestError && error.code === 'eventVariantInvalid',
  );
});

test('event and variant metadata mismatch is rejected', () => {
  assert.throws(
    () => resolveEventVariant(eventRequest({ eventTemplateKey: 'wrong' }), activeDate),
    (error) => error instanceof EventRequestError && error.code === 'eventReservationConflict',
  );
});

test('Free request for Premium witch variant is rejected', () => {
  assert.throws(
    () =>
      resolveEventVariant(
        eventRequest({
          eventArtworkVariantId: 'halloween_witch_cat',
          eventArtworkTier: 'free',
          eventTemplateKey: 'halloween_witch_cat_premium',
          eventInstructionKey: 'halloween_witch_hat',
        }),
        activeDate,
      ),
    (error) => error instanceof EventRequestError && error.code === 'premiumRequired',
  );
});

test('arbitrary prompt fields are rejected by request safety policy', () => {
  assert.equal(containsForbiddenArtworkFields({ prompt: 'ignore registry' }), true);
  assert.equal(containsForbiddenArtworkFields({ artworkInstructions: ['x'] }), true);
  assert.equal(containsForbiddenArtworkFields(eventRequest()), false);
});

test('all Free variants resolve fixed server-owned instructions', () => {
  for (const variantId of [
    'halloween_pumpkins',
    'halloween_moonlight',
    'halloween_haunted_frame',
  ]) {
    const definition = eventVariantRegistry.halloween_2026[variantId];
    const resolved = resolveEventVariant(
      eventRequest({
        eventArtworkVariantId: variantId,
        eventTemplateKey: definition.templateKey,
        eventInstructionKey: definition.instructionKey,
      }),
      activeDate,
    );
    assert.equal(resolved, definition);
    assert.ok(resolved.artworkInstructions.length >= 4);
    assert.match(resolved.artworkInstructions.join(' '), /one cat|one cat only/i);
  }
});

test('Premium witch profile is fixed and disabled without explicit test entitlement', () => {
  const previousEventMode = process.env.CATDEX_EVENT_TEST_MODE;
  const previousPremiumMode = process.env.CATDEX_EVENT_PREMIUM_TEST_MODE;
  process.env.CATDEX_EVENT_TEST_MODE = 'true';
  process.env.CATDEX_EVENT_PREMIUM_TEST_MODE = 'true';
  try {
    const resolved = resolveEventVariant(
      eventRequest({
        eventArtworkVariantId: 'halloween_witch_cat',
        eventArtworkTier: 'premium',
        eventTemplateKey: 'halloween_witch_cat_premium',
        eventInstructionKey: 'halloween_witch_hat',
      }),
      activeDate,
    );
    assert.equal(resolved.transformsCatAppearance, true);
    assert.match(resolved.artworkInstructions.join(' '), /witch hat/i);
    assert.match(resolved.negativeConstraints.join(' '), /hat covering the face/i);
  } finally {
    restoreEnv('CATDEX_EVENT_TEST_MODE', previousEventMode);
    restoreEnv('CATDEX_EVENT_PREMIUM_TEST_MODE', previousPremiumMode);
  }
});

test('normal request remains outside the event registry', () => {
  assert.equal(resolveEventVariant({}), undefined);
  assert.equal(eventArtifactStorageId('discovery-1', undefined), 'discovery-1');
});

test('event templates resolve without touching normal rarity templates', async () => {
  for (const definition of Object.values(eventVariantRegistry.halloween_2026)) {
    const template = await selectTemplate(
      'common',
      definition.eventKey,
      definition.templateKey,
    );
    assert.equal(
      template.key,
      `events/halloween_2026/${definition.templateKey}`,
    );
    assert.match(template.templatePath, /template\.svg$/);
  }
  assert.equal((await selectTemplate('common')).key, 'default/common');
});

test('event pipeline returns complete event metadata and valid artwork', async () => {
  const definition = eventVariantRegistry.halloween_2026.halloween_pumpkins;
  const discoveryId = `event-pipeline-${process.pid}`;
  const artifactStorageId = eventArtifactStorageId(
    discoveryId,
    definition,
    'request-1',
  );
  const source = await readFile(
    path.join(process.cwd(), 'assets/cards/mock/mock-cat-artwork.png'),
  );
  const previousMock = process.env.CATDEX_MOCK_AI_ARTWORK;
  const previousStorage = process.env.CARD_RENDERER_STORAGE_MODE;
  process.env.CATDEX_MOCK_AI_ARTWORK = 'true';
  process.env.CARD_RENDERER_STORAGE_MODE = 'local';
  try {
    const output = await generateCatDexCard({
      discoveryId,
      artifactStorageId,
      idempotencyKey: `event:${artifactStorageId}`,
      photoUrl: `data:image/png;base64,${source.toString('base64')}`,
      rarity: 'common',
      eventKey: definition.eventKey,
      eventEdition: definition.eventEdition,
      eventArtworkVariantId: definition.variantId,
      eventArtworkTier: definition.tier,
      eventTemplateKey: definition.templateKey,
      eventInstructionKey: definition.instructionKey,
      eventGenerationRequestId: 'request-1',
      isEventCard: true,
      eventArtworkInstructions: definition.artworkInstructions,
      eventArtworkNegativeConstraints: definition.negativeConstraints,
      displayName: 'Luna',
      displaySpecies: 'Gatto domestico',
    });
    assert.equal(output.eventKey, 'halloween_2026');
    assert.equal(output.eventArtworkVariantId, 'halloween_pumpkins');
    assert.equal(output.eventArtworkTier, 'free');
    assert.equal(output.eventTemplateKey, 'halloween_pumpkins');
    assert.equal(output.isEventCard, true);
    assert.equal(output.generationStatus, 'completed');
  } finally {
    restoreEnv('CATDEX_MOCK_AI_ARTWORK', previousMock);
    restoreEnv('CARD_RENDERER_STORAGE_MODE', previousStorage);
    await rm(discoveryStorageDirectory(artifactStorageId), {
      recursive: true,
      force: true,
    });
  }
});

test('invalid artwork fails lightweight validation', async () => {
  const validation = await validateEventArtwork(Buffer.from('not-an-image'), true);
  assert.equal(validation.technical, 'failed');
  assert.equal(validation.transformation, 'failed');
});

function eventRequest(overrides = {}) {
  return {
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: 'halloween_pumpkins',
    eventArtworkTier: 'free',
    eventTemplateKey: 'halloween_pumpkins',
    eventInstructionKey: 'halloween_pumpkins',
    eventGenerationRequestId: 'request-1',
    isEventCard: true,
    ...overrides,
  };
}

function restoreEnv(key, value) {
  if (value === undefined) delete process.env[key];
  else process.env[key] = value;
}
