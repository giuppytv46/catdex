import { stat } from 'node:fs/promises';
import sharp from 'sharp';

export type EventArtworkValidationResult = {
  technical: 'passed' | 'failed';
  transformation: 'passed' | 'uncertain' | 'failed';
  reason?: string;
};

export async function validateEventArtwork(
  artwork: Buffer,
  transformsCatAppearance: boolean,
): Promise<EventArtworkValidationResult> {
  try {
    const image = sharp(artwork, { failOn: 'error' });
    const [metadata, stats] = await Promise.all([
      image.metadata(),
      image.clone().ensureAlpha().stats(),
    ]);
    if (!metadata.width || !metadata.height || metadata.width < 256 || metadata.height < 256) {
      return {
        technical: 'failed',
        transformation: transformsCatAppearance ? 'failed' : 'uncertain',
        reason: 'image_dimensions_too_small',
      };
    }
    const visibleColorContent = stats.channels
      .slice(0, 3)
      .some((channel) => channel.max > channel.min || channel.max > 0);
    const alpha = stats.channels[3];
    if (!visibleColorContent || !alpha || alpha.max <= 0) {
      return {
        technical: 'failed',
        transformation: transformsCatAppearance ? 'failed' : 'uncertain',
        reason: 'image_content_empty',
      };
    }
    return {
      technical: 'passed',
      transformation: transformsCatAppearance ? 'uncertain' : 'passed',
    };
  } catch {
    return {
      technical: 'failed',
      transformation: 'failed',
      reason: 'image_decode_failed',
    };
  }
}

export async function validateFinalCard(
  bytes: Buffer,
  filePath: string,
): Promise<boolean> {
  try {
    const [metadata, file] = await Promise.all([
      sharp(bytes, { failOn: 'error' }).metadata(),
      stat(filePath),
    ]);
    return (
      metadata.width === 1500 &&
      metadata.height === 2100 &&
      file.isFile() &&
      file.size > 0
    );
  } catch {
    return false;
  }
}

export class EventArtworkValidationError extends Error {
  constructor() {
    super('Event artwork validation failed.');
    this.name = 'EventArtworkValidationError';
  }
}
