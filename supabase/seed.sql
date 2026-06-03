-- EVC — reference / config data. Loaded by `supabase db reset`.
-- (Demo users + trips are created via auth signup; see supabase/README.md.)

-- Pricing (Dubai). Fares = (base + per_km·km + per_min·min) · tier.multiplier.
insert into public.pricing (region, currency, base_fare, per_km, per_min, min_fare, vat_rate)
values ('dubai', 'AED', 8.00, 1.90, 0.45, 12.00, 0.05);

-- Ride tiers.
insert into public.ride_tiers (id, name, blurb, seats, multiplier, icon, sort_order) values
  ('go',      'EVC Go',            'Compact EV · 3 seats',          3, 1.00, 'directions_car_filled',   1),
  ('comfort', 'EVC Comfort',       'Newer EVs, extra legroom · 4',  4, 1.35, 'airline_seat_recline_extra', 2),
  ('xl',      'EVC XL',            'SUV / van · 6 seats',           6, 1.90, 'airport_shuttle',          3),
  ('premium', 'EVC Green Premium', 'Tesla / luxury EV · 3 seats',   3, 2.50, 'electric_car',             4);

-- Zones (for surge + demand analytics).
insert into public.zones (name, region) values
  ('Downtown / DIFC', 'dubai'),
  ('Dubai Marina / JBR', 'dubai'),
  ('DXB Airport', 'dubai'),
  ('Deira / Bur Dubai', 'dubai');

insert into public.surge_rules (zone_id, multiplier, starts_at, ends_at)
select id, 1.4, '17:00', '21:00' from public.zones where name = 'Downtown / DIFC';
insert into public.surge_rules (zone_id, multiplier, starts_at, ends_at)
select id, 1.6, '00:00', '23:59' from public.zones where name = 'DXB Airport';

-- Promo codes.
insert into public.promo_codes (code, description, discount_type, value, max_discount, active) values
  ('GREEN20',  '20% off, max AED 15',     'percent', 20, 15, true),
  ('WELCOME',  'AED 25 off first ride',   'flat',    25, null, true),
  ('EID10',    '10% off all rides',       'percent', 10, null, false);

-- DEWA EV Green Charger stations.
insert into public.charging_stations (name, network, lat, lng, total_stalls, available_stalls, power_kw) values
  ('DEWA — Business Bay',            'DEWA EV Green Charger', 25.1860, 55.2620, 4, 3, 120),
  ('DEWA — Downtown / Dubai Mall',   'DEWA EV Green Charger', 25.1972, 55.2796, 6, 0, 150),
  ('DEWA — Sheikh Zayed Rd',         'DEWA EV Green Charger', 25.2180, 55.2810, 4, 2,  60),
  ('DEWA — Marina',                  'DEWA EV Green Charger', 25.0805, 55.1403, 8, 5, 120);