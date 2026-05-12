# JamUP — Requirements Traceability Matrix

> This document maps every **Functional Requirement (FR)** from the Software
> Requirements Specification to the **Unit Tests (UT)** and **System Tests (ST)**
> that verify it. Run `flutter test test/` to execute all tests.

---

## 1. Test Suite Summary

| Suite | Files | Tests | Command |
|-------|-------|-------|---------|
| Unit Tests | 11 | 98 | `flutter test test/unit/` |
| System Tests | 27 | 88 | `flutter test test/system/` |
| **Total** | **38** | **186** | `flutter test test/` |

### Unit Test Index

| ID | File | Tests | Covers |
|----|------|-------|--------|
| UT-01 | `test/unit/controllers/booking_controller_test.dart` | 7 | BookingController state machine |
| UT-02 | `test/unit/controllers/gig_controller_test.dart` | 18 | GigController filtering & loading |
| UT-03 | `test/unit/core/distance_calculation_test.dart` | 4 | Haversine distance formula |
| UT-04 | `test/unit/core/filter_state_test.dart` | 10 | FilterState genre/type/location/price |
| UT-05 | `test/unit/core/pay_label_test.dart` | 13 | payLabel() formatting |
| UT-06 | `test/unit/models/booking_model_test.dart` | 4 | Booking model serialisation |
| UT-07 | `test/unit/models/gig_model_test.dart` | 11 | Gig model serialisation |
| UT-08 | `test/unit/models/musician_model_test.dart` | 10 | Musician model & derived fields |
| UT-09 | `test/unit/models/schedule_item_test.dart` | 3 | ScheduleItem model |
| UT-10 | `test/unit/models/venue_model_test.dart` | 11 | Venue model serialisation |
| UT-11 | `test/unit/services/favorites_service_test.dart` | 7 | FavoritesService cache & toggle |

### System Test Index

| ID | File | Tests | Feature |
|----|------|-------|---------|
| ST-01 | `test/system/st01_login_renders_test.dart` | 3 | Login page UI |
| ST-02 | `test/system/st02_login_validation_test.dart` | 2 | Login form validation |
| ST-03 | `test/system/st03_register_venue_role_test.dart` | 3 | Register with Venue role |
| ST-04 | `test/system/st04_gig_card_renders_test.dart` | 3 | GigCard widget |
| ST-05 | `test/system/st05_gig_detail_info_test.dart` | 3 | Gig detail — info display |
| ST-06 | `test/system/st06_gig_detail_book_button_test.dart` | 2 | Gig detail — page render |
| ST-07 | `test/system/st07_create_gig_form_renders_test.dart` | 3 | Create Gig form fields |
| ST-08 | `test/system/st08_create_gig_validation_test.dart` | 2 | Create Gig validation |
| ST-09 | `test/system/st09_musicians_page_loading_test.dart` | 3 | Musicians browse page |
| ST-10 | `test/system/st10_musician_detail_profile_test.dart` | 3 | Musician detail — profile |
| ST-11 | `test/system/st11_musician_detail_genre_test.dart` | 3 | Musician detail — genre & share |
| ST-12 | `test/system/st12_venue_my_gigs_no_user_test.dart` | 2 | Venue My Gigs page |
| ST-13 | `test/system/st13_create_gig_genre_chips_test.dart` | 3 | Create Gig genre selection |
| ST-14 | `test/system/st14_create_booking_renders_test.dart` | 3 | Create Booking page |
| ST-15 | `test/system/st15_venue_confirm_booking_test.dart` | 4 | Venue confirms booking |
| ST-16 | `test/system/st16_my_bookings_filter_chips_test.dart` | 3 | My Bookings page |
| ST-17 | `test/system/st17_my_bookings_loading_test.dart` | 3 | My Bookings loading state |
| ST-18 | `test/system/st18_gig_detail_description_test.dart` | 3 | Gig detail — description |
| ST-19 | `test/system/st19_messages_page_renders_test.dart` | 2 | Messages inbox page |
| ST-20 | `test/system/st20_favorite_heart_button_test.dart` | 3 | Favorite heart button |
| ST-21 | `test/system/st21_edit_profile_form_renders_test.dart` | 3 | Edit Profile form |
| ST-22 | `test/system/st22_favorites_empty_state_test.dart` | 3 | Favorites empty state |
| ST-23 | `test/system/st23_venue_profile_trust_test.dart` | 6 | Venue trust profile page |
| ST-24 | `test/system/st24_musician_review_venue_test.dart` | 4 | Musician reviews venue |
| ST-25 | `test/system/st25_venue_decline_booking_test.dart` | 5 | Venue declines booking |
| ST-26 | `test/system/st26_register_musician_test.dart` | 6 | Register Musician account |
| ST-27 | `test/system/st27_venue_edit_gig_test.dart` | 5 | Venue edits existing gig |

