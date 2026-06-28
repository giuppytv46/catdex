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
- `estimatedAge`
- `traits`
- `rarity`
- `variant`
- `personality`
- `story`
- `funFact`
- `analyzedAt`
- `safetyStatus`

If `OPENAI_API_KEY` is missing, the function returns a safe mock result. If the
OpenAI response is malformed, the function maps the result to a safe Domestic
Cat fallback with low confidence.

Realism rules:

- Confidence below 80% is mapped to `domestic_shorthair_cat` or
  `european_shorthair`.
- Rare breed ids are accepted only with high confidence.
- `legendary` rarity requires extremely high confidence.
- `event_edition` is only allowed when an active event is explicitly passed.
- Story, fun fact, trait names, and trait values are returned in Italian.

`OPENAI_API_KEY` belongs only in the Supabase Edge Function environment. The
Flutter app must never receive or store it.

For private Supabase Storage photo references, configure server-side
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the Edge Function environment
so the function can create a short-lived signed URL. These values must never be
sent to Flutter.
