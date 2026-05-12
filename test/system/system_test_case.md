JamUP System Test Cases
_Last updated: 2026-05-12 — descriptions now match the automated widget test files in test/system/_

> **How to read this document**
> Each entry below is an **automated widget test** (Flutter `testWidgets`).
> "Input" describes what the test pumps and does; "Expected Result" lists what the code asserts.
> Run all 27 cases with: `flutter test test/system/`


---

ST-01 Login Page Renders
File: st01_login_renders_test.dart

Input:
1. Pump LoginPage inside a MaterialApp.
2. Call pump() once to let the widget settle.

Expected Result:
- An Email TextFormField is visible on screen.
- A Password TextFormField is visible on screen.
- A Login ElevatedButton is visible on screen.

Status: PASS


---

ST-02 Login Form Validation
File: st02_login_validation_test.dart

Input:
1. Pump LoginPage.
2. Tap the Login button with all fields empty.
3. In a second sub-test: enter a valid email, leave password empty, then tap Login.

Expected Result:
- Tapping Login with no data shows a validation error containing "email".
- Tapping Login with email filled but password empty shows a validation error containing "assword" (Password).

Status: PASS


---

ST-03 Register with Venue Role
File: st03_register_venue_role_test.dart

Input:
1. Pump RegisterPage.
2. In a second sub-test: confirm the default selected value.
3. In a third sub-test: open the role dropdown and tap "Venue".

Expected Result:
- A DropdownButtonFormField<String> is present on the page.
- The dropdown defaults to showing "Musician" as the selected value.
- After tapping "Venue" in the menu, the dropdown displays "Venue".

Status: PASS


---

ST-04 Gig Card Renders Key Information
File: st04_gig_card_renders_test.dart

Input:
1. Create a fake Gig: title="Friday Jazz Night", location="Bangkok", genres=["Jazz"], payment=2500.
2. Pump GigCard inside a Scaffold with a fixed 300 px height.

Expected Result:
- The text "Friday Jazz Night" is visible (gig title).
- The text "Bangkok" is visible (location).
- The text "Jazz" is visible (genre badge).

Status: PASS


---

ST-05 Gig Detail Page Shows Gig Information
File: st05_gig_detail_info_test.dart

Input:
1. Create a fake Gig: title="Saturday Blues Session", location="Chiang Mai", roleNeeded="Guitarist", payment=1800, genres=["Blues"].
2. Pump GigDetailPage with that fake Gig.

Expected Result:
- The text "Saturday Blues Session" is visible (gig title).
- Text containing "Chiang Mai" is visible (location).
- Text containing "Guitarist" is visible (role needed).

Status: PASS


---

ST-06 Gig Detail Page Renders and Shows Description
File: st06_gig_detail_book_button_test.dart

Input:
1. Create a fake Gig: title="Open Jazz Jam", description="All musicians welcome.", location="Bangkok", genres=["Jazz"], roleNeeded="Any".
2. Pump GigDetailPage.
3. In a second sub-test: scroll until the description text is visible.

Expected Result:
- A single Scaffold is rendered (page does not crash).
- The text "Open Jazz Jam" is visible.
- After scrolling, the text "All musicians welcome." is visible.

Status: PASS


---

ST-07 Create Gig Form Renders
File: st07_create_gig_form_renders_test.dart

Input:
1. Pump CreateGigPage.
2. In the third sub-test: set surface size to 800×1400 and scroll to reveal the role dropdown.

Expected Result:
- A "Title" TextFormField is present.
- A "Description" TextFormField is present.
- At least one DropdownButtonFormField<String> (role selector) is present after scrolling.

Status: PASS


---

ST-08 Create Gig Validates Required Title
File: st08_create_gig_validation_test.dart

Input:
1. Pump CreateGigPage (surface 800×1400).
2. Scroll to the "Create Gig" ElevatedButton and tap it without filling Title.
3. In a second sub-test: enter "My New Gig" in Title, then tap "Create Gig".

