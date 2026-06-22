// EVC — maps-proxy
//
// Proxies Google Places (New) Autocomplete/Details + Directions so the API key
// stays server-side (PRD #5 "API Puzzle Engine" at app scale). The Flutter apps
// call this with their Supabase JWT; the key is read from the GMAPS_API_KEY
// secret and never shipped in the client for these HTTP calls.
//
// Always responds 200 with `{ status, body }` where `status` is Google's HTTP
// status and `body` is Google's JSON — so the app reads errors uniformly.
//
// Deploy:  supabase functions deploy maps-proxy --project-ref <ref>
// Secret:  supabase secrets set GMAPS_API_KEY=... --project-ref <ref>

import { corsHeaders } from "../_shared/cors.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const KEY = Deno.env.get("GMAPS_API_KEY") ?? "";
// Dubai bias for autocomplete results.
const BIAS = { lat: 25.2048, lng: 55.2708 };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (!KEY) {
    return json({ status: 500, body: { error: { message: "GMAPS_API_KEY not set" } } });
  }

  try {
    const r = await req.json();
    const op = r.op as string;

    if (op === "autocomplete") {
      const res = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": KEY },
        body: JSON.stringify({
          input: String(r.input ?? ""),
          includedRegionCodes: ["ae"],
          locationBias: {
            circle: {
              center: { latitude: BIAS.lat, longitude: BIAS.lng },
              radius: 50000.0, // Google max
            },
          },
          ...(r.sessionToken ? { sessionToken: r.sessionToken } : {}),
        }),
      });
      return json({ status: res.status, body: await res.json() });
    }

    if (op === "details") {
      const placeId = encodeURIComponent(String(r.placeId ?? ""));
      const st = r.sessionToken
        ? `?sessionToken=${encodeURIComponent(r.sessionToken)}`
        : "";
      const res = await fetch(
        `https://places.googleapis.com/v1/places/${placeId}${st}`,
        {
          headers: {
            "X-Goog-Api-Key": KEY,
            "X-Goog-FieldMask": "id,displayName,formattedAddress,location",
          },
        },
      );
      return json({ status: res.status, body: await res.json() });
    }

    if (op === "directions") {
      const o = r.origin, d = r.destination;
      if (!o || !d) return json({ status: 400, body: { error: { message: "origin/destination required" } } });
      // Routes API (New) — the legacy Directions API isn't enableable on most
      // newly-created keys (same reason we use Places New).
      const res = await fetch(
        "https://routes.googleapis.com/directions/v2:computeRoutes",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": KEY,
            "X-Goog-FieldMask":
              "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
          },
          body: JSON.stringify({
            origin: { location: { latLng: { latitude: o.lat, longitude: o.lng } } },
            destination: { location: { latLng: { latitude: d.lat, longitude: d.lng } } },
            travelMode: "DRIVE",
          }),
        },
      );
      return json({ status: res.status, body: await res.json() });
    }

    return json({ status: 400, body: { error: { message: "unknown op" } } });
  } catch (e) {
    return json({ status: 500, body: { error: { message: String(e) } } });
  }
});
