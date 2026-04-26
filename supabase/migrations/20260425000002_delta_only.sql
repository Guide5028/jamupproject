-- ============================================================================
-- JamUP  —  DELTA migration (only the missing pieces)
-- ============================================================================
-- Teacher note, Guide:
--   I inspected your live DB and your schema is already 80% there.
--   This file only adds what's truly missing. Your data is 100% safe —
--   every statement uses `if not exists` so re-running is harmless.
--
-- Run this INSTEAD of 20260425000001_align_schema.sql. You don't need both.
-- How: Supabase dashboard → SQL Editor → New Query → paste → Run.
-- ============================================================================

-- ── 1) users: fields my new Edit Profile form writes ──────────────────
alter table public.users add column if not exists instruments   text[] default '{}';
alter table public.users add column if not exists hourly_rate   numeric;
alter table public.users add column if not exists location_text text;

-- ── 2) gigs: fields my new Create/Edit Gig forms write ────────────────
-- musician_id is here because Gig.fromJson reads it (booking accepted →
-- gig gets a musician). The current `gigs` table doesn't have it yet.
alter table public.gigs add column if not exists musician_id  uuid references public.users(id) on delete set null;
alter table public.gigs add column if not exists price        numeric default 0;
alter table public.gigs add column if not exists payment      numeric;
alter table public.gigs add column if not exists role_needed  text;
alter table public.gigs add column if not exists slots        int default 1;
alter table public.gigs add column if not exists applicants   int default 0;
alter table public.gigs add column if not exists start_time   timestamptz;
alter table public.gigs add column if not exists end_time     timestamptz;

-- ── 3) notifications: data column for deep-linking push taps ──────────
-- When a user taps a push banner, we want to know WHERE to navigate.
-- The Edge Function already sends `data: { chatId, bookingId, ... }` but
-- the table was dropping it because the column didn't exist.
alter table public.notifications add column if not exists data jsonb default '{}';

-- ── 4) get_nearby_gigs RPC — INTENTIONALLY SKIPPED ────────────────────
-- I checked the live DB: this function ALREADY EXISTS and works.
-- Live signature returns `distance_km` (with a bbox prefilter for speed).
-- A `create or replace` here with a different return signature would error:
--     "cannot change return type of existing function"
-- Even worse, renaming `distance_km` → `distance` would silently break the
-- Flutter home page (it reads row['distance_km']).
-- Decision: leave the live RPC alone. If we later need new columns in the
-- feed, that becomes its own focused migration with the Flutter side
-- updated in the same PR.
--
-- (No SQL needed in this section — keeping the heading for the audit trail.)

-- ── 5) gig_images storage bucket + policies ───────────────────────────
insert into storage.buckets (id, name, public)
values ('gig_images', 'gig_images', true)
on conflict (id) do nothing;

drop policy if exists "read_all_gig_images"   on storage.objects;
drop policy if exists "write_own_gig_image"   on storage.objects;
drop policy if exists "delete_own_gig_image"  on storage.objects;

create policy "read_all_gig_images" on storage.objects
  for select using (bucket_id = 'gig_images');

-- Path convention: gig_images/<auth.uid>/<filename> — so the first path
-- segment must match the caller's user id. My create_gig_page.dart
-- already writes files in this shape.
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

select 1 as delta_migration_ok;
