# JamUP Test Suite

Two layers of tests, mapped to your professor's "unit + system" requirement.

**Current totals: 70 unit test cases (across 9 files) + 22 documented system test cases.**
See `JamUP-TestPlan.docx` (in the project root) for the full traceability matrix
mapping every test back to URS / SRS / UC IDs.

## Layout

```
test/
├── unit/                            # Pure-Dart, runs offline
│   ├── models/                      # JSON parsing, value-object semantics
│   │   ├── gig_model_test.dart
│   │   ├── booking_model_test.dart
│   │   ├── musician_model_test.dart
│   │   └── schedule_item_test.dart
│   ├── controllers/                 # ChangeNotifier + filter/sort logic
│   │   ├── gig_controller_test.dart
│   │   └── booking_controller_test.dart
│   ├── core/                        # Cross-cutting pure logic
│   │   ├── filter_state_test.dart
│   │   └── distance_calculation_test.dart
│   └── services/                    # Singletons / cross-feature services
│       └── favorites_service_test.dart
├── system/                          # IEEE-829 manual test scripts
│   └── system_test_case.md
├── TESTING_PLAN.md                  # Strategy + test pyramid rationale
└── README.md                        # this file
```

The folder structure mirrors `lib/` so when you change a file, you know
exactly which test folder to open. This convention is used by every
serious Flutter project (see flutter/samples).

## How to run

### Unit tests (run constantly during dev)

```bash
flutter test test/unit
```

You can also run a single layer:

```bash
flutter test test/unit/models       # 4 model files
flutter test test/unit/controllers  # 2 controller files
flutter test test/unit/core         # 2 core files
flutter test test/unit/services     # 1 service file
```

### System tests (manual, follow the script during a demo)

`test/system/system_test_case.md` contains 22 documented test cases
(ST-01 through ST-22). Each has Steps, Expected Result, and Status —
the standard IEEE-829 lite format. Walk through them on a real device
during your demo to demonstrate end-to-end coverage.

## Why this split

* **Unit tests** target pure logic (models, controllers, services) and
  run in milliseconds with no Supabase, no network, no flakiness. They
  catch bugs *before* you launch the app.
* **System tests** target real user journeys against a real backend.
  They're slower but prove the whole stack works together.

This is the canonical "test pyramid" pattern (Mike Cohn, *Succeeding
with Agile*, 2009): many fast unit tests at the bottom, a few slow
system tests at the top.
