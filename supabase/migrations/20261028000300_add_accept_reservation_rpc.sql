-- -- RPC to accept reservation atomically
-- create or replace function public.accept_reservation(p_reservation_id uuid)
-- returns void
-- language plpgsql
-- security definer
-- as $$
-- declare
--   v_listing_id uuid;
--   v_listing_status text;
-- begin
--   -- Get listing and lock for update
--   select listing_id into v_listing_id
--     from public.reservations
--     where id = p_reservation_id;

--   select status into v_listing_status
--     from public.listings
--     where id = v_listing_id
--     for update;

--   if v_listing_status <> 'available' then
--     raise exception 'Listing is not available' using errcode = '23514';
--   end if;

--   -- Update reservation
--   update public.reservations
--     set status = 'accepted'
--     where id = p_reservation_id;

--   -- Update listing
--   update public.listings
--     set status = 'reserved'
--     where id = v_listing_id;

--   -- Reject other pending requests
--   update public.reservations
--     set status = 'rejected'
--     where listing_id = v_listing_id and id <> p_reservation_id and status = 'pending';
-- end;
-- $$;

-- Atomically accept the first reservation for an available listing.
create or replace function public.accept_reservation(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_listing_id uuid;
  v_listing_status text;
  v_reservation_status text;
  v_seller_id uuid;
begin
  -- Find the listing associated with the reservation.
  select r.listing_id
    into v_listing_id
    from public.reservations r
   where r.id = p_reservation_id;

  if not found then
    raise exception 'Reservation not found' using errcode = 'P0002';
  end if;

  -- Lock the listing first to serialize competing acceptances.
  select l.status, l.seller_id
    into v_listing_status, v_seller_id
    from public.listings l
   where l.id = v_listing_id
   for update;

  if not found or v_listing_status <> 'available' then
    raise exception 'Listing is not available' using errcode = '23514';
  end if;

  -- Only the listing owner may accept a reservation.
  if v_seller_id <> auth.uid() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;

  -- Lock and validate the requested reservation.
  select r.status
    into v_reservation_status
    from public.reservations r
   where r.id = p_reservation_id
     and r.listing_id = v_listing_id
   for update;

  if not found or v_reservation_status <> 'pending' then
    raise exception 'Reservation is not pending' using errcode = '23514';
  end if;

  -- Accept this reservation.
  update public.reservations
     set status = 'accepted',
         updated_at = now()
   where id = p_reservation_id;

  -- Reserve the listing.
  update public.listings
     set status = 'reserved'
   where id = v_listing_id;

  -- Reject all other pending requests.
  update public.reservations
     set status = 'rejected',
         updated_at = now()
   where listing_id = v_listing_id
     and id <> p_reservation_id
     and status = 'pending';
end;
$$;

revoke all on function public.accept_reservation(uuid) from public;
grant execute on function public.accept_reservation(uuid) to authenticated;
