# JamupProject
 
JamUP — Flutter MVP README

A quick, copy-paste checklist to take your solo project from mock UI to a working MVP with Supabase (auth, storage, database) and clean architecture.

✅ What you’ll build (MVP scope)

Home (location + upcoming/nearby gigs)

Gigs list + Gig detail → Book Now

Messages (per booking chat)

Musicians directory (basic list)

Profile (view + edit + avatar upload)

My Bookings (Musician dashboard)

My Gigs (Venue dashboard with confirm/decline)

Bottom nav: Home · Gigs · Musicians · Messages · Profile

📁 Project structure (finalized)
lib/
  core/
    config/                 # keys, env helpers (dev-only)
    constants/              # colors, fonts, app constants
    services/               # supabase client, api helpers (if any)
  features/
    home/
      pages/
      widgets/
    gigs/
      controllers/
      data/
      models/               # (Gig model can live here or in /models root)
      pages/
      widgets/
    bookings/
      controllers/
      data/
      pages/
    messages/
      controllers/
      data/
      pages/
      widgets/
    musicians/
      controllers/
      data/
      pages/
      widgets/
    profile/
      pages/                # ProfilePage, EditProfilePage, SettingsPage
  models/                    # Shared models (Gig, Musician, Venue, User)
  main.dart


Stick to this layout to avoid confusion later.

🧰 Prerequisites

Flutter SDK installed

Dart >= 3.x

VS Code / Android Studio

Android emulator or iOS simulator / device

Supabase account + new project

🚀 Quick start (15–20 min)
1) Clone + dependencies
flutter pub get

2) Add packages (if not present)
flutter pub add supabase_flutter provider image_picker google_fonts


iOS: also run cd ios && pod install && cd .. after pub get as needed.

3) Configure Supabase in main.dart

In main():

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);


You can temporarily hardcode keys while developing, but move to lib/core/config/supabase_keys.dart (git-ignored) or use flutter_dotenv later.

4) Android & iOS permissions

Android android/app/src/main/AndroidManifest.xml:

(Already good for basic Flutter)

For camera/gallery (image picker) add if missing:

<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>


iOS ios/Runner/Info.plist:

<key>NSPhotoLibraryUsageDescription</key>
<string>We use your photo for profile avatar.</string>
<key>NSCameraUsageDescription</key>
<string>We use your camera for profile avatar.</string>

5) Supabase: create tables & storage

In the Supabase SQL editor, create minimal tables:

-- users (mirrors auth.users info you care about)
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  bio text,
  role text check (role in ('musician','venue')),
  avatar_url text
);

-- gigs
create table if not exists public.gigs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date text not null,           -- simplify for MVP
  location text not null,
  image_url text,               -- public URL or storage public URL
  venue_id uuid not null references public.users(id) on delete cascade
);

-- bookings
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  gig_id uuid not null references public.gigs(id) on delete cascade,
  musician_id uuid not null references public.users(id) on delete cascade,
  venue_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','confirmed','declined')),
  created_at timestamp with time zone default now()
);

-- chats (one chat per booking)
create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade
);

-- messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid references public.users(id) on delete set null,
  text text not null,
  type text not null default 'user' check (type in ('user','system')),
  created_at timestamp with time zone default now()
);


RLS (Row Level Security) on all tables, with policies for read/write by owners. You can start with RLS off until things work, then enable progressively.

Storage:

Create a bucket: avatars (public or signed; MVP can be public).

RLS path pattern used by the app: avatars/{user.id}/avatar.png

Storage policy (if public with path guard):

-- Example: Allow users to read all, write only to their folder
-- Adjust for your security needs


In the app we upload to: avatars/<user.id>/avatar.<ext> (matches your current code).

6) Ensure minimal auth (temp)

For quick testing, use Email + Password from the Supabase dashboard (Auth → Users → Create user). Later you can add a simple sign-in screen.

🧩 Wire-up checklist (per feature)
Profile

 ProfilePage displays current user metadata and avatar.

 EditProfilePage updates Supabase auth metadata + public.users.

 Avatar upload to avatars/<user.id>/avatar.<ext> (done in your code).

 If auth.currentUser == null, show a sign-in prompt.

Gigs

 GigRepository.fetchAllGigs() selects: id, title, date, location, image_url, venue_id.

 GigPage uses GigController + Provider to load/display gigs.

 Filters work on genres (MVP can be a simple client-side filter or extra column later).

Gig Detail → Booking

 On Book Now, create a row in bookings with:

gig_id, musician_id = auth.user.id, venue_id = gig.venue_id, status = 'pending'.

 Create chats row linked to booking.

 Insert a messages system row: "⏳ Booking request sent".

 Navigate to ChatPage.

My Gigs (Venue dashboard)

 Uses auth.currentUser.id as venueId.

 Loads bookings with: id, status, musicians(name, avatar_url), gigs(title, date).

 Confirm/Decline updates bookings.status and inserts a system message (✅ or ❌).

 Tap to open ChatPage.

My Bookings (Musician dashboard)

 Uses auth.currentUser.id as musicianId.

 Loads bookings with: id, status, gigs(title, date, location, image_url).

 Tap to open ChatPage (show current status icon).

Messages

 ChatPage shows message list for a chat_id (MVP can mock; later load by booking→chat).

 Sending user messages inserts into messages with type='user'.

🔑 Places to swap mock → real IDs

 GigDetailPage → use me.id and gig.venueId

 MyGigsPage → use auth.currentUser.id

 MyBookingsPage → use auth.currentUser.id

 HomePage lists → call repo methods, not hardcoded lists

🧪 Run
flutter run


Test flow (as Musician):

Sign in → Profile → Edit → upload avatar → Save.

Gigs → Open a gig → Book Now → lands on Chat.

Profile → My Bookings → see status (pending).

Test flow (as Venue):

Sign in (venue account).

Profile → My Gigs → see incoming booking → confirm/decline → open Chat.

🧭 Roadmap (after MVP)

 Auth UI (email/password or magic link)

 Realtime messages (Supabase realtime on messages)

 Push notifications (FCM)

 Payments (Stripe) & booking deposits

 Better filters (date range, distance)

 Role setup wizard after sign-up (musician vs venue)

🛠 Troubleshooting

Null currentUser: You’re not signed in. Add a quick sign-in screen or seed a test user.

Images not loading: If no internet or blocked domain, replace placeholders with Supabase Storage public URLs.

RLS errors: Disable RLS during early development, then add table policies carefully.

iOS build issues: cd ios && pod install, ensure deployment target is compatible.