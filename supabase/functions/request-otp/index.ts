// EVC — request-otp
//
// Generates a 6-digit code for `phone`, stores it HASHED in otp_codes, and
// delivers it via the **Vonage WhatsApp Sandbox**.
//
// SANDBOX NOTE: the sandbox can only message numbers that have joined it, so —
// regardless of the phone the user typed — we deliver the code to the single
// whitelisted test number (OTP_SANDBOX_TO). The typed phone is still the
// account identity; only the *delivery* target is fixed in dev.
//
// Deploy:  supabase functions deploy request-otp --no-verify-jwt
// Secrets: supabase secrets set VONAGE_API_KEY=... VONAGE_API_SECRET=... \
//            VONAGE_WA_FROM=14157386102 OTP_SANDBOX_TO=918097086954

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

async function sha256Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { phone } = await req.json();
    if (!phone || typeof phone !== "string") return json({ error: "phone required" }, 400);

    // 6-digit code (crypto-random), stored hashed with a 5-minute expiry.
    const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000)
      .padStart(6, "0");
    const codeHash = await sha256Hex(code);

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error: dbErr } = await service.from("otp_codes").upsert({
      phone,
      code_hash: codeHash,
      channel: "whatsapp",
      expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      attempts: 0,
      consumed: false,
      created_at: new Date().toISOString(),
    }, { onConflict: "phone" });
    if (dbErr) return json({ error: dbErr.message }, 500);

    // Deliver via Vonage WhatsApp Sandbox (fixed recipient).
    const key = Deno.env.get("VONAGE_API_KEY")!;
    const secret = Deno.env.get("VONAGE_API_SECRET")!;
    const from = Deno.env.get("VONAGE_WA_FROM") ?? "14157386102";
    const to = Deno.env.get("OTP_SANDBOX_TO")!; // whitelisted sandbox number

    const res = await fetch("https://messages-sandbox.nexmo.com/v1/messages", {
      method: "POST",
      headers: {
        "Authorization": "Basic " + btoa(`${key}:${secret}`),
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        from,
        to,
        channel: "whatsapp",
        message_type: "text",
        text: `Your EVC verification code is ${code} (for ${phone})`,
      }),
    });

    if (!res.ok) {
      const detail = await res.text();
      return json({ error: "delivery failed", detail }, 502);
    }
    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
