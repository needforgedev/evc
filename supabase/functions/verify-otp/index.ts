// EVC — verify-otp
//
// Validates a code for `phone` against otp_codes (hash + expiry + attempt cap).
// Returns { verified: true|false }. The Flutter app then signs in (deterministic
// phone→account), so a verified user lands back in their existing account.
//
// Deploy: supabase functions deploy verify-otp --no-verify-jwt

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
    const { phone, code } = await req.json();
    if (!phone || !code) return json({ error: "phone + code required" }, 400);

    const service = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: row } = await service
      .from("otp_codes").select("*").eq("phone", phone).maybeSingle();

    if (!row) return json({ verified: false, reason: "no_code" });
    if (row.consumed) return json({ verified: false, reason: "used" });
    if (new Date(row.expires_at) < new Date()) {
      return json({ verified: false, reason: "expired" });
    }
    if (row.attempts >= 5) return json({ verified: false, reason: "too_many_attempts" });

    const hash = await sha256Hex(String(code));
    if (hash !== row.code_hash) {
      await service.from("otp_codes").update({ attempts: row.attempts + 1 }).eq("phone", phone);
      return json({ verified: false, reason: "incorrect" });
    }

    await service.from("otp_codes").update({ consumed: true }).eq("phone", phone);
    return json({ verified: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
