import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { CatAnalysisJson, StoredGeneratedCard } from './types';

const generatedRoot = path.join(process.cwd(), 'public/generated/cards');

export function publicCardUrl(discoveryId: string, fileName: string): string {
  return `/generated/cards/${discoveryId}/${fileName}`;
}

export function discoveryStorageDirectory(discoveryId: string): string {
  return path.join(generatedRoot, discoveryId);
}

export async function ensureDiscoveryStorage(discoveryId: string): Promise<string> {
  const directory = discoveryStorageDirectory(discoveryId);
  await mkdir(directory, { recursive: true });
  return directory;
}

export async function saveJsonArtifact(discoveryId: string, fileName: string, data: unknown): Promise<string> {
  const directory = await ensureDiscoveryStorage(discoveryId);
  const filePath = path.join(directory, fileName);
  await writeFile(filePath, JSON.stringify(data, null, 2));
  return filePath;
}

export async function savePngArtifact(discoveryId: string, fileName: string, data: ArrayBuffer): Promise<string> {
  const directory = await ensureDiscoveryStorage(discoveryId);
  const filePath = path.join(directory, fileName);
  await writeFile(filePath, Buffer.from(data));
  return filePath;
}

export async function saveIllustrationReference(discoveryId: string, imageUrl: string): Promise<{ path: string; url: string }> {
  const directory = await ensureDiscoveryStorage(discoveryId);
  const referencePath = path.join(directory, 'illustrated-cat.json');
  await writeFile(referencePath, JSON.stringify({ imageUrl }, null, 2));
  return { path: referencePath, url: imageUrl };
}

export async function saveOriginalPhotoReference(discoveryId: string, photoUrl: string): Promise<string> {
  return saveJsonArtifact(discoveryId, 'original-photo.json', { photoUrl });
}

export async function saveImageFromUrl(
  discoveryId: string,
  fileName: string,
  imageUrl: string,
): Promise<{ path: string; url: string; contentType: string } | undefined> {
  try {
    const directory = await ensureDiscoveryStorage(discoveryId);
    const filePath = path.join(directory, fileName);
    const image = await readImageBytes(imageUrl);
    await writeFile(filePath, image.data);

    return {
      path: filePath,
      url: publicCardUrl(discoveryId, fileName),
      contentType: image.contentType,
    };
  } catch {
    return undefined;
  }
}

export async function saveAnalysis(discoveryId: string, analysis: CatAnalysisJson): Promise<string> {
  return saveJsonArtifact(discoveryId, 'analysis.json', analysis);
}

export async function saveMetadata(metadata: StoredGeneratedCard): Promise<string> {
  return saveJsonArtifact(metadata.discoveryId, 'metadata.json', metadata);
}

export async function fileToDataUrl(filePath: string, contentType = 'image/png'): Promise<string> {
  const data = await readFile(filePath);
  return `data:${contentType};base64,${data.toString('base64')}`;
}

async function readImageBytes(imageUrl: string): Promise<{ data: Buffer; contentType: string }> {
  if (imageUrl.startsWith('data:')) {
    const match = imageUrl.match(/^data:([^;]+);base64,(.+)$/);
    if (!match) {
      throw new Error('Unsupported data URL image.');
    }

    return {
      contentType: match[1],
      data: Buffer.from(match[2], 'base64'),
    };
  }

  if (imageUrl.startsWith('/')) {
    const filePath = path.join(process.cwd(), 'public', imageUrl);
    return {
      contentType: contentTypeFromPath(filePath),
      data: await readFile(filePath),
    };
  }

  const response = await fetch(imageUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status}`);
  }

  return {
    contentType: response.headers.get('content-type') ?? contentTypeFromPath(imageUrl),
    data: Buffer.from(await response.arrayBuffer()),
  };
}

function contentTypeFromPath(filePath: string): string {
  const extension = path.extname(filePath).toLowerCase();
  if (extension === '.jpg' || extension === '.jpeg') {
    return 'image/jpeg';
  }
  if (extension === '.webp') {
    return 'image/webp';
  }

  return 'image/png';
}
