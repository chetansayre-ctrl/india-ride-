-- India Ride: database upgrade for driver fare offers and completion-based commission
-- Run in Supabase SQL Editor. This file does NOT process payments or charge commission by itself.
-- Keep customer phone numbers private; do not add public SELECT policies for ride_bookings.

alter table if exists public.ride_bookings
  add column if not exists agreed_fare numeric(10,2),
  add column if not exists payment_status text not null default 'unpaid',
  add column if not exists completed_at timestamptz,
  add column if not exists commission_rate numeric(5,4) not null default 0.10,
  add column if not exists commission_amount numeric(10,2),
  add column if not exists selected_offer_id uuid;

create table if not exists public.driver_offers (
  id uuid primary key default gen_random_uuid(),
  booking_id bigint,
  driver_name text not null,
  driver_phone text,
  offered_fare numeric(10,2) not null check (offered_fare > 0),
  vehicle_details text,
  message text,
  status text not null default 'pending'
    check (status in ('pending','accepted','rejected','withdrawn')),
  created_at timestamptz not null default now()
);

-- If ride_bookings uses a UUID id rather than bigint, change driver_offers.booking_id
-- to uuid before applying this schema. Verify the existing table's id type first.

create index if not exists driver_offers_booking_id_idx
  on public.driver_offers (booking_id);

-- Important:
-- 1) Do not enable anonymous public reads of ride_bookings: it may contain customer phone numbers.
-- 2) Driver/customer authentication and row-level security policies must be configured before
--    production use, so users can only access their own bookings/offers.
-- 3) Commission is calculated only after a trusted payment provider confirms payment and the ride
--    is marked completed by a trusted backend/webhook. Never trust a browser-only payment_status.