Expected Result:
- Tapping "Create Gig" with an empty title shows the text "Title required".
- After filling a valid title and tapping "Create Gig", "Title required" is NOT shown.

Status: PASS


---

ST-09 Musicians Page Behaviour Without Network
File: st09_musicians_page_loading_test.dart

Input:
1. Pump MusiciansPage (no Supabase session available in test environment).
2. Call pumpAndSettle with a 2-second timeout to let all async calls fail.

Expected Result:
- A Scaffold is rendered without crashing.
- The text "Failed to load musicians 😵" is displayed.
- A "Retry" button is visible in the error state.

Status: PASS


---

ST-10 Musician Detail Page Shows Profile
File: st10_musician_detail_profile_test.dart

Input:
1. Create a fake Musician: name="Nadia Siriwan", bio="Jazz vocalist with 10 years experience performing across Bangkok.", location="Bangkok", genres=["Jazz","Blues"].
2. Pump MusicianDetailPage with that fake Musician.

Expected Result:
- The text "Nadia Siriwan" is visible (musician name).
- Text containing "Jazz vocalist" is visible (bio).
- Text containing "Bangkok" is visible (location).

Status: PASS


---

ST-11 Musician Detail Page Shows Genre and Share Button
File: st11_musician_detail_genre_test.dart

Input:
1. Create a fake Musician: name="Krit Songkla", genres=["Blues"], location="Chiang Mai", priceRange="1500–3000 THB".
2. Pump MusicianDetailPage with that fake Musician.

Expected Result:
- The text "Blues" is visible (genre tag).
- An Icons.share_outlined icon button is present in the app bar.
- The text "Krit Songkla" is visible as the page heading.

Status: PASS


---

ST-12 Venue My Gigs Page — No Authenticated User
File: st12_venue_my_gigs_no_user_test.dart

Input:
1. Pump VenueMyGigsPage with no Supabase session (unauthenticated state).

Expected Result:
- Text containing "sign in" is visible — the page prompts the user to sign in rather than crashing.
- The app bar title "My Gigs" is visible.

Status: PASS


---

ST-13 Create Gig Genre Chips Are Selectable
File: st13_create_gig_genre_chips_test.dart

Input:
1. Pump CreateGigPage (surface 800×1400).
2. Scroll until the "Jazz" FilterChip is visible.
3. In a second sub-test: tap the "Jazz" chip.
4. In a third sub-test: scroll until the "Rock" FilterChip is visible.

Expected Result:
- A FilterChip labelled "Jazz" is visible after scrolling.
- After tapping "Jazz", the chip's selected property is true.
- Multiple FilterChip widgets are present (genre list has more than one chip).

Status: PASS


---

ST-14 Create Booking Page Renders Gig Info and Send Button
File: st14_create_booking_renders_test.dart

Input:
1. Create a fake Gig: title="Rooftop Jazz Night", location="Bangkok", roleNeeded="Vocalist", date=2026-09-20.
2. Pump CreateBookingPage with that fake Gig.

Expected Result:
- The text "Rooftop Jazz Night" is visible (gig title pre-filled on the booking page).
- The text "Bangkok" is visible (location).
- A "Send Booking Request" ElevatedButton is visible.

Status: PASS


---

ST-15 Venue Confirms a Booking Request
File: st15_venue_confirm_booking_test.dart

Input:
1. Inject a fake BookingRepository pre-seeded with one pending booking (id="b1", title="Sunday Acoustic Set", musician="Test Musician").
2. Pump VenueBookingsPage via ChangeNotifierProvider.
3. Pump for 1 second to let the fake load settle.
4. Tap the "Confirm" button.

Expected Result:
- The "Confirm" ElevatedButton is visible for the pending booking.
- After tapping Confirm, the fake repo records lastRespondedStatus="confirmed" and lastRespondedId="b1".
- The status badge updates to show "confirmed".
- The Confirm and Decline buttons both disappear after the booking is confirmed.

Status: PASS


---

ST-16 My Bookings Page Shows Status Filter Chips
File: st16_my_bookings_filter_chips_test.dart

