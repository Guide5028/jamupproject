import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  const { chatId, senderId, senderName, message } = await req.json();

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const ONESIGNAL_APP_ID = "08bf7c47-ef4a-49c7-9673-6ae912d7ea81";
  const ONESIGNAL_API_KEY = Deno.env.get("ONESIGNAL_API_KEY");

  // 1️⃣ Get booking id
  const chatRes = await fetch(
    `${SUPABASE_URL}/rest/v1/chats?id=eq.${chatId}&select=booking_id`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  const chatData = await chatRes.json();
  const bookingId = chatData[0]?.booking_id;

  // 2️⃣ Get musician + venue
  const bookingRes = await fetch(
    `${SUPABASE_URL}/rest/v1/bookings?id=eq.${bookingId}&select=musician_id,venue_id`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  const bookingData = await bookingRes.json();

  const musicianId = bookingData[0]?.musician_id;
  const venueId = bookingData[0]?.venue_id;

  // 3️⃣ Determine receiver
  const receiverId = senderId === musicianId ? venueId : musicianId;

  // 4️⃣ Get device tokens
  const deviceRes = await fetch(
    `${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${receiverId}&select=player_id`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  const deviceData = await deviceRes.json();
  const playerIds = deviceData.map((d: any) => d.player_id);

  // 5️⃣ Send notification via OneSignal
  const response = await fetch("https://onesignal.com/api/v1/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${ONESIGNAL_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: playerIds,

      headings: { en: senderName },
      contents: { en: message },

      android_channel_id: "messages",
    }),
  });

  const data = await response.json();

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
});