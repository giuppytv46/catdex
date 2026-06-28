# CatDex Release Preparation Foundation

This document tracks the store-readiness foundation for Android and iOS.

CatDex is not ready to publish yet. These notes exist so future release work can happen safely without adding credentials or store-specific secrets to source control.

## App Identity

| Field | Value |
| --- | --- |
| App name | CatDex |
| Android package name | `com.catdex.app` |
| iOS bundle identifier | `com.catdex.app` |
| Version name | `0.1.0` |
| Build number | `1` |

The canonical Flutter version source is `pubspec.yaml`:

```yaml
version: 0.1.0+1
```

Android reads this through `flutter.versionName` and `flutter.versionCode`.
iOS reads this through `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER`.

## Android Release Placeholder

Release signing is intentionally not enabled with real credentials.

Placeholder file:

- `android/release/key.properties.example`

When Android signing is implemented later, create a local `android/key.properties` file or configure CI secrets. Never commit keystores, passwords, or Play Console service account JSON.

## iOS Release Placeholder

iOS signing is intentionally not configured with a production team or provisioning profile.

Placeholder file:

- `ios/Runner/Config/ReleaseConfig.example.xcconfig`

When iOS signing is implemented later, configure the Apple Team ID, bundle capabilities, provisioning profiles, and App Store Connect credentials outside source control.

## Build Scripts

Scripts:

- `scripts/build_android.sh`
- `scripts/build_ios.sh`

The scripts accept optional environment overrides:

```sh
BUILD_NAME=0.1.0 BUILD_NUMBER=1 scripts/build_android.sh
BUILD_NAME=0.1.0 BUILD_NUMBER=1 scripts/build_ios.sh
```

The iOS script uses `--no-codesign` by default so it can prepare a local release artifact without requiring Apple signing credentials.

## Store Credentials

Do not commit:

- Android keystores
- `key.properties`
- Play Console service account JSON
- Apple certificates
- provisioning profiles
- App Store Connect API keys
- AdMob app IDs or ad unit IDs
- purchase product secrets

## Future Release Work

Before publishing, complete the release checklist in `docs/RELEASE_CHECKLIST.md`.
