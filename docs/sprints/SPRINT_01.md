# Sprint 01 — Project Foundation

## Sprint Goal

Build the production-ready foundation of CatDex.

No gameplay.

No AI.

No map.

No CatDex collection.

The goal is to create a clean, scalable and maintainable Flutter application.

---

## Context

Read first:

AGENTS.md

01_GDD.md

02_TECH_STACK.md

03_ARCHITECTURE.md

04_DATABASE.md

05_GAMEPLAY.md

06_UI_UX.md

07_AI_SYSTEM.md

---

## Deliverables

Create a Flutter application.

Configure:

Flutter

Riverpod

GoRouter

Freezed

Json Serializable

Build Runner

Supabase

Firebase

Flutter Lints

Very Good Analysis

---

## Folder Structure

lib/

core/

shared/

features/

services/

theme/

routing/

widgets/

---

## Features to create

Authentication

Home

Capture

CatDex

Friends

Profile

Settings

Only empty pages.

No business logic yet.

---

## Routing

Implement navigation using GoRouter.

Routes:

Splash

Onboarding

Login

Home

Capture

CatDex

Friends

Profile

Settings

Unknown Route

---

## Theme

Implement CatDex Design System.

Colors

Typography

Rounded Cards

Buttons

Spacing

Dark Theme

Light Theme

---

## Localization

Create localization infrastructure.

Supported:

English

Italian

Spanish

French

German

Japanese

No hardcoded strings.

---

## Authentication

Implement:

Email

Google

Apple

Using Supabase Auth.

Only login flow.

No profile yet.

---

## State Management

Configure Riverpod.

Create providers for:

Theme

Localization

Authentication

Navigation

---

## Error Handling

Global error page.

Offline page.

Unknown error page.

Loading screen.

---

## Dependency Injection

Configure dependency injection.

Repositories must not depend on widgets.

---

## CI

GitHub Actions

Run:

flutter analyze

flutter test

---

## README

Create a professional README describing:

Project

Architecture

Folder Structure

Requirements

Setup

---

## Out of Scope

No AI

No Camera

No GPS

No Database Tables

No Gameplay

No XP

No Missions

No Premium

---

## Acceptance Criteria

Application builds successfully.

Runs on Android.

Runs on iOS.

Navigation works.

Authentication works.

Theme works.

Dark Mode works.

Localization works.

CI passes.

No warnings.

No errors.

No TODOs.
