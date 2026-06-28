create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text not null default 'Explorer',
  avatar_url text,
  country text,
  language text not null default 'en',
  xp integer not null default 0 check (xp >= 0),
  level integer not null default 1 check (level between 1 and 100),
  coins integer not null default 0 check (coins >= 0),
  discovery_count integer not null default 0 check (discovery_count >= 0),
  duplicate_discovery_count integer not null default 0 check (duplicate_discovery_count >= 0),
  premium boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cat_species (
  id text primary key,
  display_name text not null,
  scientific_name text not null,
  origin_country text not null,
  base_rarity text not null check (
    base_rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')
  ),
  illustration text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cat_variants (
  id text primary key,
  name text not null,
  reward_multiplier numeric(8, 2) not null check (reward_multiplier >= 1),
  xp_bonus integer not null default 0 check (xp_bonus >= 0),
  animation text,
  border_style text,
  event_required boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.discoveries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  species_id text not null references public.cat_species(id),
  variant_id text not null references public.cat_variants(id),
  rarity text not null check (
    rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')
  ),
  personality text not null,
  confidence numeric(4, 3),
  friendship_points integer not null default 0 check (friendship_points >= 0),
  nickname text,
  story text,
  city text,
  region text,
  country text,
  latitude double precision,
  longitude double precision,
  photo_url text,
  illustration_seed text,
  favorite boolean not null default false,
  shared boolean not null default false,
  discovered_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.discovery_traits (
  id uuid primary key default gen_random_uuid(),
  discovery_id text not null references public.discoveries(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  trait_name text not null,
  trait_value text not null,
  rarity_weight numeric(8, 2) not null default 1 check (rarity_weight >= 1),
  created_at timestamptz not null default now()
);

create table if not exists public.achievements (
  id text primary key,
  name text not null,
  description text not null,
  xp_reward integer not null default 0 check (xp_reward >= 0),
  hidden boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

create table if not exists public.badges (
  id text primary key,
  name text not null,
  description text not null,
  icon_key text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id text not null references public.badges(id),
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table if not exists public.scan_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  photo_reference text,
  status text not null check (status in ('started', 'succeeded', 'failed')),
  error_code text,
  created_at timestamptz not null default now()
);

create index if not exists discoveries_user_id_idx on public.discoveries(user_id);
create index if not exists discoveries_species_id_idx on public.discoveries(species_id);
create index if not exists discovery_traits_user_id_idx on public.discovery_traits(user_id);
create index if not exists scan_history_user_id_idx on public.scan_history(user_id);

alter table public.profiles enable row level security;
alter table public.cat_species enable row level security;
alter table public.cat_variants enable row level security;
alter table public.discoveries enable row level security;
alter table public.discovery_traits enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.scan_history enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "cat_species_public_read" on public.cat_species
  for select using (true);

create policy "cat_variants_public_read" on public.cat_variants
  for select using (true);

create policy "discoveries_select_own" on public.discoveries
  for select using (auth.uid() = user_id);

create policy "discoveries_insert_own" on public.discoveries
  for insert with check (auth.uid() = user_id);

create policy "discoveries_update_own" on public.discoveries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "discoveries_delete_own" on public.discoveries
  for delete using (auth.uid() = user_id);

create policy "discovery_traits_select_own" on public.discovery_traits
  for select using (auth.uid() = user_id);

create policy "discovery_traits_insert_own" on public.discovery_traits
  for insert with check (auth.uid() = user_id);

create policy "discovery_traits_update_own" on public.discovery_traits
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "discovery_traits_delete_own" on public.discovery_traits
  for delete using (auth.uid() = user_id);

create policy "achievements_public_read" on public.achievements
  for select using (true);

create policy "badges_public_read" on public.badges
  for select using (true);

create policy "user_achievements_select_own" on public.user_achievements
  for select using (auth.uid() = user_id);

create policy "user_achievements_insert_own" on public.user_achievements
  for insert with check (auth.uid() = user_id);

create policy "user_badges_select_own" on public.user_badges
  for select using (auth.uid() = user_id);

create policy "user_badges_insert_own" on public.user_badges
  for insert with check (auth.uid() = user_id);

create policy "scan_history_select_own" on public.scan_history
  for select using (auth.uid() = user_id);

create policy "scan_history_insert_own" on public.scan_history
  for insert with check (auth.uid() = user_id);
