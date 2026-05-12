# JamUP

> **Connecting musicians and venues — one gig at a time.**

JamUP is a full-stack mobile application built with **Flutter** and **Supabase** that solves a real problem in the live music industry: musicians struggle to find gigs, and venues struggle to find performers. JamUP brings both sides together on a single platform with real-time booking, in-app messaging, GPS-based discovery, and push notifications.

Built as a solo scholarship project at the **Software Engineering Program, Chiang Mai University**.

---

## Features

**For Musicians**
- Browse and search upcoming gigs with genre, type, and price filters
- View full gig details and apply with one tap
- Real-time in-app chat with venues after booking
- Track booking status (pending → confirmed → declined) on a personal dashboard
- Save favourite gigs and revisit them anytime
- View and manage your performance schedule in a calendar
- Upload a portfolio of images to your public profile
- Discover other musicians and venues near your current location

**For Venues**
- Post, edit, and delete gig listings with cover images, Google Places location, date/time, genre tags, and pay rate
- Review incoming musician applications and confirm or decline with one tap
- Manage all your gigs and bookings from a dedicated dashboard
- Leave star-rating reviews for musicians after a performance
- Trust profile page showing review average, gigs hosted count, and open listings

**Platform-wide**
- Role-based access control (Musician vs Venue) enforced throughout the UI and database
- Push notifications via OneSignal for booking decisions and new messages
- GPS-powered "Nearby Gigs" and "Nearby Musicians" powered by custom Supabase RPC functions using the Haversine formula
- Share gigs to external apps or send them directly into an existing chat
- Change password and manage notification preferences in Settings

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3 (Dart) |
| State management | Provider + ChangeNotifier |
| Backend & database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth (email/password, PKCE flow) |
| Real-time messaging | Supabase Realtime (WebSocket streams) |
| Push notifications | OneSignal Flutter SDK |
| Location & maps | Geolocator · Geocoding · Google Places Flutter |
| File storage | Supabase Storage (avatars, gig images, portfolio) |
| Environment config | flutter_dotenv |
| Sharing | share_plus |
| Calendar view | table_calendar |

---

## Architecture

The project follows a **feature-first clean architecture** that mirrors the structure recommended by the Flutter team. Each feature is self-contained with its own pages, widgets, data layer, and controller.

```
lib/
├── core/
│   ├── constants/          # Colors, fonts, app-wide constants
│   ├── filters/            # Shared FilterState (genre, type, price, location)
│   ├── services/           # Auth, Location, Nearby, Notification, Portfolio, Favorites
│   ├── utils/              # Pure functions (pay label formatter, etc.)
│   └── widgets/            # Shared widgets (FavoriteHeartButton, FilterBar, PortfolioGrid)
├── features/
│   ├── auth/               # Login, Register, AuthGate
│   ├── booking/            # CreateBooking, MyBookings, VenueBookings, Schedule, BookingDetail
│   ├── favorites/          # FavoritesPage
│   ├── gigs/               # GigPage, GigDetail, CreateGig, EditGig, VenueMyGigs
│   ├── home/               # HomePage (upcoming + nearby gigs feed)
│   ├── messages/           # MessagesPage (inbox), ChatPage, ChatBubble
│   ├── musicians/          # MusiciansPage (All / Nearby toggle), MusicianDetail
│   ├── notifications/      # NotificationsPage (real-time stream, swipe to dismiss)
│   ├── profile/            # ProfilePage, EditProfile, Settings, ProfileAvatar
│   ├── reviews/            # ReviewPage, ReviewWidget, ReviewRepository
│   └── venues/             # VenueDetailPage (trust profile)
├── models/                 # Shared models: Gig, Musician, Venue, Booking, ScheduleItem
└── main.dart
```

**Key design decisions:**
- Repositories abstract all Supabase calls — controllers never touch the client directly, which makes them fully unit-testable with mock repositories
- `NearbyService` calls custom PostgreSQL RPC functions (`get_nearby_gigs`, `get_nearby_musicians`) that run the Haversine distance formula inside the database, so only nearby rows travel over the network
- `FavoritesService` uses a `ValueNotifier<Set<String>>` so the heart button rebuilds reactively anywhere on screen without `setState` or `Provider`
- `OneSignal` device tokens are stored in a `device_tokens` table and cleaned up on logout, preventing ghost notifications to signed-out devices

---

## Testing

The project has **186 automated tests** covering every functional requirement defined in the SRS.

```
flutter test test/
```

| Suite | Files | Tests | Command |
|---|---|---|---|
| Unit tests | 11 | 98 | `flutter test test/unit/` |
| System tests | 27 | 88 | `flutter test test/system/` |
| **Total** | **38** | **186** | `flutter test test/` |

**Unit tests** cover models (JSON serialisation, null safety, derived fields), controllers (state machine transitions, filter logic, optimistic UI rollback), services (Haversine distance, pay label formatting, favorites toggle), and the booking controller's conflict detection.

**System tests** are automated Flutter widget tests (`testWidgets`) that pump real pages with fake repositories and assert on rendered output. They prove every user-facing flow — login validation, gig card rendering, booking confirmation, decline flow, review submission, registration, and more — without needing a live Supabase connection.

All 19 Functional Requirements (FR-01 through FR-19) are traced to at least one passing test in `docs/traceability_matrix.md`.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.5
- Dart ≥ 3.x
- A Supabase project
- A OneSignal app (for push notifications)
- Google Places API key (for location search on gig creation)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-username/jamup-project.git
cd jamup-project

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Fill in your keys in .env:
#   SUPABASE_URL=
#   SUPABASE_KEY=
#   GOOGLE_PLACES_API_KEY=

# 4. Run the app
flutter run
```

### Running tests

```bash
# All tests
flutter test test/

# Unit tests only
flutter test test/unit/

# System tests only
flutter test test/system/
```

---

## Documentation

The project includes a full set of formal software engineering documents:

| Document | Description |
|---|---|
| `JamUP-SRS.pdf` | Software Requirements Specification (URS + SRS, 52 requirements) |
| `JamUP-SDD_v3.0.pdf` | Software Design Document |
| `JamUP-TestPlan_v2.0.pdf` | Test Plan (unit, system, and UAT strategy) |
| `JamUP-TestRecord_v1.0.pdf` | Test Record with results |
| `JamUP-Traceability_v3.0.pdf` | Requirements Traceability Matrix |
| `docs/traceability_matrix.md` | Live markdown traceability matrix (FR → UT/ST) |
| `test/system/system_test_case.md` | System test case descriptions matching the dart files |
| `test/TESTING_PLAN.md` | Developer-facing testing guide and coverage targets |

---

## Author

**Pawat Mungmuang**
Bachelor of Science — Software Engineering
College of Arts, Media and Technology, Chiang Mai University
Student ID: 652115038

Project Advisor: Asst. Prof. Dr. Chartchai Doungsa-ard
