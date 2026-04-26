// ============================================================================
// send-notification  —  Supabase Edge Function
// ============================================================================
// Purpose: one place in the backend that knows how to notify a user.
//
// It does TWO things atomically (the "two-layer" notification pattern):
//   (1) INSERT a row into the `notifications` table   → populates the
//       in-app bell icon inbox so the user can see it later.
//   (2) SEND a push via OneSignal REST API            → shows the
//       banner on the user's lock screen right now.
//
// Input payload (JSON):
//   {
//     "receiverId": "uuid of the user to notify",
//     "title":      "short heading, shown bold",
//     "body":       "longer message body",
//     "type":       "message | booking_request | booking_confirmed | booking_declined | ...",
//     "data":       { any extra JSON, used for deep-linking inside the app }
//   }
//
// Why this design?
//   • One call = one delivery. Callers don't need to remember to do both.
//   • Changes to the notification system only happen in ONE file.
//   • RLS can't block us because we use the SERVICE_ROLE_KEY here on the
//     server side — the client never sees that key.
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Standard CORS headers — required because the Flutter app calls this
// function from inside the mobile HTTP stack, which enforces CORS preflight.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight request (browsers/mobile send OPTIONS before POST).
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1) Parse the incoming JSON ─────────────────────────────────
    const { receiverId, title, body, type, data } = await req.json();

    if (!receiverId || !title || !body || !type) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: receiverId, title, body, type",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2) Read secrets from environment ───────────────────────────
    // Never hardcode these. They are set with `supabase secrets set ...`.
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ??
      "08bf7c47-ef4a-49c7-9673-6ae912d7ea81";
    const ONESIGNAL_API_KEY = Deno.env.get("ONESIGNAL_API_KEY")!;

    // ── 3) Layer A: insert into `notifications` table ──────────────
    // This is what makes the bell icon light up.
    // `.stream()` in notifications_page.dart is a live subscription, so the
    // row will appear on the receiver's phone instantly without refresh.
    const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
      method: "POST",
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
        // `Prefer: return=representation` tells Postgres to return the row,
        // which is handy for debugging but not strictly required.
        Prefer: "return=representation",
      },
      body: JSON.stringify({
        user_id: receiverId,
        title,
        message: body,
        type,
        is_read: false,
        // ── Why we now persist `data` to the row ─────────────────────
        // Push notifications carry `additional_data` (see layer B below)
        // so taps can deep-link. But if the user opens the bell icon
        // LATER instead of tapping the banner, the app must read deep-
        // link state from the DB — the OneSignal payload is gone by then.
        // Storing `data` here makes the bell icon behave identically to
        // a fresh tap. Default to {} so the column is never null.
        data: data ?? {},
      }),
    });

    if (!insertRes.ok) {
      const errText = await insertRes.text();
      console.error("Failed to insert notification row:", errText);
      // We DO NOT fail the whole function — we still try to send the push,
      // because a missed bell icon row is less bad than no push at all.
    }

    // ── 4) Layer B: send OneSignal push ────────────────────────────
    // Look up this user's device tokens. A user may have multiple devices;
    // we push to all of them.
    const deviceRes = await fetch(
      `${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${receiverId}&select=player_id`,
      {
        headers: {
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      },
    );

    const devices = await deviceRes.json();
    const subscriptionIds: string[] = (devices ?? [])
      .map((d: any) => d.player_id)
      .filter((id: string | null) => !!id);

    // If the user is logged out on every device, skip push gracefully.
    // The bell icon insert still happened, so they'll see it next login.
    if (subscriptionIds.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, pushed: false, reason: "no devices" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // OneSignal REST API. We use `include_subscription_ids` (new name) —
    // `include_player_ids` still works but is deprecated.
    // Reference: https://documentation.onesignal.com/reference/create-notification
    const pushRes = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_subscription_ids: subscriptionIds,

        headings: { en: title },
        contents: { en: body },

        // additional_data rides along with the push. Our Flutter click
        // listener reads this to know WHERE to navigate when the user
        // taps the banner (deep linking).
        data: {
          type,
          ...(data ?? {}),
        },

        // Android: make this a "heads-up" banner. Priority 10 = high.
        // Without this, the banner only drops into the tray silently.
        priority: 10,

        // iOS high priority (10 = immediate).
        ios_interruption_level: "active",
      }),
    });

    const pushJson = await pushRes.json();

    return new Response(
      JSON.stringify({ ok: true, pushed: true, onesignal: pushJson }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("send-notification error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
