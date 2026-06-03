// EVC — finalize-payment edge function.
//
// Example of logic that can't live in Postgres: capturing a card charge with an
// external UAE gateway (Telr / Stripe / Network International). Called after a
// trip completes when payment_type = 'card' and the payment row is 'authorized'.
//
// Flow:
//   1. Verify the caller (rider on the trip, or an admin) via their JWT.
//   2. Load the trip's authorized payment.
//   3. Charge the gateway (stubbed here).
//   4. Mark the payment 'captured' (or 'failed') using the service role.
//
// Deploy:  supabase functions deploy finalize-payment
// Secrets: supabase secrets set PAYMENT_GATEWAY_KEY=...

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { trip_id } = await req.json();
    if (!trip_id) {
      return json({ error: "trip_id required" }, 400);
    }

    const authHeader = req.headers.get("Authorization") ?? "";

    // Caller-scoped client (RLS applies) — confirms they can see this trip.
    const asUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: trip, error: tripErr } = await asUser
      .from("trips")
      .select("id, final_fare, vat, tip, payment_type, status")
      .eq("id", trip_id)
      .single();

    if (tripErr || !trip) return json({ error: "trip not found" }, 404);
    if (trip.status !== "completed") return json({ error: "trip not completed" }, 409);
    if (trip.payment_type !== "card") return json({ ok: true, skipped: "non-card" });

    // Charge the gateway (STUB — wire Telr/Stripe here).
    const amount = Number(trip.final_fare) + Number(trip.vat) + Number(trip.tip);
    const gatewayRef = await chargeGateway(amount);

    // Service-role client to write the captured payment (bypasses RLS).
    const asService = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error: payErr } = await asService
      .from("payments")
      .update({ status: "captured", gateway_ref: gatewayRef })
      .eq("trip_id", trip_id)
      .eq("status", "authorized");

    if (payErr) return json({ error: payErr.message }, 500);
    return json({ ok: true, amount, gateway_ref: gatewayRef });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// Stub: replace with a real gateway SDK call.
async function chargeGateway(amountAed: number): Promise<string> {
  const _key = Deno.env.get("PAYMENT_GATEWAY_KEY");
  await new Promise((r) => setTimeout(r, 50));
  return `mock_${Math.round(amountAed * 100)}`;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}