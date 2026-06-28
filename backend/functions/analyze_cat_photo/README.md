# analyze_cat_photo

Supabase Edge Function scaffold for CatDex photo analysis.

Input:

```json
{
  "image_url": "https://example.com/cat.jpg",
  "base64_image": "data:image/jpeg;base64,...",
  "user_id": "optional-user-id",
  "locale": "en",
  "metadata": {
    "source": "gallery",
    "sizeBytes": 1024,
    "capturedAt": "2026-06-28T12:00:00.000Z"
  }
}
```

Output is shaped to match Flutter `CatAnalysisResult` parsing:

- `breed`
- `confidence`
- `candidates`
- `coatColor`
- `coatPattern`
- `eyeColor`
- `hairLength`
- `traits`
- `rarity`
- `variant`
- `personality`
- `story`
- `analyzedAt`
- `safetyStatus`

If `OPENAI_API_KEY` is missing, the function returns a safe mock result. If the
OpenAI response is malformed, the function maps the result to a safe Domestic
Cat fallback with low confidence.

`OPENAI_API_KEY` belongs only in the Supabase Edge Function environment. The
Flutter app must never receive or store it.
