# CatDex Database Design v1.0

## Purpose

This document defines the complete database architecture for CatDex.

The database must support millions of discoveries while remaining scalable, secure and easy to maintain.

Backend:

Supabase PostgreSQL

---

# Main Principles

* UUID primary keys
* Timestamps everywhere
* Soft deletes where appropriate
* Row Level Security
* Audit friendly
* Optimized indexes
* Minimal duplicated data

---

# Tables Overview

profiles

cat_species

cat_variants

discoveries

discovery_traits

friendships

achievements

user_achievements

daily_missions

user_daily_progress

events

badges

user_badges

notifications

premium_status

scan_history

reports

---

# profiles

Stores player information.

Columns

id

username

display_name

avatar_url

country

language

xp

level

coins

premium

created_at

updated_at

---

# cat_species

Master list.

Examples

European Shorthair

Maine Coon

Persian

Domestic Cat

Siamese

...

Fields

id

scientific_name

display_name

origin_country

description

base_rarity

illustration

active

---

# cat_variants

Contains collectible variants.

Examples

Normal

Golden

Albino

Melanistic

Shiny

Halloween

Christmas

Lucky

Midnight

Fields

id

name

rarity_multiplier

animation

border_style

event_required

---

# discoveries

Most important table.

Each discovery belongs to one player.

Fields

id

user_id

species_id

variant_id

confidence

friendship_level

nickname

story

city

region

country

latitude

longitude

discovered_at

photo_url

illustration_seed

favorite

shared

---

# discovery_traits

Stores AI extracted traits.

Examples

Green Eyes

Blue Eyes

Long Tail

Short Hair

Scar

Broken Ear

White Socks

Large Size

Fields

id

discovery_id

trait_name

trait_value

---

# friendships

Future social system.

Fields

id

requester_id

receiver_id

status

created_at

---

# achievements

Static table.

Fields

id

name

description

icon

xp_reward

hidden

---

# user_achievements

Fields

id

user_id

achievement_id

completed_at

---

# badges

Collectible profile badges.

Examples

Explorer

Cat Lover

Night Hunter

Halloween Master

Fields

id

title

description

icon

---

# user_badges

Fields

id

user_id

badge_id

selected

earned_at

---

# daily_missions

Static missions.

Fields

id

title

description

objective

reward_xp

reward_coins

active

---

# user_daily_progress

Stores mission progress.

Fields

id

user_id

mission_id

progress

completed

date

---

# events

Future event system.

Examples

Halloween

Christmas

Summer

Cat Day

Fields

id

title

start_date

end_date

theme

active

---

# notifications

Fields

id

user_id

title

body

type

read

created_at

---

# premium_status

Stores subscription.

Fields

id

user_id

provider

expiration

status

---

# scan_history

Stores every AI scan.

Useful for:

Analytics

Debugging

Rate limits

Fields

id

user_id

image_url

analysis_duration

success

error

created_at

---

# reports

Community moderation.

Fields

id

reporter

discovery

reason

status

---

# Relationships

Profile

↓

Many Discoveries

↓

One Species

↓

One Variant

↓

Many Traits

Profile

↓

Many Achievements

↓

Many Badges

↓

Many Missions

↓

Many Friends

---

# Indexes

Create indexes for:

user_id

species_id

variant_id

city

country

created_at

level

xp

---

# Security

Row Level Security enabled everywhere.

Players only access their own discoveries.

Public profile information separated from private information.

---

# Future Ready

Database prepared for:

Trading

Guilds

Pets

Marketplace

Breeding Simulator

Cat Rescue Events

Community Challenges

---

This database is designed for long-term scalability.
