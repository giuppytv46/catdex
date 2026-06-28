insert into public.badges (
  id,
  name,
  description,
  icon_key
) values
  ('explorer', 'Explorer', 'Started the CatDex journey.', 'compass'),
  ('first_cat', 'First Cat', 'Saved the first discovery card.', 'paw'),
  ('rare_finder', 'Rare Finder', 'Found a rare cat.', 'sparkle'),
  ('shiny_hunter', 'Shiny Hunter', 'Found a shiny variant.', 'star'),
  ('summer_paw', 'Sun Paw Badge', 'Joined the Summer Paw Festival.', 'sun')
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  icon_key = excluded.icon_key;