---

## 2. Functional Requirements

| FR-ID | Requirement Description |
|-------|------------------------|
| FR-01 | The system shall allow new users to register with email, password, display name, and role (Musician or Venue). |
| FR-02 | The system shall allow registered users to log in with email and password and validate empty fields before submission. |
| FR-03 | The system shall display a list of available gigs, each showing title, location, date, genre badge, and payment. |
| FR-04 | The system shall allow users to view the full detail of a gig including description, role needed, and payment rate. |
| FR-05 | The system shall allow venue users to create new gig postings with title, description, date, location, genres, role, and budget. |
| FR-06 | The system shall allow venue users to edit the details of their existing gig postings. |
| FR-07 | The system shall display a browseable list of registered musicians. |
| FR-08 | The system shall display a musician's full profile including name, bio, genre tags, and price range. |
| FR-09 | The system shall display a venue's trust profile showing review count, gigs hosted, member-since date, open gigs, and past events. |
| FR-10 | The system shall allow musician users to apply for (book) a gig and see the gig information before submitting. |
| FR-11 | The system shall allow venue users to confirm a pending booking request, updating the status badge and removing the action buttons. |
| FR-12 | The system shall allow venue users to decline a pending booking request with the same status-update behaviour. |
| FR-13 | The system shall allow musician users to view all their booking requests and render the page in all states (loading, error, settled). |
| FR-14 | The system shall allow venue users to view incoming booking requests and manage them. |
| FR-15 | The system shall allow musician users to leave a star rating and comment review for a venue after a booking. |
| FR-16 | The system shall allow users to mark gigs as favourites using a heart button and view their saved list. |
| FR-17 | The system shall provide an inbox for viewing message conversations. |
| FR-18 | The system shall allow venue users to manage their posted gigs and see a prompt to sign in when unauthenticated. |
| FR-19 | The system shall allow users to edit their profile information including name, bio, and save the changes. |

---

## 3. Traceability Matrix

| FR-ID | Requirement (short) | Related UT | Related ST | Status |
|-------|---------------------|-----------|-----------|--------|
| FR-01 | User Registration | UT-08 | ST-03, ST-26 | ✅ Verified |
| FR-02 | User Login & Validation | — | ST-01, ST-02 | ✅ Verified |
| FR-03 | Browse Gigs — card display | UT-05, UT-07 | ST-04 | ✅ Verified |
| FR-04 | Gig Detail — info & description | UT-07 | ST-05, ST-06, ST-18 | ✅ Verified |
| FR-05 | Create Gig — form & validation | UT-02, UT-07 | ST-07, ST-08, ST-13 | ✅ Verified |
| FR-06 | Edit Gig | UT-02, UT-07 | ST-27 | ✅ Verified |
| FR-07 | Browse Musicians | UT-08 | ST-09 | ✅ Verified |
| FR-08 | Musician Detail Profile | UT-08 | ST-10, ST-11 | ✅ Verified |
| FR-09 | Venue Trust Profile | UT-10 | ST-23 | ✅ Verified |
| FR-10 | Apply / Book a Gig | UT-01, UT-06 | ST-14 | ✅ Verified |
| FR-11 | Confirm Booking | UT-01, UT-06 | ST-15 | ✅ Verified |
| FR-12 | Decline Booking | UT-01, UT-06 | ST-25 | ✅ Verified |
| FR-13 | Musician Booking View | UT-01, UT-06, UT-09 | ST-16, ST-17 | ✅ Verified |
| FR-14 | Venue Booking Management | UT-01, UT-06 | ST-15, ST-25 | ✅ Verified |
| FR-15 | Review Venue | — | ST-24 | ✅ Verified |
| FR-16 | Favourite Gigs | UT-11 | ST-20, ST-22 | ✅ Verified |
| FR-17 | Messaging Inbox | — | ST-19 | ✅ Verified |
| FR-18 | Venue Gig Management | UT-02, UT-07 | ST-12 | ✅ Verified |
| FR-19 | Edit Profile | — | ST-21 | ✅ Verified |

---

## 4. Coverage Summary

| Layer | Tests Passing | Notes |
|-------|--------------|-------|
| Unit | 98 / 98 | Models, controllers, services, utilities |
| System | 88 / 88 | End-to-end widget flows for all 27 STs |
| **Total** | **186 / 186** | All requirements have at least one UT or ST |

Every Functional Requirement (FR-01 through FR-19) is covered by at least one
passing System Test. Twelve of the nineteen requirements are additionally backed
by Unit Tests that verify the underlying model, controller, or service layer.

---

*Generated for JamUP presentation — `flutter test test/` verifies all 186 tests pass.*