Input:
1. Pump MyBookingsPage.
2. In a second sub-test: call pumpAndSettle for 2 seconds.
3. In a third sub-test: pump for 1 millisecond to capture the very first frame.

Expected Result:
- The app bar title "My Bookings" is visible.
- After settling, a Scaffold is present (page does not crash in any async state).
- Within the first frame, either a CircularProgressIndicator or a Column/Center layout is present.

Status: PASS


---

ST-17 My Bookings Page Renders and Settles
File: st17_my_bookings_loading_test.dart

Input:
1. Pump MyBookingsPage.
2. Call pumpAndSettle with 2-second timeout to allow async to complete.

Expected Result:
- A Scaffold renders without crashing.
- The app bar title "My Bookings" is always visible.
- After settling, the page body is in a defined state (error, empty state, or list) — never a blank, crashed view.

Status: PASS


---

ST-18 Gig Detail Page Displays Description and Payment
File: st18_gig_detail_description_test.dart

Input:
1. Create a fake Gig: title="Electric Nights", description="An electrifying night of EDM and live performance.", location="Pattaya", genres=["EDM"], payment=5000.
2. Pump GigDetailPage with that fake Gig.
3. Scroll until the description text is visible.
4. In a second sub-test: scroll until payment info is visible.

Expected Result:
- After scrolling, text containing "electrifying" is visible (description).
- Text containing "5" is visible (payment amount "5,000 THB").
- The text "EDM" is visible (genre tag, without scrolling).

Status: PASS


---

ST-19 Messages Page Renders App Bar
File: st19_messages_page_renders_test.dart

Input:
1. Pump MessagesPage (no Supabase session in test environment).

Expected Result:
- The text "Messages" is visible in the app bar.
- The page body shows either a CircularProgressIndicator (loading) or text containing "Failed" / "load" (error) — the page handles the unauthenticated state gracefully.

Status: PASS


---

ST-20 Favorite Heart Button Shows Correct State
File: st20_favorite_heart_button_test.dart

Input:
1. Set FavoritesService.instance.ids.value = {} (empty cache) before each test.
2. Pump FavoriteHeartButton with gigId="g_test".
3. In a second sub-test: pump with gigId="g_fav", then set ids.value = {"g_fav"} and pump again.

Expected Result:
- When the gig is NOT in the favorites set, an Icons.favorite_border (outline heart) is shown.
- After updating the ValueNotifier to include the gig ID, an Icons.favorite (filled heart) is shown.
- The FavoriteHeartButton widget is present in the widget tree.

Status: PASS


---

ST-21 Edit Profile Page Form Renders
File: st21_edit_profile_form_renders_test.dart

Input:
1. Pump EditProfilePage.
2. Call pumpAndSettle with 2-second timeout so _loadProfile() fails gracefully and the form becomes visible.

Expected Result:
- A "Name / Venue" TextFormField is visible after settling.
- A "Bio" TextFormField is visible after settling.
- A "Save Changes" ElevatedButton is visible after scrolling.

Status: PASS


---

ST-22 Favorites Page Shows Empty State
File: st22_favorites_empty_state_test.dart

Input:
1. Set FavoritesService.instance.ids.value = {} (empty cache) before each test.
2. Pump FavoritesPage.
3. Call pumpAndSettle with 2-second timeout to let the FutureBuilder resolve.

Expected Result:
- The text "Favorites" is visible in the app bar.
- After settling, the text "No favorites yet" is shown (empty state message).
- Text containing "Tap the heart" is shown (guidance text for the user).

Status: PASS


---

ST-23 Venue Profile Trust Page
File: st23_venue_profile_trust_test.dart

Input:
1. Inject fake VenueRepository (venue: "The Jazz Cellar", location="Bangkok", 14 gigs hosted, 2 upcoming gigs, 2 past gigs) and fake ReviewRepository (average rating: 4.3, 2 reviews).
2. Pump VenueDetailPage with venueId="v1" and the injected fakes.
3. Pump for 1 second to let FutureBuilders resolve, then scroll to each section.

