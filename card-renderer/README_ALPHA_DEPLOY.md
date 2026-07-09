# CatDex Card Renderer Alpha Deployment

This service is the private-alpha Next.js renderer for CatDex collectible cards.
Flutter calls `POST /api/generate-card`; the renderer creates the final card PNG
and returns its URL.

## Architecture Summary

- Framework: Next.js route handlers on Node.js runtime.
- Active card endpoint: `POST /api/generate-card`.
- Health endpoint: `GET /api/health`.
- Final card output: `final-card.png`.
- Local output path: `public/generated/cards/<discoveryId>/final-card.png`.
- Local public URL: `<CARD_RENDERER_PUBLIC_BASE_URL>/generated/cards/<discoveryId>/final-card.png`.
- Optional cloud output: Supabase Storage object `cards/<discoveryId>/final-card.png`.

The final renderer still uses the existing template and layout pipeline. This
deployment pass does not change card visuals.

## Local Development

Install dependencies:

```sh
npm install
```

Run local development:

```sh
npm run dev
```

Run local mock-artwork mode:

```sh
CATDEX_MOCK_AI_ARTWORK=true npm run dev
```

For private alpha, mock artwork is safe by default unless
`CATDEX_MOCK_AI_ARTWORK=false` is explicitly set.

## Production Commands

Build:

```sh
npm run build
```

Start:

```sh
npm run start
```

Most hosts will set `PORT` automatically. Next.js also respects:

```sh
PORT=3000 npm run start
```

## Environment Variables

Required for alpha:

```txt
CATDEX_MOCK_AI_ARTWORK=true
CARD_RENDERER_PUBLIC_BASE_URL=https://your-renderer.example.com
CARD_RENDERER_STORAGE_MODE=local
CARD_RENDERER_ALLOWED_ORIGINS=
```

Supported:

```txt
CATDEX_MOCK_AI_ARTWORK=true|false
CARD_RENDERER_PUBLIC_BASE_URL=https://...
CARD_RENDERER_STORAGE_MODE=local|supabase
CARD_RENDERER_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
CARD_RENDERER_GENERATION_TIMEOUT_MS=120000
PORT=3000
OPENAI_API_KEY=... only when CATDEX_MOCK_AI_ARTWORK=false
OPENAI_IMAGE_MODEL=gpt-image-1.5
REMOVE_BG_API_KEY=... optional, only for real artwork pipeline
```

Supabase Storage mode also requires:

```txt
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<server-only-service-role-key>
SUPABASE_CARD_BUCKET=catdex-cards
```

Never expose `SUPABASE_SERVICE_ROLE_KEY` to Flutter.

## Health Endpoint

```sh
curl https://your-renderer.example.com/api/health
```

Example response:

```json
{
  "ok": true,
  "service": "catdex-card-renderer",
  "mockArtwork": true,
  "storageMode": "local",
  "version": "alpha"
}
```

## Generate Card Endpoint

```sh
curl -X POST https://your-renderer.example.com/api/generate-card \
  -H 'content-type: application/json' \
  -d '{
    "discoveryId": "alpha-test-0001",
    "photoUrl": "https://example.com/cat.png",
    "rarity": "common",
    "displayName": "Mochi",
    "displaySpecies": "Gatto domestico tigrato"
  }'
```

The endpoint validates JSON, required fields, rarity values, and safe
`discoveryId` characters. It rejects concurrent renders for the same
`discoveryId`.

## Storage Modes

### `CARD_RENDERER_STORAGE_MODE=local`

Writes generated files to:

```txt
public/generated/cards/<discoveryId>/
```

This is simple and good for local development or hosts with persistent disks.
It is not safe on serverless/ephemeral filesystems because generated files can
disappear between deploys or restarts.

### `CARD_RENDERER_STORAGE_MODE=supabase`

Writes files locally for the current render and uploads generated artifacts to
Supabase Storage:

```txt
cards/<discoveryId>/final-card.png
cards/<discoveryId>/illustrated-cat.png
cards/<discoveryId>/metadata.json
```

Returned URLs use the Supabase public object URL. For private buckets, add
signed URL support before production.

Supabase setup:

1. Create a bucket, for example `catdex-cards`.
2. For alpha simplicity, make the bucket public or add signed URL support.
3. Set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and
   `SUPABASE_CARD_BUCKET`.
4. Keep the service role key only on the renderer host.

## CORS

Set:

```txt
CARD_RENDERER_ALLOWED_ORIGINS=https://your-admin.example.com
```

Native mobile apps usually do not send browser CORS requests. Browser-based
tools do. In development, if no origins are configured, the renderer echoes the
request origin. In production, configure explicit origins when browser clients
need access.

## Recommended Hosting

Recommended for private alpha: **Render with a persistent disk**.

Why:

- It runs a normal long-lived Node/Next process.
- It supports persistent disk for `public/generated/cards`.
- It avoids serverless execution/time limits that can hurt image rendering.
- It is simple to operate for a small tester group.

Alternative good option: Railway with a volume.

Avoid Vercel for this alpha if using local storage, because generated images
depend on filesystem persistence and rendering can exceed serverless limits.

## Render Deployment Steps

1. Create a new Render Web Service from the repository.
2. Set root directory:

```txt
card-renderer
```

3. Build command:

```sh
npm install && npm run build
```

4. Start command:

```sh
npm run start
```

5. Add environment variables:

```txt
CATDEX_MOCK_AI_ARTWORK=true
CARD_RENDERER_PUBLIC_BASE_URL=https://<your-render-service>.onrender.com
CARD_RENDERER_STORAGE_MODE=local
CARD_RENDERER_ALLOWED_ORIGINS=
```

6. Add a persistent disk mounted so `card-renderer/public/generated/cards` is
   preserved, or switch to `CARD_RENDERER_STORAGE_MODE=supabase`.
7. Verify:

```sh
curl https://<your-render-service>.onrender.com/api/health
```

8. Point Flutter's card generation URL to:

```txt
https://<your-render-service>.onrender.com/api/generate-card
```

## Rollback Notes

- Revert Flutter to the previous local renderer URL if cloud generation fails.
- Keep `CATDEX_MOCK_AI_ARTWORK=true` during alpha to avoid OpenAI image billing
  and quota failures.
- If generated images disappear, the host disk is ephemeral; add persistent disk
  or switch to Supabase Storage.
