insert into public.achievements (
  id,
  name,
  description,
  xp_reward,
  hidden
) values
  ('first_cat', 'First Cat', 'Save your first cat discovery.', 100, false),
  ('cat_lover', 'Cat Lover', 'Save ten cat discoveries.', 250, false),
  ('first_rare', 'First Rare', 'Discover your first rare cat.', 200, false),
  ('first_shiny', 'First Shiny', 'Discover your first shiny variant.', 300, false),
  ('world_explorer', 'World Explorer', 'Discover cats in multiple places.', 400, false)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  xp_reward = excluded.xp_reward,
  hidden = excluded.hidden;
