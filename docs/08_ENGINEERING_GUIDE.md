# CatDex Engineering Guide v1.0

## Purpose

This document defines how every engineer (human or AI) must work on CatDex.

The objective is consistency.

Every feature should look like it was written by the same developer.

---

# Golden Rule

Never rewrite working code.

Always extend existing systems.

---

# Architecture

Respect Clean Architecture.

Presentation

↓

Application

↓

Domain

↓

Infrastructure

Never bypass layers.

---

# Widgets

Every widget should be reusable.

Never duplicate UI.

If a widget is used twice,

create a shared component.

---

# Business Logic

Business logic NEVER belongs inside widgets.

Widgets only render UI.

---

# State Management

Riverpod only.

Never use setState for business logic.

---

# Naming

Good

DiscoveryCard

Bad

Card2

Good

UserProfileRepository

Bad

Repo

---

# Folder Rules

One feature

↓

One folder

Every folder contains

presentation

application

domain

data

---

# Dependencies

Always inject.

Never instantiate services directly.

---

# Comments

Explain WHY.

Never explain WHAT.

---

# AI Calls

Every AI request must pass through backend functions.

Never expose API keys.

---

# Errors

Every feature needs:

Loading

Empty

Success

Failure

Offline

States.

---

# Analytics

Every important interaction must generate an analytics event.

Examples

Discovery

Mission Completed

Level Up

Premium Purchase

Ad Viewed

Friend Added

---

# Performance

Images lazy loaded.

Lists virtualized.

Animations GPU friendly.

Avoid rebuilds.

---

# Pull Requests

Every feature should compile.

Every feature should include tests.

No TODO left behind.

---

# Code Style

Readable first.

Short methods.

Single Responsibility Principle.

Prefer composition over inheritance.

---

# Documentation

Every public service must contain documentation.

Every repository must describe its purpose.

---

# Accessibility

Every screen must support:

Screen readers

Dynamic text

Large touch targets

Dark mode

---

# Definition of Done

A feature is only complete if:

Code

Tests

Localization

Analytics

Accessibility

Loading

Error Handling

Documentation

are complete.

Nothing is considered finished otherwise.
