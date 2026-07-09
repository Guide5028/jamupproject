# 🎤 JamUp — Demo Day Checklist

Keep this open during your exam. Run through Section 1 about **15 minutes before** you present.

Handy paths (copy-paste ready):
- adb: `~/Library/Android/sdk/platform-tools/adb`
- emulator: `~/Library/Android/sdk/emulator/emulator`
- AVD name: `Pixel_8`
- App package: `com.example.jamupproject`

---

## 1. Pre-flight (do this 15 min before)

**a) Start the emulator and confirm it has internet**
- Open the emulator, launch **Chrome inside it**, load `google.com`.
- ✅ Loads → you're good.
- ❌ Doesn't load → the emulator lost DNS. Kill it and relaunch with a DNS server:
  ```bash
  ~/Library/Android/sdk/platform-tools/adb -e emu kill
  ~/Library/Android/sdk/emulator/emulator -avd Pixel_8 -dns-server 8.8.8.8,8.8.4.4
  ```
  (No internet = Supabase can't load data. This is the #1 thing to verify.)

**b) Clean install + run**
```bash
~/Library/Android/sdk/platform-tools/adb uninstall com.example.jamupproject
flutter run
```
(The uninstall keeps old OneSignal junk out of the logs. Skip it if you're short on time — it's optional.)

**c) Location**
- Location is currently set to **mock Chiang Mai** in code (`_useMockLocation = true` in `lib/core/services/location_service.dart`), so the city + nearby gigs/musicians **just work** — no GPS setup needed for the demo. ✅
- If you ever flip mock off and want real emulator GPS, set it with:
  ```bash
  ~/Library/Android/sdk/platform-tools/adb emu geo fix 98.9547 18.8082
  ```
  (longitude first, then latitude — Chiang Mai University)

---

## 2. What a HEALTHY startup log looks like

