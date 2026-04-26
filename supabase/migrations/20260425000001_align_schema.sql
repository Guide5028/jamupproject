-- ============================================================================
-- JamUP  —  Align Supabase schema to what the Flutter code actually uses
-- ============================================================================
-- WHY this file exists, Guide:
--   Your README describes an early MVP schema. Your code has since grown
--   (reviews, portfolio, notifications, device_tokens, lat/lng, etc.).
--   This migration brings the database up to the REAL current code.
--
-- HOW to run it:
--   Option A (recommended once you're comfortable):
--     npx supabase db push
--   Option B (quick / safe for a student MVP):
--     Open Supabase dashboard → SQL Editor → New Query
--     → paste this whole file → Run
--
-- This file is idempotent: every CREATE uses `IF NOT EXISTS`, every
-- ALTER uses `ADD COLUMN IF NOT EXISTS`, and every policy is `DROP ...
-- IF EXISTS` before create. So you can run it repeatedly and it's safe.
-- ============================================================================

-- Needed for UUIDs. It's usually enabled already, but safe to ask.
create extension if not exists "pgcrypto";

-- ============================================================================
-- 1. USERS
-- ============================================================================
-- Teacher note: we mirror auth.users so we can attach profile fields
-- (name, role, avatar, lat/lng, genres...) that auth.users doesn't hold.
-- Every row's `id` must match exactly with auth.users.id.
create table if not exists public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text,
  bio         text,
  role        text check (role in ('musician','venue')) default 'musician',
  avatar_url  text,
  -- MVP "array" columns — simpler than a junction table, fine at this scale.
  genres      text[] default '{}',
  instruments text[] default '{}',
  -- Geo for the "nearby" feature
  latitude    double precision,
  longitude   double precision,
  location_text text,
  -- Musician-only field, null for venues
  hourly_rate numeric,
  created_at  timestamptz default now()
);

-- Add columns safely if the table already existed
alter table public.users add column if not exists genres      text[] default '{}';
alter table public.users add column if not exists instruments text[] default '{}';
alter table public.users add column if not exists latitude    double precision;
alter table public.users add column if not exists longitude   double precision;
alter table public.users add column if not exists location_text text;
alter table public.users add column if not exists hourly_rate numeric;
alter table public.users add column if not exists created_at  timestamptz default now();


-- ============================================================================
-- 2. GIGS
-- ============================================================================
-- Teacher note: this is the table your Gig.fromJson reads from. Every
-- field in /lib/models/gig.dart must have a column here or the model
-- just gets `null`.
create table if not exists public.gigs (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text,
  date         timestamptz not null,         -- was `text` in README; timestamptz is correct
  location     text not null,
  image_url    text,
  venue_id     uuid not null references public.users(id) on delete cascade,
  musician_id  uuid     references public.users(id) on delete set null,
  genres       text[] default '{}',
  latitude     double precision,
  longitude    double precision,
  price        numeric default 0,
  payment      numeric,
  role_needed  text,
  slots        int default 1,
  applicants   int default 0,
  created_at   timestamptz default now()
);

alter table public.gigs add column if not exists description  text;
alter table public.gigs add column if not exists image_url    text;
alter table public.gigs add column if not exists musician_id  uuid references public.users(id) on delete set null;
alter table public.gigs add column if not exists genres       text[] default '{}';
alter table public.gigs add column if not exists latitude     double precision;
alter table public.gigs add column if not exists longitude    double precision;
alter table public.gigs add column if not exists price        numeric default 0;
alter table public.gigs add column if not exists payment      numeric;
alter table public.gigs add column if not exists role_needed  text;
alter table public.gigs add column if not exists slots        int default 1;
alter table public.gigs add column if not exists applicants   int default 0;
alter table public.gigs add column if not exists created_at   timestamptz default now();
-- start_time / end_time are OPTIONAL on a gig — venue may just publish a date.
-- They're required on BOOKINGS (that's how conflict detection works).
alter table public.gigs add column if not exists start_time   timestamptz;
alter table public.gigs add column if not exists end_time     timestamptz;

-- Helpful index for the "upcoming gigs" query (date > now() order by date).
create index if not exists gigs_date_idx     on public.gigs (date);
create index if not exists gigs_venue_id_idx on public.gigs (venue_id);


-- ============================================================================
-- 3. BOOKINGS
-- ============================================================================
-- Teacher note: your booking_repository uses start_time / end_time to
-- detect time conflicts. The old README only had `created_at`, so we
-- add start_time and end_time here.
create table if not exists public.bookings (
  id           uuid primary key default gen_random_uuid(),
  gig_id       uuid not null references public.gigs(id) on delete cascade,
  musician_id  uuid not null references public.users(id) on delete cascade,
  venue_id     uuid not null references public.users(id) on delete cascade,
  status       text not null default 'pending'
               check (status in ('pending','confirmed','declined','cancelled')),
  start_time   timestamptz,
  end_time     timestamptz,
  created_at   timestamptz default now()
);