Expected Result:
- Trust card shows the labels "gigs hosted", "member since", and text containing "review".
- The venue name "The Jazz Cellar" and location "Bangkok" are visible.
- An "Open Gigs" section header is present after scrolling.
- A "Past Events" section header is present after scrolling.
- Each upcoming gig row has an "Apply" chip.
- Each past event row has an Icons.check_circle_outline icon.

Status: PASS


---

ST-24 Musician Reviews a Venue
File: st24_musician_review_venue_test.dart

Input:
1. Pump ReviewPage with bookingId="b1", reviewerId="musician1", reviewedUserId="venue1" and a fake ReviewRepository.
2. Verify initial render (stars and comment field).
3. In a third sub-test: tap the 4th star, enter comment "Great venue, very professional", tap "Submit".
4. In a fourth sub-test: tap the 5th star and tap "Submit" (no comment).

Expected Result:
- Exactly 5 Icons.star rating icons are visible.
- A TextField (comment input) is present.
- A "Submit" ElevatedButton is present.
- After tapping the 4th star and submitting, the fake repo records rating=4, comment="Great venue, very professional", reviewedUserId="venue1".
- After a successful submit, no text containing "failed" or "error" appears.

Status: PASS


---

ST-25 Venue Declines a Booking Request
File: st25_venue_decline_booking_test.dart

Input:
1. Inject a fake BookingRepository pre-seeded with one pending booking (id="b1", gig title="Jazz Night", musician="Test Musician").
2. Pump VenueBookingsPage via ChangeNotifierProvider.
3. Pump for 1 second to settle, then tap "Decline".

Expected Result:
- The pending booking shows status "pending", a "Confirm" button, and a "Decline" button.
- After tapping Decline, the fake repo records lastRespondedId="b1" and lastRespondedStatus="declined".
- The status badge updates to show "declined".
- The "Confirm" and "Decline" buttons both disappear after the decision.
- The "Chat" button remains visible after the decline.

Status: PASS


---

ST-26 Register New Account (Musician Role)
File: st26_register_musician_test.dart

Input:
1. Pump RegisterPage.
2. Sub-test A: verify all fields render.
3. Sub-test B: confirm default role.
4. Sub-test C: tap Register with all fields empty.
5. Sub-test D: enter name, an invalid email "not-an-email", and a password, then tap Register.
6. Sub-test E: enter name, valid email, short password "123", then tap Register.
7. Sub-test F: inject a fake AuthService, enter name="Test Musician", email="test@musician.com", password="testpass123", role left as Musician, then tap Register.

Expected Result:
- A Name TextFormField, Email TextFormField, Password TextFormField, and Register ElevatedButton are all visible.
- The role dropdown defaults to "Musician".
- Empty form submission shows "Please enter your name" and "Please enter your email".
- An invalid email shows "Enter a valid email".
- A password shorter than 6 characters shows "Minimum 6 characters".
- A valid submission calls signUp with name="Test Musician", email="test@musician.com", role="musician".

Status: PASS


---

ST-27 Venue Edits an Existing Gig
File: st27_venue_edit_gig_test.dart

Input:
1. Create a fake Gig: id="g1", title="Original Jazz Night", description="Original description", location="Bangkok", payment=3000.
2. Pump EditGigPage (surface 800×1400) with the existing fake Gig.
3. Sub-test B: scroll to the Save button (Key: save_gig_button).
4. Sub-test C: clear the Title field, scroll to Save, tap Save.
5. Sub-test D: inject a fake GigRepository, change title to "Updated Title ST-27", scroll to Save, tap Save.
6. Sub-test E: inject fake GigRepository, scroll to Save, tap Save without changes.

Expected Result:
- The Title field is pre-populated with "Original Jazz Night".
- A Save Changes button (save_gig_button key) is visible after scrolling.
- Clearing the title and saving shows "Title required" validation error.
- After changing the title and saving, the fake repo records title="Updated Title ST-27" and gigId="g1".
- No text containing "Error" or "failed" appears after a successful save.

Status: PASS
