# CatDex Release Checklist

Use this checklist before any Android or iOS store submission.

## App Identity

- [ ] Confirm app name: CatDex.
- [ ] Confirm Android package name: `com.catdex.app`.
- [ ] Confirm iOS bundle identifier: `com.catdex.app`.
- [ ] Confirm version name and build number in `pubspec.yaml`.
- [ ] Confirm app display name on Android and iOS.

## Code Quality

- [ ] Run `flutter pub get`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Confirm no TODO/FIXME markers remain in release code.
- [ ] Confirm no secrets are committed.

## Android

- [ ] Configure release signing outside source control.
- [ ] Confirm min SDK and target SDK.
- [ ] Build Android App Bundle with `scripts/build_android.sh`.
- [ ] Verify app icon assets.
- [ ] Verify splash screen.
- [ ] Verify permissions in Android manifest.
- [ ] Review Play Console privacy and data safety answers.

## iOS

- [ ] Configure Apple Team ID outside source control.
- [ ] Configure provisioning profiles outside source control.
- [ ] Build iOS release artifact with `scripts/build_ios.sh`.
- [ ] Verify app icon assets.
- [ ] Verify splash screen.
- [ ] Verify permission usage descriptions in `Info.plist`.
- [ ] Review App Store privacy nutrition labels.

## Privacy

- [ ] Finalize privacy policy with legal review.
- [ ] Add support contact.
- [ ] Add data deletion instructions.
- [ ] Document photo handling.
- [ ] Document optional location handling.
- [ ] Document account handling.
- [ ] Document AI processing.

## Store Listing

- [ ] Finalize short description.
- [ ] Finalize full description.
- [ ] Prepare screenshots.
- [ ] Prepare feature graphic or promotional artwork where required.
- [ ] Add support URL.
- [ ] Add marketing URL.
- [ ] Confirm age rating.

## Monetization

- [ ] Confirm no real payments are enabled unless products are configured.
- [ ] Confirm no real ads are enabled unless placements and consent flow are configured.
- [ ] Confirm premium copy matches actual functionality.

## Final Manual QA

- [ ] Launch app in guest mode.
- [ ] Select or capture a photo.
- [ ] Complete fake/local analysis flow.
- [ ] Save a discovery locally.
- [ ] Verify Home updates.
- [ ] Verify CatDex unlocks update.
- [ ] Verify login flow in configured cloud mode.
- [ ] Verify cloud repository read/write in configured cloud mode.