alter table public.bookings add column if not exists start_time timestamptz;
alter table public.bookings add column if not exists end_time   timestamptz;

-- Drop the old CHECK so we can re-add 'cancelled'. Then re-add a complete one.
alter table public.bookings drop constraint if exists bookings_status_check;
alter table public.bookings add  constraint bookings_status_check
  check (status in ('pending','confirmed','declined','cancelled'));

create index if not exists bookings_musician_idx on public.bookings (musician_id);
create index if not exists bookings_venue_idx    on public.bookings (venue_id);
create index if not exists bookings_gig_idx      on public.bookings (gig_id);


-- ============================================================================
-- 4. CHATS + MESSAGES
-- ============================================================================
create table if not exists public.chats (
  id         uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.messages (
  id         uuid primary key default gen_random_uuid(),
  chat_id    uuid not null references public.chats(id) on delete cascade,
  sender_id  uuid     references public.users(id) on delete set null,
  text       text not null,
  type       text default 'user' check (type in ('user','system')),
  read_at    timestamptz,
  created_at timestamptz default now()
);

alter table public.messages add column if not exists read_at timestamptz;

create index if not exists messages_chat_idx   on public.messages (chat_id, created_at);


-- ============================================================================
-- 5. PORTFOLIO  (musician photos/videos — your "talent" media)
-- ============================================================================
create table if not exists public.portfolio (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  media_url   text not null,
  media_type  text not null check (media_type in ('image','video')),
  description text,
  created_at  timestamptz default now()
);

create index if not exists portfolio_user_idx on public.portfolio (user_id, created_at desc);


-- ============================================================================
-- 6. REVIEWS
-- ============================================================================
create table if not exists public.reviews (
  id                uuid primary key default gen_random_uuid(),
  booking_id        uuid not null references public.bookings(id) on delete cascade,
  reviewer_id       uuid not null references public.users(id) on delete cascade,
  reviewed_user_id  uuid not null references public.users(id) on delete cascade,
  rating            int not null check (rating between 1 and 5),
  comment           text,
  created_at        timestamptz default now(),
  -- One review per (booking, reviewer) so a user can't spam.
  unique (booking_id, reviewer_id)
);

create index if not exists reviews_reviewed_idx on public.reviews (reviewed_user_id);


-- ============================================================================
-- 7. NOTIFICATIONS  (bell icon inbox — the "persistent" layer)
-- ============================================================================
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  title      text not null,
  message    text,
  type       text,                 -- 'message' | 'booking_request' | 'booking_confirmed' | ...
  data       jsonb default '{}',   -- deep-link info (chatId, bookingId, gigId)
  is_read    boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications add column if not exists data jsonb default '{}';

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);


-- ============================================================================
-- 8. DEVICE_TOKENS  (OneSignal subscription IDs — the "ephemeral" layer)
-- ============================================================================
create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  player_id   text not null,
  platform    text,        -- 'ios' | 'android'
  created_at  timestamptz default now(),
  unique (user_id, player_id)
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);


-- ============================================================================
-- 9. NEARBY GIGS RPC
-- ============================================================================
-- Teacher note: your home page calls `get_nearby_gigs(user_lat, user_lng,
-- radius_km)`. The haversine formula computes the great-circle distance
-- between two points on Earth — accurate enough at city scale.
--
-- We return every column the `Gig.fromJson` constructor reads, PLUS a
-- computed `distance` column (km).
create or replace function public.get_nearby_gigs(
  user_lat  double precision,
  user_lng  double precision,
  radius_km double precision
)
returns table (
  id          uuid,
  title       text,
  description text,
  date        timestamptz,
  location    text,
  image_url   text,
  venue_id    uuid,
  musician_id uuid,
  genres      text[],
  latitude    double precision,
  longitude   double precision,
  price       numeric,
  payment     numeric,
  role_needed text,
  slots       int,
  applicants  int,
  created_at  timestamptz,
  distance    double precision
)
language sql
stable
as $$
  select
    g.id, g.title, g.description, g.date, g.location, g.image_url,
    g.venue_id, g.musician_id, g.genres, g.latitude, g.longitude,
    g.price, g.payment, g.role_needed, g.slots, g.applicants, g.created_at,
    -- Haversine, radius of Earth = 6371 km
    (6371 * acos(
        cos(radians(user_lat))
      * cos(radians(g.latitude))
      * cos(radians(g.longitude) - radians(user_lng))
      + sin(radians(user_lat))
      * sin(radians(g.latitude))
    )) as distance
  from public.gigs g
  where g.latitude is not null
    and g.longitude is not null
    and g.date >= now()
    and (6371 * acos(
        cos(radians(user_lat))
      * cos(radians(g.latitude))
      * cos(radians(g.longitude) - radians(user_lng))
      + sin(radians(user_lat))
      * sin(radians(g.latitude))
    )) <= radius_km
  order by distance asc;
