import type { NextRequest } from 'next/server';

const maxJsonPayloadBytes = 128 * 1024;
const safeDiscoveryIdPattern = /^[a-zA-Z0-9_-]{1,96}$/;

export function assertSafeJsonPayloadSize(request: NextRequest): void {
  const contentLength = Number(request.headers.get('content-length') ?? '0');
  if (Number.isFinite(contentLength) && contentLength > maxJsonPayloadBytes) {
    throw new RequestSafetyError('PAYLOAD_TOO_LARGE', 'Request body is too large.', 413);
  }
}

export function assertSafeDiscoveryId(discoveryId: string): void {
  if (!safeDiscoveryIdPattern.test(discoveryId)) {
    throw new RequestSafetyError('INVALID_DISCOVERY_ID', 'discoveryId contains unsupported characters.', 400);
  }
}

export function withTimeout<T>(promise: Promise<T>, timeoutMs: number, errorCode: string): Promise<T> {
  let timeout: NodeJS.Timeout | undefined;
  const timeoutPromise = new Promise<T>((_, reject) => {
    timeout = setTimeout(() => {
      reject(new RequestSafetyError(errorCode, 'Card generation timed out.', 504));
    }, timeoutMs);
  });

  return Promise.race([promise, timeoutPromise]).finally(() => {
    if (timeout) {
      clearTimeout(timeout);
    }
  });
}

export class RequestSafetyError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number,
  ) {
    super(message);
    this.name = 'RequestSafetyError';
  }
}
