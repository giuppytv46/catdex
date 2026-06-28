# analyze_cat_photo

Supabase Edge Function scaffold for CatDex photo analysis.

Input:

```json
{
  "photoReference": "storage/path/or/local-reference.jpg",
  "metadata": {
    "source": "gallery",
    "sizeBytes": 1024,
    "capturedAt": "2026-06-28T12:00:00.000Z"
  }
}
```

Output is shaped to match Flutter `CatAnalysisResult` parsing:

- `primaryBreed`
- `breedCandidates`
- `visualTraits`
- `confidence`
- `rarity`
- `variantId`
- `personality`
- `story`
- `analyzedAt`

`OPENAI_API_KEY` belongs only in the Supabase Edge Function environment. The
Flutter app must never receive or store it.
