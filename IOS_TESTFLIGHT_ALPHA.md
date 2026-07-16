# CatDex iOS TestFlight Alpha

Private alpha target:

- App version: `0.1.0`
- Build number: `1`
- Bundle ID: `com.giuppy.catdex`
- Renderer endpoint: `https://catdex-card-renderer-alpha.onrender.com/api/generate-card`
- Ads: enabled with test IDs through `SHOW_ADS=true`
- Monetization debug UI: hidden with `SHOW_MONETIZATION_DEBUG=false`

## Build Command

Recommended command:

```sh
./scripts/build_ios.sh
```

Equivalent explicit command:

```sh
flutter build ipa \
  --release \
  --build-name=0.1.0 \
  --build-number=1 \
  --dart-define=CARD_GENERATION_API_URL=https://catdex-card-renderer-alpha.onrender.com/api/generate-card \
  --dart-define=SHOW_MONETIZATION_DEBUG=false \
  --dart-define=SHOW_ADS=true
```

If your local signing is not ready, use the script default `--no-codesign`.
For a TestFlight upload, use Apple signing from Xcode or pass a signing-ready
configuration.

Do not put service-role keys or private backend secrets in Dart defines. The iOS
app may contain public client configuration such as public Supabase URL and anon
key, but never service-role credentials.

## Xcode Archive Procedure

1. Open:

```sh
open ios/Runner.xcworkspace
```

2. Select the `Runner` scheme.
3. Select `Any iOS Device (arm64)` or a connected device.
4. Confirm signing:
   - Bundle Identifier: `com.giuppy.catdex`
   - Signing: Automatic or the selected Apple Developer team
   - Version: `0.1.0`
   - Build: `1`
5. Product > Archive.
6. In Organizer, choose Distribute App.
7. Select App Store Connect.
8. Upload to TestFlight.

## Bundle ID

Current iOS app Bundle ID:

```txt
com.giuppy.catdex
```

RunnerTests uses:

```txt
com.giuppy.catdex.RunnerTests
```

## Version and Build Increment Rules

- Marketing version follows semantic alpha versioning: `0.1.0`, `0.1.1`, etc.
- Build number must increase for every TestFlight upload.
- Next alpha rebuild should become `0.1.0+2` if the app version stays the same.
- Update `pubspec.yaml` and the build command/script values together.

## Required iOS Permissions

`Info.plist` includes:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

Localized permission text is provided in:

- `ios/Runner/en.lproj/InfoPlist.strings`
- `ios/Runner/it.lproj/InfoPlist.strings`

The camera permission is used only when the tester chooses to take a cat photo.
Photo library read permission is used only when importing a cat photo. Photo
library add permission is used only when saving media to the library.

## TestFlight Upload Steps

1. Build/archive with the release configuration.
2. Upload from Xcode Organizer or Transporter.
3. Wait for App Store Connect processing.
4. Add the build to the private alpha TestFlight group.
5. Add tester notes:
   - This is a private alpha.
   - Test cat analysis, manual edit, save to CatDex, and card generation.
   - Report bugs with a screenshot and the action being performed.

## Rollback Instructions

If the alpha build has a critical issue:

1. Disable the build in TestFlight.
2. Re-enable the previous stable build for testers.
3. If card generation is the issue, restore the previous
   `CARD_GENERATION_API_URL` in the next build.
4. Increment the build number before uploading any fixed build.

## Alpha Verification Checklist

- App launches on a real iPhone.
- Camera permission prompt appears with clear text.
- Photo library import prompt appears with clear text.
- Profile shows `Alpha 0.1.0`.
- Monetization debug controls are hidden.
- Ads are enabled for free users.
- Card generation calls the alpha renderer endpoint.
