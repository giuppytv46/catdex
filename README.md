# CatDex

CatDex is a Flutter mobile game for a relaxed cat discovery and collection experience. The app supports a guest/local mode by default and can connect to Supabase for authentication, AI Edge Functions, and cloud repository access when configured.

## Tech Stack

- Flutter stable channel
- Dart 3
- Riverpod for state management
- GoRouter for navigation
- Flutter Lints and Very Good Analysis for code quality
- GitHub Actions for continuous integration

## Requirements

Install Flutter from the stable channel and keep it current:

```sh
flutter channel stable
flutter upgrade
flutter doctor
```

## Setup

```sh
flutter pub get
flutter run
```

## Supabase Setup

CatDex starts in guest mode when Supabase values are missing. Guest mode keeps local capture, fake AI, in-memory saves, XP updates, Home refresh, and CatDex unlocks working without a backend.

To connect a real Supabase project locally:

```sh
cp .env.example .env
```

Edit `.env`:

```text
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

The `.env` file is gitignored. Do not commit real keys. The anon key is public by design, but it still belongs in local configuration, not source files.

Run with either the built-in `.env` loader:

```sh
flutter run
```

or with Flutter defines:

```sh
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

For CI or release builds, prefer environment-specific defines or a secure pipeline secret store. Server-only values such as `OPENAI_API_KEY` must only be configured in Supabase Edge Function secrets and must never be passed to Flutter.

### Connection Checks

The app exposes Supabase health checks behind providers:

- `supabaseConnectionHealthProvider` verifies local-vs-cloud mode, auth client readiness, and master data reachability.
- `cloudRepositoryVerificationProvider` verifies that logged-in cloud mode can read master data and read/write profile progress through repositories.

These checks are repository/service level checks; widgets do not call Supabase directly.

### AI Edge Function

Real AI analysis is handled by the Supabase Edge Function
`analyze_cat_photo`. Deployment steps are documented in
[docs/AI_DEPLOYMENT.md](docs/AI_DEPLOYMENT.md).

Flutter never stores OpenAI keys. If Supabase is not configured, CatDex falls
back to the local fake analyzer for guest/local mode.

### Storage

Cloud-mode photo upload uses a private Supabase Storage bucket named `cat-photos`.
See [backend/supabase/STORAGE.md](backend/supabase/STORAGE.md) for bucket setup, path format, and policy guidance.

## Quality Checks

```sh
flutter analyze
flutter test
```

## Current Sprint Status

CatDex is in the Sprint 21 Beta QA + Stability Pass foundation.

Stable foundations currently include:

- Production Flutter structure with Riverpod and GoRouter.
- Guest/local mode by default.
- In-memory CatDex game core and discovery save flow.
- Fake/local AI analysis fallback.
- Supabase auth, Edge Function, database, storage, and repository switching foundations.
- Premium and ads placeholder architecture with no real payments or real ads enabled.
- Release preparation docs and build helper scripts.

Known beta limitations are tracked in [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).
Beta QA coverage is tracked in [docs/BETA_QA_CHECKLIST.md](docs/BETA_QA_CHECKLIST.md).

## Release Preparation

Sprint 20 adds store-readiness foundations only. CatDex is not published from this repository, and no store credentials are committed.

Release references:

- [Release preparation](docs/RELEASE_PREPARATION.md)
- [Permissions](docs/PERMISSIONS.md)
- [Privacy policy draft](docs/PRIVACY_POLICY_DRAFT.md)
- [Store listing draft](docs/STORE_LISTING_DRAFT.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [App icon placeholder](docs/APP_ICON_PLACEHOLDER.md)
- [Splash screen placeholder](docs/SPLASH_SCREEN_PLACEHOLDER.md)

Build helpers:

```sh
scripts/build_android.sh
scripts/build_ios.sh
```

## Project Structure

```text
lib/
  core/
    config/
    localization/
  features/
    app_shell/
    capture/
    catdex/
    error/
    friends/
    home/
    login/
    offline/
    onboarding/
    profile/
    settings/
    splash/
  routing/
  services/
  shared/
  theme/
  widgets/
  main.dart
```

## Architecture

CatDex follows the Clean Architecture direction defined in `docs/03_ARCHITECTURE.md`.

- `core` contains application-wide configuration and localization foundations.
- `features` contains isolated placeholder modules for the app shell and pages.
- `routing` owns navigation setup.
- `services` is reserved for infrastructure integrations added in later tasks.
- `theme` contains CatDex light and dark visual foundations.
- `widgets` contains reusable UI primitives.

Widgets do not call backend services directly. Future Supabase, Firebase, AI, analytics, and storage integrations should be introduced behind repositories or services and injected through Riverpod providers.

## Sprint 2 Shell

The app shell includes:

- Splash, Onboarding, Login, Settings, Offline, Global Error, and Unknown Route pages.
- Five-tab bottom navigation for Home, CatDex, Capture, Friends, and Profile.
- A centered, larger Capture tab with CatDex green-to-purple styling.
- GoRouter navigation with animated route transitions.
