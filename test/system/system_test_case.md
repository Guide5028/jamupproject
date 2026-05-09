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


ST-23 Venue Profile Trust Page
Steps:
1. Sign in as a musician
2. From the Home page or Gigs page, tap any gig card
3. On the Gig Detail page, scroll down to the "Organizer" row
4. Tap the Organizer row

Expected Result:
Venue Detail page opens for that venue.
The trust stats card is visible showing three stats: average rating
(star icon), gigs hosted count (event icon), and member since year
(calendar icon).
If the venue has received reviews, the star rating shows a number
between 1.0 and 5.0, not "—".
The "Open Gigs" section lists upcoming gigs for that venue with
an "Apply" chip on each row.
The "Past Events" section lists historical gigs with a green
checkmark icon, proving the venue has a track record.
The "Reviews from Musicians" section shows any submitted reviews.

Status: PASS


ST-24 Musician Reviews a Venue
Steps:
1. Sign in as a musician who has a confirmed booking with a venue
2. Open Profile → My Bookings
3. Tap the confirmed booking
4. Tap "Leave Review" on the Booking Detail page
5. Select a star rating (e.g. 4 stars)
6. Enter a comment: "Great venue, very professional"
7. Submit the review
8. Navigate to the venue's profile via any gig → Organizer tap

Expected Result:
The review submission succeeds with no error snackbar.
On the Venue Detail page, the new review appears in the
"Reviews from Musicians" section with the correct star count
and comment text.
The average rating in the trust stats card updates to reflect
the new review.
This is the reverse of ST-07 (which tests venue reviewing a
musician) and proves the review system works bidirectionally.

Status: PASS


ST-25 Venue Declines a Booking Request
Steps:
1. Sign in as a venue that has at least one pending booking request
2. Open Profile → Booking Requests
3. Find a booking with status "pending"
4. Tap "Decline" on that booking card

Expected Result:
The booking card status badge changes from "pending" (amber)
to "declined" (red) immediately (optimistic UI update).
The Confirm and Decline buttons disappear — only the Chat button
remains visible for that card.
In the Supabase bookings table, that row's status is "declined".
The musician who applied sees status "declined" on their
My Bookings page.
This is the sad path counterpart to ST-05 (Accept Booking) and
proves the full confirm/decline flow works end-to-end.

Status: PASS


ST-26 Register New Account (Musician Role)
Steps:
1. Open the JamUP app while not signed in
2. Tap "Register" on the login screen
3. Enter: full name "Test Musician", a unique test email address,
   and a password of at least 6 characters
4. Select role "Musician"
5. Tap the register / submit button

Expected Result:
No error is shown.
The app navigates to the Home page as a logged-in musician.
The Profile page shows the name "Test Musician" and the role
badge reads "MUSICIAN".
A row exists in the Supabase users table with role = 'musician'
and the entered name.
This proves the full registration → auto-login flow works for
the musician role.

Status: PASS


ST-27 Venue Edits an Existing Gig
Steps:
1. Sign in as a venue that has at least one existing gig
2. Open Profile → My Gigs
3. Tap any gig card to open the Edit Gig page
4. Change the title to a new unique value (e.g. "Updated Title Test")
5. Change the payment amount to a new value (e.g. 4500)
6. Tap Save

Expected Result:
A success snackbar appears confirming the update.
The My Gigs list refreshes and shows the updated title.
Navigating to that gig from the public Gigs feed shows the
new title and updated payment amount.
In the Supabase gigs table, the row reflects the new values.
This is the edit path that ST-10 (create gig) does not cover.

Status: PASS