JamUP System Test Cases

ST-01 Login
Steps:
1. Open JamUP app
2. Enter email and password
3. Tap Login

Expected Result:
User is redirected to Home Page

Status: PASS


ST-02 Search Gigs
Steps:
1. Enter "Jazz" in search bar

Expected Result:
Jazz gigs appear

Status: PASS


ST-03 Filter Musicians
Steps:
1. Open musicians page
2. Select Genre filter

Expected Result:
Only musicians with selected genre appear

Status: PASS


ST-04 Apply for Gig
Steps:
1. Open gig details
2. Tap Apply

Expected Result:
Booking request created

Status: PASS


ST-05 Accept Booking
Steps:
1. Venue opens booking request
2. Tap Accept

Expected Result:
Musician receives notification

Status: PASS


ST-06 Upload Media
Steps:
1. Musician uploads image/video

Expected Result:
Media appears on profile

Status: PASS


ST-07 Review Musician
Steps:
1. Venue submits rating after gig

Expected Result:
Review stored and average rating updated

Status: PASS


ST-08 Login with wrong password (sad path)
Steps:
1. Open JamUP app
2. Enter a valid email
3. Enter an INCORRECT password
4. Tap Login

Expected Result:
Error message "Invalid login credentials" appears.
User remains on the Login Page (NOT redirected).

Status: PASS


ST-09 Logout returns to login screen
Steps:
1. Sign in with a valid account
2. Open Profile page
3. Tap "Logout"

Expected Result:
User is redirected to Login Page.
device_tokens row for this device is removed (verified via DB).
Re-opening the app shows the Login Page (no auto-login).

Status: PASS


ST-10 Venue creates a new gig (happy path)
Steps:
1. Sign in as a Venue user
2. Tap "Create Gig" / FAB
3. Fill: title, location (pick from Google Places), date/time, genres, role, payment, slots
4. Optionally pick a cover image
5. Tap "Create Gig"

Expected Result:
A success snackbar appears.
The new gig is visible on the Home page "Upcoming Gigs" row.
Cover image is uploaded under gig_images/<user_id>/<timestamp>.<ext>.
The DB row contains lat/lng captured from Google Places.

Status: PASS


ST-11 Filter gigs by Type (role_needed)
Steps:
1. From Home page, tap the "Type" filter chip
2. Select "Singer"
3. Close the bottom sheet

Expected Result:
Only gigs whose role_needed = "Singer" remain visible across
"Recommended", "Upcoming", and "Nearby" sections.
The Type chip turns gold (active state).

Status: PASS


ST-12 Filter gigs by Price bucket
Steps:
1. From Home page, tap the "Price" filter chip
2. Select "<฿3000"

Expected Result:
Only gigs with payment < 3000 are visible.
Gigs with NULL payment are hidden (we treat null as "skip").

Status: PASS


ST-13 Combined filter — Type + Location + Price
Steps:
1. From the Gigs page, select Type "Singer"
2. Select Price "฿3000-฿10000" (in the same flow)
3. Use the Location nearby toggle to enable proximity filtering

Expected Result:
Only gigs matching ALL active filters are shown (intersection,
not union). The active-filter chips bar updates accordingly.
Clearing one filter re-includes the gigs that were hidden by it.

Status: PASS


ST-14 Favorite a gig from the Home feed
Steps:
1. From Home page, tap the heart icon on a gig card

Expected Result:
Heart fills red instantly (optimistic UI).
A row appears in the favorites table with (user_id, gig_id).
Opening the same gig elsewhere (detail page, gigs grid) shows
the heart already filled — proving the cache is shared.

Status: PASS


ST-15 Unfavorite from Favorites page
Steps:
1. From Profile, tap "Favorites"
2. Tap the heart on any listed gig

Expected Result:
That card disappears from the Favorites grid immediately.
The DB row in `favorites` is deleted.
The same gig's heart is now an outline (unfilled) elsewhere.

Status: PASS


ST-16 Favorites empty state
Steps:
1. Sign in as a user with NO favorites
2. Open Profile → Favorites

Expected Result:
The page shows an empty-state with the heart icon and the message:
"Tap the heart on any gig to save it here for quick access."
The "pull-to-refresh" gesture still works on the empty page.

Status: PASS


ST-17 Schedule page navigation (back arrow)
Steps:
1. Open Profile page
2. Tap "My Schedule"
3. Tap the back arrow inside the gradient header

Expected Result:
User returns to the Profile page.
The schedule page does NOT use a default AppBar — confirms the
manually-added IconButton + Navigator.maybePop() works.

Status: PASS


ST-18 Schedule event tap opens booking detail
Steps:
1. Open My Schedule
2. Tap a date that has events
3. Tap any event row

Expected Result:
The Booking Detail page opens for that booking.
Confirm/Decline/Cancel actions are available depending on role.
The chevron at the right edge of the row hints the row is tappable.

Status: PASS


ST-19 My Bookings status filter chips
Steps:
1. Sign in as a musician with bookings in mixed states
2. Open Profile → My Bookings
3. Tap "Pending" chip, then "Confirmed", then "All"

Expected Result:
The list narrows to bookings with the matching status.
"All" shows everything regardless of status.
Empty result for a chip shows a contextual empty state
("No confirmed bookings"), NOT a generic blank screen.

Status: PASS


ST-20 Notification deep-link payload persists
Steps:
1. Send a chat message that triggers send-notification
2. Stop the receiver's app before they tap the banner
3. Re-open the app
4. Open the bell icon notification list

Expected Result:
The notification row exists in `notifications` table with
`data` JSONB populated (chatId, bookingId).
Tapping the row navigates to the correct deep-linked screen.
This proves the Edge Function persists the payload (not just
sending it via OneSignal additional_data).

Status: PASS


ST-21 Location pill shows specific city, not "Thailand"
Steps:
1. Grant location permission to the app
2. Open Home page

Expected Result:
The location pill in the top-left shows a specific city name
(e.g. "Chiang Mai, TH" or "Bangkok, TH"), NOT just "Thailand".
This proves the multi-level fallback in LocationService.getCityName
(locality → subLocality → subAdministrativeArea → administrativeArea)
is working on the device.

Status: PASS


ST-22 Nearby gigs feed populated from RPC
Steps:
1. Grant location permission
2. Open Home page
3. Scroll to "Nearby Gigs" section

Expected Result:
At least one nearby gig is shown (assuming there are upcoming gigs
within radius with non-null lat/lng).
Each card displays a "X km away" badge derived from distance_km
returned by the get_nearby_gigs RPC. This proves both the
backfilled coordinates AND the distance_km/distance fallback in
Gig.fromJson are in effect.

Status: PASS