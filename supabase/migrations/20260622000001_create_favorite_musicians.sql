-- A venue (user_id) favoriting a musician (musician_id).
-- Both reference public.users(id) since venues and musicians both live there.
create table if not exists public.favorite_musicians (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  musician_id uuid not null references public.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, musician_id)
);

-- Fast lookup of "all musicians this user favorited".
create index if not exists favorite_musicians_user_id_idx
  on public.favorite_musicians (user_id);

-- Row Level Security: a user can only see/insert/delete their OWN favorites.
-- This mirrors the existing `favorites` table policies exactly.
alter table public.favorite_musicians enable row level security;

create policy favorite_musicians_select_own
  on public.favorite_musicians for select
  using (auth.uid() = user_id);

create policy favorite_musicians_insert_own
  on public.favorite_musicians for insert
  with check (auth.uid() = user_id);

create policy favorite_musicians_delete_own
  on public.favorite_musicians for delete
  using (auth.uid() = user_id);
