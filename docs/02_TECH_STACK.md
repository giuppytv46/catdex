# CatDex Technical Stack v1.0

## Purpose

This document defines every technology used in CatDex.

The goal is to build a scalable mobile game that can support hundreds of thousands of users while remaining simple to maintain.

---

# Frontend

Framework

Flutter

Reason

* Single codebase
* Native performance
* Android
* iOS
* Huge ecosystem
* Excellent animations

State Management

Riverpod

Reason

* Modern
* Scalable
* Testable
* Recommended by Flutter community

Routing

GoRouter

Reason

* Deep linking
* Navigation
* Web compatibility

---

# Backend

Supabase

Services used

* PostgreSQL
* Authentication
* Storage
* Edge Functions
* Realtime
* Row Level Security

Reason

Supabase provides almost every backend feature required without maintaining custom servers.

---

# Authentication

Supabase Auth

Providers

* Email
* Google
* Apple

Future

* Anonymous Login

---

# Database

PostgreSQL

Hosted on Supabase.

Reason

Reliable

Scalable

SQL support

Easy backups

---

# AI

OpenAI Vision

Responsibilities

* Cat breed detection
* Coat analysis
* Pattern analysis
* Eye color
* Trait extraction

The AI never invents scientific facts.

If uncertain, classify as Domestic Cat.

---

# Maps

Mapbox

Reason

Better customization than Google Maps.

Lower long-term costs.

Offline capabilities.

---

# Notifications

Firebase Cloud Messaging

Notifications

Daily missions

Events

Achievements

Streak reminder

Premium reminders

---

# Analytics

Firebase Analytics

Track

Retention

Session length

Daily Active Users

Monthly Active Users

Discovery frequency

Conversion to Premium

---

# Crash Reporting

Firebase Crashlytics

Mandatory.

---

# Monetization

Google AdMob

Formats

Rewarded

Banner

Interstitial (limited)

Subscriptions

Google Play Billing

Apple In App Purchase

---

# Storage

Supabase Storage

Stores

User photos

Generated assets

Profile images

---

# Source Control

GitHub

Branch strategy

main

develop

feature/*

release/*

hotfix/*

---

# Continuous Integration

GitHub Actions

Automatic

Testing

Lint

Build verification

---

# Architecture

Clean Architecture

Presentation

Domain

Data

Repository Pattern

Dependency Injection

---

# Testing

Unit Tests

Widget Tests

Integration Tests

---

# Target Platforms

Android

iOS

---

# Languages

English

Italian

Spanish

French

German

Japanese

Future additions through localization files.

---

# Security

JWT Authentication

HTTPS only

Encrypted storage

Secure API Keys

No API key stored inside the app.

---

# Performance Goals

App startup

<2 seconds

Camera opening

<500 ms

AI analysis

<5 seconds average

Navigation

60 FPS animations

---

# Scalability Goal

Initial

10,000 users

Target

1,000,000 users

Architecture must support horizontal scaling.

---

This document is considered the technical foundation of CatDex.

