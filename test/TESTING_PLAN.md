# JamUP Testing Plan

_A learning-oriented test plan for the JamUP Flutter + Supabase project._
_Last reviewed: 2026-04-21_

---

## 1. How to think about "how many tests do I need?"

Software engineers don't pick a number like "I need 30 tests." We use a **model called the Testing Pyramid** (introduced by Mike Cohn, _Succeeding with Agile_, 2009). It says:

- **Lots** of small **unit tests** at the bottom (fast, cheap, run all the time)
- **Some** integration / widget tests in the middle (slower, test wiring)
- **A few** end-to-end / system tests at the top (slowest, test real user journeys)

**Why this shape?** Because unit tests are cheap to write and run in milliseconds, so you can afford many of them. System tests are slow and brittle (a network hiccup can fail them), so you only write them for the _most important_ user journeys.

> Reference: Martin Fowler, _TestPyramid_ — https://martinfowler.com/bliki/TestPyramid.html
> Flutter official guide — https://docs.flutter.dev/testing/overview
> Flutter cookbook — https://docs.flutter.dev/cookbook/testing/unit/introduction

For a university scholarship project, a reasonable target is:

| Level          | Target count | What it proves                                |
| -------------- | ------------ | --------------------------------------------- |
| Unit tests     | **20 – 30**  | Your logic is correct in isolation            |
| Widget tests   | **5 – 10**   | Your UI components render & react correctly   |
| System tests   | **12 – 18**  | The whole app works for real user journeys    |

You already have 4 unit tests and 7 system tests. My recommendation below adds **~20 more unit tests** and **~10 more system tests** so your work shows real engineering rigour.

---

## 2. What each kind of test is actually for

### Unit tests (Dart `test` package)
These test **one function or one class in isolation**. No Flutter widgets, no real Supabase — you mock the repository layer. They are fast (ms) and run on every save if you use `flutter test --watch`.

**When a test is a "unit test":** if you can delete the whole `lib/features` folder and this test still runs and passes, it's probably a proper unit test of pure logic.

### Widget tests (Flutter's `flutter_test` package)
These pump a widget into a fake tree and check "when I tap this button, does the right thing show up?" They are mid-speed. Good for `gig_card`, `filter_bar`, `chat_bubble`.

### System tests (documented manual tests, or `integration_test` package)
These drive the **real app** against a **real backend** (Supabase) and check a whole user journey. They're slow and flaky, so you keep only the most important journeys.

> Reference: https://docs.flutter.dev/testing/integration-tests

---

## 3. Unit tests you should write (target ~25)

I grouped them by what they prove. Each one is small and focused — **one behaviour per test**.

### 3a. Model tests (pure data, no network, very easy wins)
Why: models do JSON parsing and serialization. A wrong field name and your whole app breaks silently. These are the _cheapest tests per unit of value_ you can write.

1. `gig_model_test.dart` — ✅ you already have this
2. `booking_model_test.dart` — `fromJson` builds a Booking, `toJson` round-trips, handles null `cancelled_at`
3. `musician_model_test.dart` — parses genres list, handles missing profile_image
4. `schedule_item_model_test.dart` — date parsing, equality

### 3b. Controller tests (state logic — the brains of your app)
Why: controllers decide what gets shown. A bug here = wrong data on screen. You mock the repo so no Supabase is called. Use `mocktail` package.

5. `gig_controller_test.dart` — ✅ you have one; **expand** to cover:
   - sorting by `dateAsc`, `dateDesc`, `titleAz`, `distance`
   - filtering by genre sets (empty, one, multiple)
   - `isNearbyMode = true` filters by `radiusKm`
   - `loading` and `error` states are set correctly on failure
6. `booking_controller_test.dart` — accept, reject, cancel transitions; optimistic UI rollback on error
7. `messages_controller_test.dart` — mark-as-read updates count; new message appends to list

### 3c. Repository tests (data layer, mocked Supabase client)
Why: repositories translate Supabase responses into model objects. Bugs here cause silent data corruption.

8. `gig_repository_test.dart` — `fetchGigs()` maps rows to `Gig` list; handles empty; bubbles error
9. `booking_repository_test.dart` — status filter, create/update payload shape
10. `musician_repository_test.dart` — search by name with `ilike`
11. `review_repository_test.dart` — average rating aggregation
12. `profile_repository_test.dart` — upload path formatting

### 3d. Service tests (cross-cutting concerns)
13. `auth_service_test.dart` — sign in / sign up happy path, wrong password error
14. `location_service_test.dart` — permission denied fallback; distance between two coords (you have distance ✅)
15. `portfolio_service_test.dart` — file size limit rejects oversized uploads
16. `notification_service_test.dart` — formats payload correctly; handles device token refresh

### 3e. Pure logic tests
17. `filter_state_test.dart` — ✅ you have this; add test for clearing, toggling same value twice
18. `distance_calculation_test.dart` — ✅ you have this; add edge case (same point = 0 km, antipodal)

**Running total: 4 existing + 14 new = ~18 unit test files, but ~30 individual `test()` cases when you include the multiple `group()` blocks inside each file.**

---

## 4. Widget tests you should write (target ~8)

These are HIGH value for marking because they visibly prove your UI works. Use `flutter_test`'s `tester.pumpWidget`.

