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

test('Free requests for all Premium variants are rejected', () => {
  for (const variantId of [
    'halloween_witch_cat',
    'halloween_pumpkin_king',
    'halloween_night_spirit',
  ]) {
    const definition = eventVariantRegistry.halloween_2026[variantId];
    assert.throws(
      () =>
        resolveEventVariant(
          eventRequest({
            eventArtworkVariantId: variantId,
            eventArtworkTier: 'free',
            eventTemplateKey: definition.templateKey,
            eventInstructionKey: definition.instructionKey,
          }),
          activeDate,
        ),
      (error) => error instanceof EventRequestError && error.code === 'premiumRequired',
      variantId,
    );
  }
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

test('haunted-house variant uses the redesigned mansion art direction', () => {
  const haunted = eventVariantRegistry.halloween_2026.halloween_haunted_frame;
  const instructions = haunted.artworkInstructions.join(' ');
  const negatives = haunted.negativeConstraints.join(' ');

  assert.match(instructions, /(haunted Victorian|Victorian haunted) mansion/i);
  assert.match(instructions, /front door/i);
  assert.match(instructions, /warm illuminated windows/i);
  assert.match(instructions, /winding path/i);
  assert.match(instructions, /fog around the cat paws/i);
  assert.match(instructions, /pumpkins and lanterns/i);
  assert.match(instructions, /blue, purple, orange and gold lighting/i);
  assert.match(instructions, /matching light and shadows on the cat/i);
  assert.match(instructions, /preserve coat color|Preserve coat color/i);
  assert.match(negatives, /large foreground tombstones/i);
  assert.match(negatives, /cemetery dominating the scene/i);
  assert.match(negatives, /giant ghosts behind the cat/i);
  assert.match(negatives, /gray smoke masses hiding the mansion/i);
  assert.match(negatives, /abstract geometric outlines/i);
  assert.match(negatives, /pasted cutout appearance/i);
  assert.match(negatives, /changed coat pattern/i);
});

test('haunted template redesign is isolated from other event variants', async () => {
  const haunted = eventVariantRegistry.halloween_2026.halloween_haunted_frame;
  const hauntedTemplate = await selectTemplate(
    'common',
    haunted.eventKey,
    haunted.templateKey,
  );
  const source = await readFile(hauntedTemplate.templatePath, 'utf8');

  assert.match(source, /#100D36|#253A78/);
  assert.match(source, /#FFB347|#FFD66B|#E8B95A/);
  assert.match(source, /id="mansionEntrance"/);
  assert.match(source, /id="windingPath"/);
  assert.doesNotMatch(source, /tombstone|cemetery/i);
  assert.doesNotMatch(source, /#6FE0B7/);

  const pumpkin = eventVariantRegistry.halloween_2026.halloween_pumpkins;
  const moonlight = eventVariantRegistry.halloween_2026.halloween_moonlight;
  const witch = eventVariantRegistry.halloween_2026.halloween_witch_cat;
  assert.match(pumpkin.artworkInstructions.join(' '), /pumpkins, autumn leaves/i);
  assert.match(moonlight.artworkInstructions.join(' '), /full moon, subtle bats/i);
  assert.match(witch.artworkInstructions.join(' '), /small elegant witch hat/i);
  assert.equal(pumpkin.templateKey, 'halloween_pumpkins');
  assert.equal(moonlight.templateKey, 'halloween_moonlight');
  assert.equal(witch.templateKey, 'halloween_witch_cat_premium');
});

test('an explicit Free-tier selection remains valid for a Premium user flow', () => {
  const haunted = eventVariantRegistry.halloween_2026.halloween_haunted_frame;
  const resolved = resolveEventVariant(
    eventRequest({
      eventArtworkVariantId: haunted.variantId,
      eventArtworkTier: haunted.tier,
      eventTemplateKey: haunted.templateKey,
      eventInstructionKey: haunted.instructionKey,
    }),
    activeDate,
  );

  assert.equal(resolved.variantId, 'halloween_haunted_frame');
  assert.equal(resolved.tier, 'free');
});

test('all Premium profiles resolve with fixed server-owned settings', () => {
  const previousEventMode = process.env.CATDEX_EVENT_TEST_MODE;
  const previousPremiumMode = process.env.CATDEX_EVENT_PREMIUM_TEST_MODE;
  process.env.CATDEX_EVENT_TEST_MODE = 'true';
  process.env.CATDEX_EVENT_PREMIUM_TEST_MODE = 'true';
  try {
    for (const variantId of [
      'halloween_witch_cat',
      'halloween_pumpkin_king',
      'halloween_night_spirit',
    ]) {
      const definition = eventVariantRegistry.halloween_2026[variantId];
      const resolved = resolveEventVariant(
        eventRequest({
          eventArtworkVariantId: variantId,
          eventArtworkTier: 'premium',
          eventTemplateKey: definition.templateKey,
          eventInstructionKey: definition.instructionKey,
        }),
        activeDate,
      );
      assert.equal(resolved, definition);
      assert.equal(resolved.transformsCatAppearance, true);
      assert.equal(resolved.tier, 'premium');
    }
    assert.match(
      eventVariantRegistry.halloween_2026.halloween_pumpkin_king.artworkInstructions.join(' '),
      /crown.*royal cape|royal cape.*crown/i,
    );
    assert.match(
      eventVariantRegistry.halloween_2026.halloween_night_spirit.artworkInstructions.join(' '),
      /spirit flames/i,
    );
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

test('new Premium variants return exact renderer response metadata', async () => {
  const source = await readFile(
    path.join(process.cwd(), 'assets/cards/mock/mock-cat-artwork.png'),
  );
  const previousMock = process.env.CATDEX_MOCK_AI_ARTWORK;
  const previousStorage = process.env.CARD_RENDERER_STORAGE_MODE;
  process.env.CATDEX_MOCK_AI_ARTWORK = 'true';
  process.env.CARD_RENDERER_STORAGE_MODE = 'local';
  const artifactIds = [];
  try {
    for (const variantId of [
      'halloween_pumpkin_king',
      'halloween_night_spirit',
    ]) {
      const definition = eventVariantRegistry.halloween_2026[variantId];
      const discoveryId = `${variantId}-${process.pid}`;
      const artifactStorageId = eventArtifactStorageId(
        discoveryId,
        definition,
        `request-${variantId}`,
      );
      artifactIds.push(artifactStorageId);
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
        eventGenerationRequestId: `request-${variantId}`,
        isEventCard: true,
        eventArtworkInstructions: definition.artworkInstructions,
        eventArtworkNegativeConstraints: definition.negativeConstraints,
        displayName: 'Luna',
        displaySpecies: 'Gatto domestico',
      });
      assert.equal(output.eventArtworkVariantId, variantId);
      assert.equal(output.eventArtworkTier, 'premium');
      assert.equal(output.eventTemplateKey, definition.templateKey);
      assert.equal(output.isEventCard, true);
      assert.equal(output.generationStatus, 'completed');
    }
  } finally {
    restoreEnv('CATDEX_MOCK_AI_ARTWORK', previousMock);
    restoreEnv('CARD_RENDERER_STORAGE_MODE', previousStorage);
    await Promise.all(
      artifactIds.map((artifactStorageId) =>
        rm(discoveryStorageDirectory(artifactStorageId), {
          recursive: true,
          force: true,
        }),
      ),
    );
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
