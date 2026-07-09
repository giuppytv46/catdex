# CatDex Card Renderer

Free PNG card rendering endpoint built with Next.js route handlers and `@vercel/og`.

## Run locally

```sh
npm install
npm run dev
```

Then call:

```sh
curl -X POST http://localhost:3000/api/render-card \
  -H 'content-type: application/json' \
  -o card.png \
  -d '{
    "cardNumber": "#0008",
    "catName": "LUNETTA",
    "species": "Gatto domestico bicolore",
    "rarity": "common",
    "starCount": 1,
    "template": "common",
    "catImageUrl": "https://example.com/cat.png"
  }'
```

The response is a `1500 x 2100` PNG. The card background comes from
`public/cards/catdex_template_v2.png`; text and stars are rendered as
deterministic layout elements.

## Visual layout lab

Open:

```txt
http://localhost:3000/lab
```

Use the controls or drag the card overlays directly. Changes are saved in
browser localStorage under `catdex_card_renderer_layout`. The **Copy layout
JSON** button copies a `CARD_LAYOUT` export and also prints it in the browser
console with `CATDEX_RENDERER_LAYOUT_EXPORT`.

## Automated card pipeline

Call:

```sh
curl -X POST http://localhost:3000/api/generate-card \
  -H 'content-type: application/json' \
  -d '{
    "discoveryId": "0008",
    "photoUrl": "https://example.com/cat.png",
    "rarity": "common"
  }'
```

The pipeline keeps final composition deterministic. AI-facing services may
produce structured analysis, plain text, or an illustrated cat image, but the
final PNG is always composed from `template.png`, `layout.json`, SVG stars, and
local fonts by the renderer.

Template folders live under:

```txt
assets/cards/templates/default/<rarity>/
assets/cards/templates/events/<eventName>/<rarity>/
```

Each template folder contains `template.png` and `layout.json`.

## Mock AI artwork mode

Use mock mode when developing without OpenAI image-generation calls:

```sh
CATDEX_MOCK_AI_ARTWORK=true npm run dev
```

In this mode `/api/generate-card` skips OpenAI and remove.bg, then renders with
`assets/cards/mock/mock-cat-artwork.png` instead of the original photo.
