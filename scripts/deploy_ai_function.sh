#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FUNCTION_NAME="analyze_cat_photo"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is required. Install it first: https://supabase.com/docs/guides/cli"
  exit 1
fi

echo "Deploying Supabase Edge Function: ${FUNCTION_NAME}"
echo "Secrets must be configured separately with supabase secrets set."
supabase functions deploy "$FUNCTION_NAME"
