# CatDex

CatDex is a Flutter mobile game foundation for a relaxed cat discovery and collection experience. This repository currently contains the production-ready foundation and Sprint 2 application shell.

No gameplay, authentication, Supabase, Firebase, AI, camera, GPS, maps, monetization, or collection logic is implemented yet.

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

## Quality Checks

```sh
flutter analyze
flutter test
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