You want to see these lines, in roughly this order:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
supabase.supabase_flutter: INFO: ***** Supabase init completed *****
⚠️ ONESIGNAL_APP_ID missing/invalid — skipping push setup.   ← expected & harmless
```

**Safe to ignore** (these are normal, NOT errors):
- All the `Warning: Flutter support for your project's Gradle/AGP/Kotlin version…` lines — just future-version notices.
- `FlutterJNI: Sending viewport metrics`, `ImeTracker`, `InsetsController`, `Width is zero` — normal rendering/keyboard logs.
- The OneSignal "skipping push setup" line — intentional (push isn't configured yet).

**Bad signs** (and the fix):
- `Failed host lookup: '…supabase.co'` → emulator has no internet → see 1a.
- App stuck on the logo → a startup crash; read the first red `E/flutter` line.

---

## 3. Suggested demo flow (show off the polish)

1. **Launch** → note the shimmer skeleton loaders, then the home hero ("Your stage, one tap away") with real gig prices.
2. **Tap a gig** → smooth fade-up page transition → polished Booking Details card.
3. **Musicians tab** → cards fade in with a stagger; tap the ❤️ → it pops (animation) and saves.
4. **Tap into a musician's profile → Portfolio** → scroll the grid (3 photos), then tap the **video tile** (▶ badge, "Live set highlight") → it opens fullscreen and actually plays. Tap the video to pause/resume.
5. **Profile → Favorite Musicians** (as a venue) → the musician you just hearted is there.
6. **Schedule** → green dots mark days with confirmed gigs; today is the white ring.
7. **Apply to a gig** ("Apply Now") → show it appears under **My Applications**.

**Demo video note:** the musician account (`Musician test`) has a sample video pre-loaded in its portfolio (Supabase `portfolio` table, row description "Live set highlight"). Its `media_url` is `asset:assets/videos/demo_performance.mp4` — a **bundled local file**, not a network URL, deliberately, after testing showed the emulator's network couldn't reliably stream from external CDNs (Google Cloud Storage, GitHub Pages, w3schools all timed out mid-download on-device even though they were reachable from the host machine — likely the emulator's virtual network struggling with sustained transfers, not a DNS issue). A local asset plays instantly with zero network risk during the live demo.

To swap in real performance footage: replace `assets/videos/demo_performance.mp4` with your own short clip (keep it small, <5MB, for fast app installs), run `flutter pub get`, and hot-restart (not just hot reload — new asset files need a restart). If you'd rather serve it from Supabase Storage instead, you'll need to upload it while logged in as that musician (RLS requires the uploader's `auth.uid()` to match the storage folder) and set `media_url` back to a plain `https://...` URL — `video_player_page.dart` handles both `asset:` and network URLs automatically.

---

## 3b. Detailed app flow (for walkthrough / presentation script)

**Personas:** the app has two roles — **Musician** (lists their act, applies to gigs) and **Venue** (posts gigs, books musicians). Role is set at signup and drives which screens/actions are available.

1. **Auth** ([auth_gate.dart](lib/features/auth/widgets/auth_gate.dart)) — Supabase email/password auth gates the whole app; `AuthGate` listens to the auth stream and routes to Home once signed in.
2. **Home** ([home_page.dart](lib/features/home/pages/home_page.dart)) — on load: detects city via `LocationService` (mocked to Chiang Mai for demo reliability), fetches *Upcoming*, *Nearby* (PostGIS RPC `get_nearby_gigs`), and *Recommended* (matched to the user's genre) gigs in parallel. Shows a shimmer skeleton while loading, then a hero header + horizontally-scrolling gig carousels + a nearby-gigs grid.
3. **Browse Gigs** (`GigPage`) — full searchable/filterable list (genre, type, location, price) of all open gigs, each rendered with `GigCard` (cached/downscaled cover image, distance badge, favorite heart).
4. **Gig Detail → Apply** (`GigDetailPage`) — full gig info; a musician taps **Apply Now**, which writes a row to `bookings` (status `pending`); shows up immediately under **My Applications**.
5. **Musicians tab** ([musicians_page.dart](lib/features/musicians/pages/musicians_page.dart)) — venues browse musician profiles. Toggle between **All** and **Nearby** (RPC-backed). Search + filter chips narrow results; cards stagger-fade in (`FadeInUp`).
6. **Musician Profile → Portfolio** ([portfolio_grid.dart](lib/core/widgets/portfolio_grid.dart)) — a 2-column grid of the musician's uploaded photos/videos (Supabase Storage bucket `portfolio` + metadata table `portfolio`). Tapping a photo shows it; tapping a video opens the new fullscreen player ([video_player_page.dart](lib/core/widgets/video_player_page.dart)).
7. **Favoriting** — hearts on both gig cards and musician cards write to `favorites` / `favorite_musicians`; **Profile → Favorites / Favorite Musicians** lists them back out, each backed by a realtime-aware service so the heart state stays in sync across screens.
8. **Booking lifecycle** ([my_bookings_page.dart](lib/features/booking/pages/my_bookings_page.dart), [booking_detail_page.dart](lib/features/booking/pages/booking_detail_page.dart)) — venue accepts/declines an application → `bookings.status` updates → musician gets a notification (`notifications` table, pushed in-app and optionally via OneSignal).
9. **Schedule** ([schedule_page.dart](lib/features/booking/pages/schedule_page.dart)) — calendar view (`table_calendar`) marks days with confirmed bookings with a green dot; today gets a white ring.
10. **Notifications** — bell icon on Home shows a live unread-count badge via a Supabase realtime `stream()` on the `notifications` table; tapping opens the full notifications list.

**Data backbone (Supabase project "JamUP's Project", `yaxfmxenmotfjvzdyphz`):** `users`, `gigs`, `bookings`, `chats`/`messages`, `reviews`, `notifications`, `device_tokens`, `portfolio`, `favorites`, `favorite_musicians` — all with RLS enabled, so each user only reads/writes rows they're allowed to.

---

## 4. If something breaks live (30-second recovery)

1. **Stay calm** — say "let me restart the emulator connection." It buys time and sounds professional.
2. In the `flutter run` terminal, press **`R`** (hot restart). Fixes most UI/state glitches.
3. No data showing? → emulator internet died. Press `q`, run the DNS relaunch from 1a, then `flutter run`.
4. Worst case → run the full clean install from 1b.

You've got this. 🎸
