# Supabase Storage

## cat-photos

CatDex stores uploaded cat photos in the `cat-photos` bucket.

- Bucket name: `cat-photos`
- Access: private
- Public URLs: disabled by default
- Path format: `{user_id}/{timestamp}.{extension}`
- Used by: cloud-mode capture/import flow before AI analysis

Create the bucket in Supabase Dashboard or CLI and keep it private. Flutter
stores only the returned storage path/reference. Signed URLs can be added later
only where a short-lived preview URL is explicitly needed.

Recommended bucket policies:

- Authenticated users can upload objects under their own `{user_id}/` prefix.
- Authenticated users can read objects under their own `{user_id}/` prefix.
- Public read is disabled.
- Guests do not upload to storage; they keep using local file paths.
