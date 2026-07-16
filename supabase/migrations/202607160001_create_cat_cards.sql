create table if not exists public.cat_cards (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  discovery_id text not null references public.discoveries(id) on delete cascade,
  card_type text not null check (card_type in ('normal', 'event')),
  rarity text not null check (
    rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')
  ),
  final_card_url text not null,
  illustrated_cat_url text,
  template_key text not null,
  generation_status text not null check (
    generation_status in ('pending', 'completed', 'failed')
  ),
  generation_request_id text not null,
  idempotency_key text not null,
  event_key text,
  event_edition text,
  event_artwork_variant_id text,
  event_artwork_tier text check (
    event_artwork_tier is null or event_artwork_tier in ('free', 'premium')
  ),
  event_template_key text,
  is_premium_artwork boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cat_cards_event_metadata_check check (
    card_type = 'normal'
    or (
      event_key is not null
      and event_edition is not null
      and event_artwork_variant_id is not null
    )
  )
);

create unique index if not exists cat_cards_normal_unique
  on public.cat_cards(user_id, discovery_id, card_type)
  where card_type = 'normal';

create unique index if not exists cat_cards_event_unique
  on public.cat_cards(
    user_id,
    discovery_id,
    event_key,
    event_edition,
    event_artwork_variant_id
  )
  where card_type = 'event';

create unique index if not exists cat_cards_idempotency_unique
  on public.cat_cards(user_id, idempotency_key);

create index if not exists cat_cards_user_created_idx
  on public.cat_cards(user_id, created_at desc);

create index if not exists cat_cards_discovery_idx
  on public.cat_cards(user_id, discovery_id);

alter table public.cat_cards enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'cat_cards'
      and policyname = 'cat_cards_select_own'
  ) then
    create policy "cat_cards_select_own" on public.cat_cards
      for select using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'cat_cards'
      and policyname = 'cat_cards_insert_own'
  ) then
    create policy "cat_cards_insert_own" on public.cat_cards
      for insert with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'cat_cards'
      and policyname = 'cat_cards_update_own'
  ) then
    create policy "cat_cards_update_own" on public.cat_cards
      for update using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'cat_cards'
      and policyname = 'cat_cards_delete_own'
  ) then
    create policy "cat_cards_delete_own" on public.cat_cards
      for delete using (auth.uid() = user_id);
  end if;
end
$$;
