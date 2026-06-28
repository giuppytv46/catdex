#!/usr/bin/env bash
set -euo pipefail

IMAGE_URL="${1:-}"

if [[ -z "$IMAGE_URL" ]]; then
  echo "Usage: scripts/test_ai_function.sh <image_url>"
  exit 1
fi

FUNCTION_URL="${SUPABASE_FUNCTION_URL:-}"
if [[ -z "$FUNCTION_URL" ]]; then
  if [[ -z "${SUPABASE_URL:-}" ]]; then
    echo "Set SUPABASE_URL or SUPABASE_FUNCTION_URL before running this script."
    exit 1
  fi
  FUNCTION_URL="${SUPABASE_URL%/}/functions/v1/analyze_cat_photo"
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Set SUPABASE_ANON_KEY before running this script."
  exit 1
fi

echo "Testing CatDex AI function at ${FUNCTION_URL}"
curl --fail --show-error --silent \
  --request POST "$FUNCTION_URL" \
  --header "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  --header "apikey: ${SUPABASE_ANON_KEY}" \
  --header "Content-Type: application/json" \
  --data "{\"image_url\":\"${IMAGE_URL}\",\"locale\":\"it\"}"