1. `gig_card_test.dart` — renders title, shows price, calls callback on tap
2. `filter_bar_test.dart` — selected chips highlight; unselected don't
3. `chat_bubble_test.dart` — "me" bubble aligns right, "them" aligns left
4. `musician_card_test.dart` — shows avatar placeholder when image null
5. `profile_avatar_test.dart` — loading state, error state
6. `login_page_test.dart` — empty email shows validation error
7. `register_page_test.dart` — password mismatch shows error
8. `auth_gate_test.dart` — unauth user sent to login, auth user sent to home

> Reference: https://docs.flutter.dev/cookbook/testing/widget/introduction

---

## 5. System tests you should document (target ~15)

You have 7 — good start. Here's the gap analysis. A good system test suite covers **happy path + sad path + role-based path** for every major feature.

### Already covered ✅
ST-01 Login, ST-02 Search Gigs, ST-03 Filter Musicians, ST-04 Apply for Gig, ST-05 Accept Booking, ST-06 Upload Media, ST-07 Review Musician.

### Missing — you should add these

**Auth & role (prove your security works):**
- ST-08 Register new musician account
- ST-09 Register new venue account
- ST-10 Logout returns to login screen
- ST-11 Login with wrong password shows error (sad path)
- ST-12 Register with existing email shows error (sad path)

**Gigs (venue side):**
- ST-13 Venue creates new gig → gig appears in public feed
- ST-14 Venue edits existing gig → changes visible
- ST-15 Venue deletes gig → gone from feed
- ST-16 Musician cannot create a gig (role-based access)

**Bookings (full lifecycle):**
- ST-17 Venue rejects booking → musician notified, status = rejected
- ST-18 Musician cancels application → removed from venue's list
- ST-19 My Bookings page shows correct status for each booking

**Messaging:**
- ST-20 Send chat message → recipient receives in real-time
- ST-21 Chat history persists after app restart

**Profile & search:**
- ST-22 Edit profile info and save → changes persist after reload
- ST-23 Search musicians by name returns correct results
- ST-24 Nearby gigs filter only shows gigs within selected radius

**Notifications:**
- ST-25 Booking accepted triggers push notification
- ST-26 Notification tap navigates to the correct page

**Why these extras matter:** In real apps, **bugs cluster around the sad path** (wrong password, no network, role mismatch). Testing only the happy path is how production outages happen. Your examiner/marker will expect to see sad-path coverage — it shows engineering maturity.

---

## 6. Packages to add to `pubspec.yaml`

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4        # cleanest way to mock without codegen
  integration_test:       # for real device E2E
    sdk: flutter
```

Why `mocktail` over `mockito`: mockito needs build_runner codegen which is slow and breaks with null-safety edge cases. Mocktail has no codegen and is the modern Flutter community default.

> Reference: https://pub.dev/packages/mocktail

---

## 7. Folder structure recommendation

```
test/
├── unit/
│   ├── models/
│   │   ├── booking_model_test.dart
│   │   ├── gig_model_test.dart            # existing
│   │   └── musician_model_test.dart
│   ├── controllers/
│   │   ├── booking_controller_test.dart
│   │   ├── gig_controller_test.dart       # existing
│   │   └── messages_controller_test.dart
│   ├── repositories/
│   │   ├── gig_repository_test.dart
│   │   └── booking_repository_test.dart
│   ├── services/
│   │   ├── auth_service_test.dart
│   │   └── location_service_test.dart
│   └── core/
│       ├── filter_state_test.dart          # existing
│       └── distance_calculation_test.dart  # existing
├── widget/
│   ├── gig_card_test.dart
│   └── filter_bar_test.dart
└── system/
    └── system_test_case.md                 # existing
```

**Why mirror the `lib/` structure?** Because when you change `lib/features/gigs/`, you know exactly which test folder to open. This is a convention used by almost every serious Flutter project (see https://github.com/flutter/samples).

---

## 8. Order to tackle this (to maximise marks per hour)

1. **Write the model tests first** — they're tiny, fast, and boost your count instantly (2 hours → 3 model files)
2. **Expand controller tests next** — highest value per test because controllers hold the real logic (3 hours)
3. **Add the 10 missing system test cases** to `system_test_case.md` — no code needed, just document (1 hour)
4. **Write 3-4 widget tests** for the most visible cards (login, gig_card, filter_bar) — visually impressive for demos (2 hours)
5. **Service and repository tests last** — harder because they need mocks (3-4 hours)

Total estimated effort: **~11 hours of focused work** to go from a thin test suite to a strong one.

---

## 9. Final targets summary

| Type              | Current | Target    | Gap      |
| ----------------- | ------- | --------- | -------- |
| Unit tests        | 4       | **25**    | **+21**  |
| Widget tests      | 0       | **8**     | **+8**   |
| System tests      | 7       | **18**    | **+11**  |
| **Total tests**   | **11**  | **~51**   | **+40**  |

These numbers are not arbitrary — they come from covering every **controller, repository, service, and model** in your `lib/` folder plus every **major user journey** described in your SRS/SDD documents.

---

## 10. Further reading

- **Testing pyramid:** https://martinfowler.com/bliki/TestPyramid.html
- **Flutter testing overview:** https://docs.flutter.dev/testing/overview
- **Mocking with mocktail:** https://pub.dev/packages/mocktail
- **Effective Dart testing:** https://dart.dev/guides/language/effective-dart
- **Supabase testing strategies:** https://supabase.com/docs/guides/local-development/testing
- **IEEE 829 (Software Test Documentation standard)** — the format your system test cases are loosely following