$$;


-- ============================================================================
-- 10. ROW LEVEL SECURITY  (RLS)
-- ============================================================================
-- Teacher note: RLS is Supabase's "firewall in the database". When it's
-- ON, every query from the mobile app is filtered by these policies,
-- so a user can't read or write rows that don't belong to them.
-- We turn RLS on for every table, then add explicit policies.

alter table public.users           enable row level security;
alter table public.gigs            enable row level security;
alter table public.bookings        enable row level security;
alter table public.chats           enable row level security;
alter table public.messages        enable row level security;
alter table public.portfolio       enable row level security;
alter table public.reviews         enable row level security;
alter table public.notifications   enable row level security;
alter table public.device_tokens   enable row level security;

-- ──── users ────────────────────────────────────────────────────────────────
drop policy if exists users_select_all      on public.users;
drop policy if exists users_insert_self     on public.users;
drop policy if exists users_update_self     on public.users;

-- Anyone logged in can read profiles (so musicians appear in directory).
create policy users_select_all on public.users
  for select using (auth.uid() is not null);

create policy users_insert_self on public.users
  for insert with check (id = auth.uid());

create policy users_update_self on public.users
  for update using (id = auth.uid());

-- ──── gigs ─────────────────────────────────────────────────────────────────
drop policy if exists gigs_select_all        on public.gigs;
drop policy if exists gigs_insert_venue_only on public.gigs;
drop policy if exists gigs_update_own        on public.gigs;
drop policy if exists gigs_delete_own        on public.gigs;

create policy gigs_select_all on public.gigs
  for select using (auth.uid() is not null);

create policy gigs_insert_venue_only on public.gigs
  for insert with check (
    auth.uid() = venue_id
    and exists (select 1 from public.users u where u.id = auth.uid() and u.role = 'venue')
  );

create policy gigs_update_own on public.gigs
  for update using (auth.uid() = venue_id);

create policy gigs_delete_own on public.gigs
  for delete using (auth.uid() = venue_id);

-- ──── bookings ─────────────────────────────────────────────────────────────
drop policy if exists bookings_select_mine   on public.bookings;
drop policy if exists bookings_insert_mine   on public.bookings;
drop policy if exists bookings_update_mine   on public.bookings;

-- You see bookings where you are musician OR venue.
create policy bookings_select_mine on public.bookings
  for select using (auth.uid() = musician_id or auth.uid() = venue_id);

create policy bookings_insert_mine on public.bookings
  for insert with check (auth.uid() = musician_id or auth.uid() = venue_id);

create policy bookings_update_mine on public.bookings
  for update using (auth.uid() = musician_id or auth.uid() = venue_id);

-- ──── chats + messages ─────────────────────────────────────────────────────
drop policy if exists chats_select_own      on public.chats;
drop policy if exists chats_insert_own      on public.chats;
drop policy if exists messages_select_own   on public.messages;
drop policy if exists messages_insert_own   on public.messages;
drop policy if exists messages_update_read  on public.messages;

-- You see chats whose booking you're part of.
create policy chats_select_own on public.chats
  for select using (
    exists (
      select 1 from public.bookings b
      where b.id = chats.booking_id
        and (auth.uid() = b.musician_id or auth.uid() = b.venue_id)
    )
  );

create policy chats_insert_own on public.chats
  for insert with check (
    exists (
      select 1 from public.bookings b
      where b.id = chats.booking_id
        and (auth.uid() = b.musician_id or auth.uid() = b.venue_id)
    )
  );

create policy messages_select_own on public.messages
  for select using (
    exists (
      select 1 from public.chats c
      join public.bookings b on b.id = c.booking_id
      where c.id = messages.chat_id
        and (auth.uid() = b.musician_id or auth.uid() = b.venue_id)
    )
  );

create policy messages_insert_own on public.messages
  for insert with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.chats c
      join public.bookings b on b.id = c.booking_id
      where c.id = messages.chat_id
        and (auth.uid() = b.musician_id or auth.uid() = b.venue_id)
    )
  );

-- For marking messages as read, both participants may update read_at.
create policy messages_update_read on public.messages
  for update using (
    exists (
      select 1 from public.chats c
      join public.bookings b on b.id = c.booking_id
      where c.id = messages.chat_id
        and (auth.uid() = b.musician_id or auth.uid() = b.venue_id)
    )
  );

