# CatDex Permissions Documentation

CatDex requests only permissions needed for the current gameplay loop.

## Camera

Purpose:

- Let players take a cat photo for local or cloud analysis.

Current platforms:

- Android: `android.permission.CAMERA`
- iOS: `NSCameraUsageDescription`

User-facing explanation:

CatDex uses the camera so you can choose a cat photo.

## Photo Library

Purpose:

- Let players import an existing cat photo.

Current platforms:

- iOS: `NSPhotoLibraryUsageDescription`
- Android: handled through the system picker/package behavior where available.

User-facing explanation:

CatDex uses your photo library so you can import a cat photo.

## Location

Purpose:

- Attach city, region, country, and coordinates to a discovery when the player chooses to detect location.

Current platforms:

- Android: `android.permission.ACCESS_COARSE_LOCATION`
- Android: `android.permission.ACCESS_FINE_LOCATION`
- iOS: `NSLocationWhenInUseUsageDescription`

User-facing explanation:

CatDex uses your location to remember where a cat photo was discovered.

Fallback behavior:

- If permission is denied, CatDex shows "Location unavailable".
- If reverse geocoding fails, CatDex can keep coordinates only.
- If location services are disabled, CatDex shows a friendly error.

## Notifications Future

Purpose:

- Future reminders for daily missions, events, streaks, and collection milestones.

Current status:

- Not implemented.
- No notification permission is requested yet.
- No Firebase Cloud Messaging integration is enabled yet.

Future user-facing explanation:

CatDex would like to send optional reminders for events, daily missions, and collection rewards.
