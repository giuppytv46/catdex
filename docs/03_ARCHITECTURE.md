# CatDex Software Architecture v1.0

## Purpose

This document defines the software architecture of CatDex.

The goal is to create an application that is modular, maintainable and scalable.

Every feature should be developed independently without affecting unrelated modules.

---

# Architecture Pattern

CatDex follows Clean Architecture.

Layers:

Presentation

↓

Application

↓

Domain

↓

Data

↓

Infrastructure

Dependencies always point inward.

The UI never communicates directly with Supabase or OpenAI.

---

# Project Structure

lib/

core/

features/

shared/

services/

widgets/

models/

theme/

routing/

main.dart

---

# Core

Contains application-wide logic.

Examples:

App configuration

Constants

Localization

Permissions

Utilities

Logging

---

# Features

Every feature is isolated.

Example:

features/

auth/

camera/

catdex/

discoveries/

profile/

map/

missions/

friends/

premium/

settings/

notifications/

Each feature contains:

presentation/

application/

domain/

data/

---

# Presentation Layer

Contains:

Pages

Widgets

Dialogs

Animations

ViewModels

No business logic.

Only UI.

---

# Application Layer

Contains:

Use Cases

Controllers

State management

Coordinates domain objects.

---

# Domain Layer

Contains:

Business rules

Entities

Repositories interfaces

No Flutter imports.

No database code.

Pure Dart.

---

# Data Layer

Contains:

Supabase repositories

OpenAI services

Storage services

DTOs

Caching

Responsible for converting external data into domain models.

---

# Infrastructure Layer

Contains:

Networking

Storage

Authentication

Notifications

Maps

Analytics

Crash reporting

---

# State Management

Riverpod

Rules:

One provider per responsibility.

No global mutable state.

Business logic stays outside widgets.

---

# Navigation

GoRouter

Navigation tree:

Splash

↓

Onboarding

↓

Authentication

↓

Home

↓

Camera

↓

Analysis

↓

Discovery

↓

CatDex

↓

Profile

↓

Settings

---

# Error Handling

All errors must be typed.

Example:

NetworkError

AuthenticationError

AIAnalysisError

PermissionDenied

StorageError

UnexpectedError

Never expose raw exceptions to users.

---

# Offline Support

If internet is unavailable:

Users can still:

Browse CatDex

Open profile

View discoveries

Photos waiting for AI analysis should enter a queue.

Automatic upload when internet returns.

---

# Image Pipeline

Capture

↓

Compression

↓

Metadata removal (optional)

↓

Upload

↓

AI Analysis

↓

Database save

↓

Card generation

↓

Animation

---

# AI Pipeline

User photo

↓

OpenAI Vision

↓

Validation

↓

Breed classification

↓

Trait extraction

↓

Location association

↓

Reward calculation

↓

Save discovery

---

# Security

API Keys never inside Flutter.

All AI calls pass through secure backend functions.

Authentication required.

Rate limiting enabled.

---

# Performance

Lazy loading everywhere.

Images cached.

Animations at 60 FPS.

Background processing for uploads.

---

# Scalability

Every feature can become its own backend service in the future.

Current architecture should not prevent future microservices migration.

---

# Coding Standards

Feature-first organization.

SOLID principles.

Repository Pattern.

Dependency Injection.

Small reusable widgets.

No duplicated business logic.

---

# Definition of Done

A feature is complete only if:

* UI implemented
* Business logic implemented
* Tests written
* Localization added
* Accessibility verified
* Error states handled
* Loading states handled
* Analytics events added

---

This architecture document is the reference for all future development.
