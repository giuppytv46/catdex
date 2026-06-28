# CatDex AI Edge Function Deployment

This guide prepares and deploys the `analyze_cat_photo` Supabase Edge Function.

Do not commit real secrets. `OPENAI_API_KEY` and `SUPABASE_SERVICE_ROLE_KEY` must live only in Supabase secrets or local shell environment variables.

## 1. Install Supabase CLI

macOS with Homebrew:

```sh
brew install supabase/tap/supabase
```

Other platforms:

```sh
npm install -g supabase
```

Verify:

```sh
supabase --version
```

## 2. Log In

```sh
supabase login
```

This opens a browser and stores a local CLI token. Do not commit Supabase CLI config containing credentials.

## 3. Link the Project

Find the Supabase project ref in the Supabase dashboard URL:

```text
https://supabase.com/dashboard/project/<PROJECT_REF>
```

Link from the repository root:

```sh
supabase link --project-ref <PROJECT_REF>
```

## 4. Set Secrets

Set the OpenAI key only as a Supabase secret:

```sh
supabase secrets set OPENAI_API_KEY=your-openai-key
```

For private Storage `photoReference` analysis, also set:

```sh
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

The Flutter app must never receive `OPENAI_API_KEY` or `SUPABASE_SERVICE_ROLE_KEY`.

## 5. Deploy the Function

Use the helper script:

```sh
scripts/deploy_ai_function.sh
```

Or deploy manually:

```sh
supabase functions deploy analyze_cat_photo
```

## 6. Test Locally

Serve the function locally:

```sh
supabase functions serve analyze_cat_photo --env-file .env
```

In another terminal, test with a public image URL:

```sh
SUPABASE_FUNCTION_URL=http://127.0.0.1:54321/functions/v1/analyze_cat_photo \
SUPABASE_ANON_KEY=local-anon-key \
scripts/test_ai_function.sh https://example.com/cat.jpg
```

If `OPENAI_API_KEY` is missing, the function should return the safe mock fallback.

## 7. Test Remotely

Set environment variables in your shell:

```sh
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your-public-anon-key
```

Run:

```sh
scripts/test_ai_function.sh https://example.com/cat.jpg
```

The script calls:

```text
$SUPABASE_URL/functions/v1/analyze_cat_photo
```

## Expected Response Shape

The function returns JSON compatible with Flutter:

```json
{
  "breed": "domestic_shorthair_cat",
  "confidence": 0.76,
  "candidates": [],
  "coatColor": "Brown",
  "coatPattern": "Tabby",
  "eyeColor": "Green",
  "hairLength": "Short",
  "estimatedAge": "adulto",
  "traits": [],
  "personality": "curious",
  "rarity": "common",
  "variant": "normal",
  "story": "Testo in italiano.",
  "funFact": "Testo in italiano.",
  "safetyStatus": "safe"
}
```

## Safety Checks

- No cat visible: returns a no-cat error.
- Inappropriate image: returns an invalid-image error.
- Low confidence: falls back to Domestic Short Hair or European Shorthair.
- `event_edition`: only allowed with an explicit active event.
- Missing `OPENAI_API_KEY`: returns safe mock output.

## Flutter Fallback

Flutter uses the backend repository only when Supabase is configured. If Supabase is not configured, CatDex keeps using the local fake analyzer so guest/local mode keeps working.
