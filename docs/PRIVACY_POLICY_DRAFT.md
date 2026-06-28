# CatDex Privacy Policy Draft

This is a draft for future legal review. It is not final legal advice and must be reviewed before store submission.

## Overview

CatDex is a mobile game where players can capture or import cat photos, analyze them, and collect generated cat discovery cards.

## Information CatDex May Process

CatDex may process:

- Photos selected or captured by the player.
- Optional location data if the player grants location permission.
- Account email when the player chooses to sign in.
- Gameplay progress such as discoveries, XP, level, and collection state.
- Technical diagnostics needed to keep the app reliable.

## Photos

In guest mode, photos can remain local to the device flow.

In cloud mode, selected photos may be uploaded to private Supabase Storage before analysis. Public photo URLs are not exposed by default.

## Location

Location is optional. If permission is granted, CatDex may store coordinates and reverse-geocoded location fields such as city, region, and country for discoveries.

If permission is denied, CatDex continues to work with location unavailable.

## AI Analysis

CatDex may send image metadata or uploaded photo references to a server-side analysis function. API keys are never stored in the Flutter app.

CatDex should not identify people. Human subjects are ignored for gameplay purposes.

## Accounts

Players may use CatDex in guest mode. If a player signs in, CatDex may store their email and cloud gameplay progress through Supabase.

## Children

CatDex is designed as a friendly game experience. Store age rating and child privacy requirements must be reviewed before publishing.

## Monetization

CatDex currently contains placeholder architecture for future premium plans and ads. No real payments or ads are enabled in this release foundation.

## Contact

Contact details must be added before store submission.

## Changes

This draft should be updated whenever CatDex adds new data collection, analytics, advertising, payments, or social features.