-- ──── portfolio ────────────────────────────────────────────────────────────
drop policy if exists portfolio_select_all on public.portfolio;
drop policy if exists portfolio_insert_own on public.portfolio;
drop policy if exists portfolio_delete_own on public.portfolio;

-- Anyone can see any musician's portfolio (venues must browse it).
create policy portfolio_select_all on public.portfolio
  for select using (auth.uid() is not null);

create policy portfolio_insert_own on public.portfolio
  for insert with check (user_id = auth.uid());

create policy portfolio_delete_own on public.portfolio
  for delete using (user_id = auth.uid());

-- ──── reviews ──────────────────────────────────────────────────────────────
drop policy if exists reviews_select_all  on public.reviews;
drop policy if exists reviews_insert_own  on public.reviews;

create policy reviews_select_all on public.reviews
  for select using (auth.uid() is not null);

create policy reviews_insert_own on public.reviews
  for insert with check (reviewer_id = auth.uid());

-- ──── notifications ────────────────────────────────────────────────────────
drop policy if exists notifications_select_own on public.notifications;
drop policy if exists notifications_update_own on public.notifications;
drop policy if exists notifications_delete_own on public.notifications;

create policy notifications_select_own on public.notifications
  for select using (user_id = auth.uid());

create policy notifications_update_own on public.notifications
  for update using (user_id = auth.uid());

create policy notifications_delete_own on public.notifications
  for delete using (user_id = auth.uid());

-- NOTE: Inserts into notifications are done by the `send-notification`
-- Edge Function using the SERVICE_ROLE_KEY, which bypasses RLS. We do
-- NOT give clients insert rights here — otherwise a musician could spam
-- fake "Booking confirmed" notifications to themselves.

-- ──── device_tokens ────────────────────────────────────────────────────────
drop policy if exists device_tokens_select_own on public.device_tokens;
drop policy if exists device_tokens_insert_own on public.device_tokens;
drop policy if exists device_tokens_delete_own on public.device_tokens;

create policy device_tokens_select_own on public.device_tokens
  for select using (user_id = auth.uid());

create policy device_tokens_insert_own on public.device_tokens
  for insert with check (user_id = auth.uid());

create policy device_tokens_delete_own on public.device_tokens
  for delete using (user_id = auth.uid());


-- ============================================================================
-- 11. STORAGE BUCKETS + POLICIES
-- ============================================================================
-- Teacher note: storage has its OWN RLS. We create 3 public-read buckets
-- (anyone can view the URL) but restrict writes to the file's owner via
-- a path convention: "<user_id>/<file>".

insert into storage.buckets (id, name, public)
  values ('avatars',     'avatars',     true)  on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
  values ('portfolio',   'portfolio',   true)  on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
  values ('gig_images',  'gig_images',  true)  on conflict (id) do nothing;

-- Clean slate for storage policies, then recreate.
drop policy if exists "read_all_avatars"       on storage.objects;
drop policy if exists "write_own_avatar"       on storage.objects;
drop policy if exists "update_own_avatar"      on storage.objects;
drop policy if exists "delete_own_avatar"      on storage.objects;

drop policy if exists "read_all_portfolio"     on storage.objects;
drop policy if exists "write_own_portfolio"    on storage.objects;
drop policy if exists "delete_own_portfolio"   on storage.objects;

drop policy if exists "read_all_gig_images"    on storage.objects;
drop policy if exists "write_own_gig_image"    on storage.objects;
drop policy if exists "delete_own_gig_image"   on storage.objects;

-- ── avatars ──
create policy "read_all_avatars" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "write_own_avatar" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "update_own_avatar" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "delete_own_avatar" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── portfolio ──
create policy "read_all_portfolio" on storage.objects
  for select using (bucket_id = 'portfolio');

create policy "write_own_portfolio" on storage.objects
  for insert with check (
    bucket_id = 'portfolio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "delete_own_portfolio" on storage.objects
  for delete using (
    bucket_id = 'portfolio'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── gig_images ──
-- Anyone logged in can write a gig image (a venue uploads when creating
-- a gig). We fence writes by requiring the file path to start with the
-- uploader's own user-id folder. The gigs table's RLS ensures only
-- venues actually save the URL into a gig row.
create policy "read_all_gig_images" on storage.objects
  for select using (bucket_id = 'gig_images');

create policy "write_own_gig_image" on storage.objects
  for insert with check (
    bucket_id = 'gig_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "delete_own_gig_image" on storage.objects
  for delete using (
    bucket_id = 'gig_images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );


-- ============================================================================
-- DONE. Run `select 1;` at the bottom so the editor shows success, not an
-- empty result. Any real error above would have already aborted the txn.
-- ============================================================================
select 1 as migration_ok;
