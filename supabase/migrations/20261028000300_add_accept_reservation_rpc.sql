-- RPC to accept reservation atomically
create or replace function public.accept_reservation(p_reservation_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_listing_id uuid;
  v_listing_status text;
begin
  -- Get listing and lock for update
  select listing_id into v_listing_id
    from public.reservations
    where id = p_reservation_id;

  select status into v_listing_status
    from public.listings
    where id = v_listing_id
    for update;

  if v_listing_status <> 'active' then
    raise exception 'Listing is not available' using errcode = '23514';
  end if;

  -- Update reservation
  update public.reservations
    set status = 'accepted'
    where id = p_reservation_id;

  -- Update listing
  update public.listings
    set status = 'reserved'
    where id = v_listing_id;

  -- Reject other pending requests
  update public.reservations
    set status = 'rejected'
    where listing_id = v_listing_id and id <> p_reservation_id and status = 'pending';
end;
$$;
