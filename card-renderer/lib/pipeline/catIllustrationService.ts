import type { CatAnalysisJson } from './types';
import { publicCardUrl, savePngArtifact } from './storage';
import { removeBackgroundFromPng } from './backgroundRemovalService';

type CreateCatIllustrationInput = {
  discoveryId: string;
  photoUrl: string;
  analysis: CatAnalysisJson;
  cardStyle: string;
};

export async function createCatIllustration(input: CreateCatIllustrationInput): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('missing_OPENAI_API_KEY');
  }

  const sourceImage = await fetch(input.photoUrl);
  if (!sourceImage.ok) {
    throw new Error(`original_photo_fetch_failed_${sourceImage.status}`);
  }

  const sourceContentType = sourceImage.headers.get('content-type') ?? 'image/png';
  const sourceExtension = sourceContentType.includes('jpeg') || sourceContentType.includes('jpg') ? 'jpg' : 'png';
  const sourceBlob = new Blob([await sourceImage.arrayBuffer()], { type: sourceContentType });
  const sourceFile = new File([sourceBlob], `cat-reference.${sourceExtension}`, { type: sourceContentType });
  const prompt = illustrationPrompt(input);
  const form = new FormData();
  form.append('model', process.env.OPENAI_IMAGE_MODEL ?? 'gpt-image-1.5');
  form.append('image', sourceFile);
  form.append('prompt', prompt);
  form.append('background', 'transparent');
  form.append('output_format', 'png');
  form.append('size', '1024x1024');
  form.append('quality', 'high');

  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_TRANSPARENT_REQUEST', true);
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_OUTPUT_FORMAT', 'png');
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_BACKGROUND', 'transparent');

  const response = await fetch('https://api.openai.com/v1/images/edits', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
    body: form,
  });

  const body = (await response.json()) as {
    data?: Array<{ b64_json?: string; url?: string }>;
    error?: { message?: string };
  };

  if (!response.ok) {
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_TRANSPARENT_FAILED', true);
    console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_ERROR', body.error?.message ?? `openai_image_error_${response.status}`);
    throw new Error(body.error?.message ?? `openai_image_error_${response.status}`);
  }

  const firstImage = body.data?.[0];
  if (firstImage?.b64_json) {
    const imageBytes = Buffer.from(firstImage.b64_json, 'base64');
    return saveIllustration(input.discoveryId, imageBytes);
  }

  if (firstImage?.url) {
    const responseImage = await fetch(firstImage.url);
    if (!responseImage.ok) {
      const error = `generated_image_fetch_failed_${responseImage.status}`;
      console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_TRANSPARENT_FAILED', true);
      console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_ERROR', error);
      throw new Error(error);
    }

    return saveIllustration(input.discoveryId, Buffer.from(await responseImage.arrayBuffer()));
  }

  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_TRANSPARENT_FAILED', true);
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_ERROR', 'missing_generated_image');
  throw new Error('missing_generated_image');
}

export function fallbackCatIllustration(photoUrl: string): string {
  return photoUrl;
}

function illustrationPrompt(input: CreateCatIllustrationInput): string {
  return [
    'Create a polished fantasy collectible companion illustration of only the cat in the provided reference photo.',
    'Output a transparent PNG cutout: the cat must be isolated on a fully transparent background.',
    'Do not add any background, paper texture, beige square, colored panel, floor, wall, scenery, frame, border, shadow box, text, UI, stars, or card elements.',
    'All pixels outside the cat silhouette must be transparent alpha.',
    'Use the provided photo as the main visual reference and preserve the individual cat identity.',
    `Card style context: ${input.cardStyle}.`,
    `Cat name: ${input.analysis.customName || input.analysis.suggestedName || 'CatDex cat'}.`,
    `Species: ${input.analysis.displaySpecies}.`,
    `Coat color: ${input.analysis.coatColor}. Preserve this exact coat color.`,
    `Coat pattern: ${input.analysis.coatPattern}. Preserve this exact coat pattern and markings.`,
    `Eye color: ${input.analysis.eyeColor}. Preserve this exact eye color.`,
    `Hair length: ${input.analysis.hairLength}. Preserve this exact hair length and fur texture.`,
    'Preserve body shape, facial structure, ear shape, muzzle color, tail shape, paw markings, stripes, patches, and other distinctive visible markings.',
    'Full cat body if possible, centered, clean silhouette, card-ready pose.',
    'No text, no labels, no card frame, no stars, no UI elements.',
  ].join('\n');
}

async function saveIllustration(discoveryId: string, imageBytes: Buffer): Promise<string> {
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_SOURCE', 'ai');
  await savePngArtifact(discoveryId, 'raw-illustrated-cat.png', bufferToArrayBuffer(imageBytes));
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_RAW_SAVED', true);

  const finalImageBytes = await removeBackgroundFromPng(imageBytes);
  const hasAlpha = pngHasAlpha(finalImageBytes);
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_HAS_ALPHA', hasAlpha);
  console.log('CATDEX_GENERATE_CARD_ILLUSTRATION_FINAL_TRANSPARENT', hasAlpha);

  await savePngArtifact(discoveryId, 'illustrated-cat.png', bufferToArrayBuffer(finalImageBytes));
  return publicCardUrl(discoveryId, 'illustrated-cat.png');
}

function pngHasAlpha(imageBytes: Buffer): boolean {
  const pngSignature = '89504e470d0a1a0a';
  if (imageBytes.length < 26 || imageBytes.subarray(0, 8).toString('hex') !== pngSignature) {
    return false;
  }

  const colorType = imageBytes[25];
  return colorType === 4 || colorType === 6;
}

function bufferToArrayBuffer(buffer: Buffer): ArrayBuffer {
  return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength) as ArrayBuffer;
}
