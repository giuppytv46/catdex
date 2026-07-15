import { mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { isSupabaseStorageConfigured, storageMode } from './config';
import type { CatAnalysisJson, StoredGeneratedCard } from './types';

const generatedRoot = path.join(process.cwd(), 'public/generated/cards');

export function publicCardUrl(discoveryId: string, fileName: string, publicBaseUrl?: string): string {
  if (storageMode() === 'supabase') {
    return supabasePublicUrl(discoveryId, fileName);
  }

  const relativePath = `/generated/cards/${discoveryId}/${fileName}`;
  return publicBaseUrl ? `${publicBaseUrl}${relativePath}` : relativePath;
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
  const buffer = Buffer.from(JSON.stringify(data, null, 2));
  await writeFile(filePath, buffer);
  await uploadArtifactToSupabaseIfEnabled(discoveryId, fileName, buffer, 'application/json');
  return filePath;
}

export async function savePngArtifact(discoveryId: string, fileName: string, data: ArrayBuffer): Promise<string> {
  const directory = await ensureDiscoveryStorage(discoveryId);
  const filePath = path.join(directory, fileName);
  const buffer = Buffer.from(data);
  await writeFile(filePath, buffer);
  await uploadArtifactToSupabaseIfEnabled(discoveryId, fileName, buffer);
  return filePath;
}

export async function saveIllustrationReference(discoveryId: string, imageUrl: string): Promise<{ path: string; url: string }> {
  const referencePath = await saveJsonArtifact(discoveryId, 'illustrated-cat.json', { imageUrl });
  return { path: referencePath, url: imageUrl };
}

export async function saveOriginalPhotoReference(discoveryId: string, photoUrl: string): Promise<string> {
  return saveJsonArtifact(discoveryId, 'original-photo.json', { photoUrl });
}

export async function saveImageFromUrl(
  discoveryId: string,
  fileName: string,
  imageUrl: string,
  publicBaseUrl?: string,
): Promise<{ path: string; url: string; contentType: string } | undefined> {
  try {
    const directory = await ensureDiscoveryStorage(discoveryId);
    const filePath = path.join(directory, fileName);
    const image = await readImageBytes(imageUrl);
    await writeFile(filePath, image.data);
    await uploadArtifactToSupabaseIfEnabled(discoveryId, fileName, image.data, image.contentType);

    return {
      path: filePath,
      url: publicCardUrl(discoveryId, fileName, publicBaseUrl),
      contentType: image.contentType,
    };
  } catch {
    return undefined;
  }
}

async function uploadArtifactToSupabaseIfEnabled(
  discoveryId: string,
  fileName: string,
  data: Buffer,
  contentType = 'image/png',
): Promise<void> {
  if (storageMode() !== 'supabase') {
    return;
  }

  if (!isSupabaseStorageConfigured()) {
    throw new Error('supabase_storage_not_configured');
  }

  const supabaseUrl = process.env.SUPABASE_URL!.replace(/\/+$/, '');
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  const bucket = process.env.SUPABASE_CARD_BUCKET!;
  const objectPath = supabaseObjectPath(discoveryId, fileName);
  const response = await fetch(
    `${supabaseUrl}/storage/v1/object/${encodeURIComponent(bucket)}/${objectPath}`,
    {
      method: 'PUT',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'content-type': contentType,
        'x-upsert': 'true',
      },
      body: new Uint8Array(data),
    },
  );

  if (!response.ok) {
    throw new Error(`supabase_storage_upload_failed_${response.status}`);
  }
}

function supabasePublicUrl(discoveryId: string, fileName: string): string {
  const supabaseUrl = process.env.SUPABASE_URL?.replace(/\/+$/, '');
  const bucket = process.env.SUPABASE_CARD_BUCKET;

  if (!supabaseUrl || !bucket) {
    return `/generated/cards/${discoveryId}/${fileName}`;
  }

  return `${supabaseUrl}/storage/v1/object/public/${encodeURIComponent(bucket)}/${supabaseObjectPath(
    discoveryId,
    fileName,
  )}`;
}

function supabaseObjectPath(discoveryId: string, fileName: string): string {
  return `cards/${encodeURIComponent(discoveryId)}/${encodeURIComponent(fileName)}`;
}

export async function saveAnalysis(discoveryId: string, analysis: CatAnalysisJson): Promise<string> {
  return saveJsonArtifact(discoveryId, 'analysis.json', analysis);
}

export async function saveMetadata(metadata: StoredGeneratedCard): Promise<string> {
  return saveJsonArtifact(metadata.discoveryId, 'metadata.json', metadata);
}

export async function readStoredGeneratedCard(discoveryId: string): Promise<StoredGeneratedCard | undefined> {
  try {
    const filePath = path.join(discoveryStorageDirectory(discoveryId), 'metadata.json');
    const data = JSON.parse(await readFile(filePath, 'utf8')) as StoredGeneratedCard;
    if (!data.finalCardUrl || !data.illustratedCatUrl || !data.selectedTemplateKey) {
      return undefined;
    }
    return data;
  } catch {
    return undefined;
  }
}

export async function hasFinalCardArtifact(discoveryId: string): Promise<boolean> {
  try {
    const filePath = path.join(discoveryStorageDirectory(discoveryId), 'final-card.png');
    const info = await stat(filePath);
    return info.isFile() && info.size > 0;
  } catch {
    return false;
  }
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
