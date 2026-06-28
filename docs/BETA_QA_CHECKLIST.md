# CatDex Beta QA Checklist

Use this checklist before each beta build. It focuses on stability, guest/local mode, cloud readiness, and avoiding fragile manual assumptions.

## Navigation

- [ ] App launches to Splash without crashing.
- [ ] Home tab opens from app shell.
- [ ] CatDex tab opens from app shell.
- [ ] Capture tab opens from centered action.
- [ ] Friends tab opens from app shell.
- [ ] Profile tab opens from app shell.
- [ ] Settings route opens.
- [ ] Premium route opens from Settings.
- [ ] Unknown routes show the Page Not Found fallback.
- [ ] Analysis route shows the global error fallback when required route data is missing.
- [ ] Discovery Reveal route shows the global error fallback when required route data is missing.

## Guest / Local Mode

- [ ] App starts when `.env` is missing.
- [ ] Profile clearly shows Guest / Local Mode.
- [ ] Capture and import remain available in guest mode.
- [ ] Fake/local AI analysis remains available in guest mode.
- [ ] Save to CatDex works locally in guest mode.
- [ ] Home recent discoveries update during the app session.
- [ ] CatDex collection unlocks update during the app session.

## Supabase Mode

- [ ] App starts when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are configured.
- [ ] Login screen shows friendly validation errors.
- [ ] Email login can connect to Supabase in a configured project.
- [ ] Profile shows signed-in user email.
- [ ] Cloud repository verification can read/write expected data for signed-in users.
- [ ] App falls back gracefully when Supabase is unavailable.

## Capture, Upload, Analysis

- [ ] Camera permission denial shows a friendly message.
- [ ] Gallery permission denial shows a friendly message.
- [ ] Invalid file type is rejected.
- [ ] Empty or missing file is rejected.
- [ ] Files over 10MB are rejected.
- [ ] Guest mode does not upload photos.
- [ ] Cloud mode uploads to private storage when signed in.
- [ ] Upload failure shows a friendly retryable state.
- [ ] Fake AI path still works without Supabase.
- [ ] Backend AI path maps timeout, network, invalid image, no-cat, and malformed responses.

## Location

- [ ] Location permission denial shows "Location unavailable".
- [ ] Disabled location services show a friendly error.
- [ ] Reverse geocode failure keeps coordinates only.
- [ ] Capture screen can continue without location.

## Discovery Save

- [ ] Result screen shows saving state.
- [ ] Result screen shows saved state.
- [ ] Result screen shows failed state and retry action.
- [ ] Guest save writes to in-memory repository.
- [ ] Logged-in cloud save writes through Supabase repository.
- [ ] Failed cloud save keeps a local pending-sync foundation item where supported.

## UI Stability

- [ ] Home dashboard does not overflow on small phones.
- [ ] CatDex grid does not overflow on small phones.
- [ ] Discovery Reveal animation completes without layout overflow.
- [ ] Text remains readable in light mode.
- [ ] Text remains readable in dark mode.
- [ ] Large text settings do not break core flows.
- [ ] Loading, empty, error, and offline states are understandable.

## Tests

- [ ] Keep domain tests.
- [ ] Keep repository tests.
- [ ] Keep calculator tests.
- [ ] Keep only smoke-level UI tests until Beta UI stabilizes.
- [ ] Remove or simplify tests that depend on seed ordering.
- [ ] Remove or simplify tests that depend on private widget tree details.

## Release Safety

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Confirm no secrets are committed.
- [ ] Confirm no real payments are enabled.
- [ ] Confirm no real ads are enabled.
- [ ] Confirm no real store credentials are committed.
