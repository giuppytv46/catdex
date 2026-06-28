insert into public.cat_variants (
  id,
  name,
  reward_multiplier,
  xp_bonus,
  event_required,
  border_style,
  animation
) values
  ('normal', 'Normal', 1.00, 0, false, 'standard', 'none'),
  ('shiny', 'Shiny', 2.00, 120, false, 'sparkle', 'sparkle'),
  ('golden', 'Golden', 2.40, 180, false, 'gold', 'glow'),
  ('albino', 'Albino', 2.10, 140, false, 'pearl', 'soft_glow'),
  ('melanistic', 'Melanistic', 1.90, 110, false, 'shadow', 'pulse'),
  ('heterochromia', 'Heterochromia', 1.80, 100, false, 'rainbow', 'shimmer'),
  ('midnight', 'Midnight', 1.60, 80, false, 'midnight', 'twinkle'),
  ('lucky', 'Lucky', 1.70, 90, false, 'lucky', 'bounce'),
  ('event_edition', 'Event Edition', 2.20, 160, true, 'event', 'confetti')
on conflict (id) do update set
  name = excluded.name,
  reward_multiplier = excluded.reward_multiplier,
  xp_bonus = excluded.xp_bonus,
  event_required = excluded.event_required,
  border_style = excluded.border_style,
  animation = excluded.animation,
  updated_at = now();
