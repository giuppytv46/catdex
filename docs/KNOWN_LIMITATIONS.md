# CatDex Known Limitations

This document lists expected limitations for the current beta-preparation foundation.

## Local Persistence

Guest/local discoveries are in-memory for the current app session. They are not durable across app restarts yet.

## Cloud Sync

Supabase cloud repository paths exist, but the app still supports guest mode by default. Cloud sync depends on a configured Supabase project, valid schema, storage bucket setup, and an authenticated user.

## Pending Sync

The pending-sync queue is a foundation only. Full offline retry orchestration is not implemented yet.

## AI

The app can use fake/local analysis in guest mode. Real AI is prepared through a Supabase Edge Function path, but production AI quality, monitoring, rate limiting, and abuse controls still require hardening before public release.

## Photos

Guest mode uses local file paths. Cloud mode can upload to private Supabase Storage when configured and signed in. Public photo URLs are intentionally not exposed by default.

## Location

Location is optional. If permission is denied or reverse geocoding fails, CatDex keeps the discovery flow usable with friendly fallback messages.

## Monetization

Premium plans, scan limits, purchase repository interfaces, and ad placement interfaces are placeholders. No real purchases, billing, AdMob keys, or real ads are enabled.

## Store Readiness

Release documents and build scripts exist, but production app icons, final splash assets, signing credentials, legal privacy copy, support URLs, and store screenshots still need final work.

## UI Tests

Most UI interaction tests are intentionally postponed until Beta UI stabilizes. Current UI tests should remain smoke-level only.

## Localization

Localization infrastructure exists, but many newer feature strings may still need a full localization pass before public release.

## Analytics and Crash Reporting

The design documents require analytics and crash reporting in the long term, but production analytics and crash reporting are not fully enabled yet.
