-- Listing publication: currency, delivery availability, the private pickup
-- address and the `publish_listing` RPC the Create Listing flow writes through.
--
-- Design notes:
--   * The exact pickup address deliberately does **not** live on `listings`.
--     `public.listings` has a `using (true)` SELECT policy, so anything put
--     there would be readable by everyone. It gets its own table with an
--     owner-only policy, and no INSERT policy at all: the only writer is the
--     SECURITY DEFINER function below.
--   * `publish_listing` is idempotent on the client-supplied id. The client
--     generates one id per publish attempt and reuses it on every retry, so a
--     retry that follows a lost response returns the row the first attempt
--     already wrote instead of publishing the same item twice.
--   * Photographs are uploaded *before* this function runs, so a row can never
--     reference a photo that failed to store.
--
-- Apply with:
--   supabase db push
-- or by pasting into the Supabase Dashboard SQL editor.

-- ---------------------------------------------------------------------------
-- listings.currency
-- ---------------------------------------------------------------------------

alter table public.listings
  add column if not exists currency text;

comment on column public.listings.currency is
  'Currency shown beside the price: ''SYP'' or ''USD''. Null for donations.';

-- Every priced row published before this migration was displayed in Syrian
-- pounds, so that is what it meant.
update public.listings
   set currency = 'SYP'
 where listing_type = 'sale'
   and currency is null;

update public.listings
   set currency = null
 where listing_type = 'donation'
   and currency is not null;

-- A donation is free and carries no currency; a priced listing carries both a
-- positive price and one of the two codes the app offers.
alter table public.listings
  drop constraint if exists listings_price_matches_type;

alter table public.listings
  add constraint listings_price_matches_type check (
    (listing_type = 'donation' and price is null and currency is null)
    or (listing_type = 'sale' and price is not null and currency in ('SYP', 'USD'))
  );

-- ---------------------------------------------------------------------------
-- listings.delivery_available
-- ---------------------------------------------------------------------------

alter table public.listings
  add column if not exists delivery_available boolean;

update public.listings
   set delivery_available = false
 where delivery_available is null;

-- No default on purpose: the Create Listing form forces an explicit choice,
-- so every new row states its delivery option rather than inheriting one.
alter table public.listings
  alter column delivery_available set not null;

comment on column public.listings.delivery_available is
  'True when the seller offers delivery as well as pickup. Explicitly chosen; never defaulted.';

-- ---------------------------------------------------------------------------
-- listing_pickup_addresses  (private)
-- ---------------------------------------------------------------------------

create table if not exists public.listing_pickup_addresses (
  listing_id uuid primary key references public.listings (id) on delete cascade,
  pickup_address text not null
    check (char_length(trim(pickup_address)) between 3 and 500),
  created_at timestamptz not null default now()
);

comment on table public.listing_pickup_addresses is
  'Exact pickup address for a listing. Owner-only read; written only by publish_listing.';

alter table public.listing_pickup_addresses enable row level security;

-- Only the seller may read their own pickup addresses. There is deliberately
-- no INSERT, UPDATE or DELETE policy: `publish_listing` runs as its owner and
-- is the sole writer, so no client can attach an address to somebody else''s
-- listing or rewrite one after the fact.
drop policy if exists listing_pickup_addresses_select_own
  on public.listing_pickup_addresses;

create policy listing_pickup_addresses_select_own
  on public.listing_pickup_addresses
  for select to authenticated
  using (
    exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = (select auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- Storage: allow the owner to clean up after a failed publish
-- ---------------------------------------------------------------------------

drop policy if exists listing_images_delete_own on storage.objects;

create policy listing_images_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'listing-images'
    and owner_id = (select auth.uid()::text)
  );

-- ---------------------------------------------------------------------------
-- publish_listing
-- ---------------------------------------------------------------------------
-- Writes the listing row and its private pickup address in one transaction and
-- returns the listing id.
--
-- SECURITY DEFINER means RLS on `listings` and `listing_pickup_addresses` does
-- not apply inside the function, so the checks below are what keep it honest:
-- the seller is always `auth.uid()`, never a value the caller supplied, and a
-- pre-existing row can only ever be returned to its own owner.

create or replace function public.publish_listing(
  p_listing_id uuid,
  p_title text,
  p_description text,
  p_category text,
  p_condition text,
  p_listing_type text,
  p_price numeric,
  p_currency text,
  p_images text[],
  p_governorate text,
  p_delivery_available boolean,
  p_pickup_address text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_owner uuid;
  v_title_length integer;
  v_photo_count integer;
begin
  if v_caller is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if p_listing_id is null then
    raise exception 'A listing id is required' using errcode = '22023';
  end if;

  v_title_length := char_length(trim(coalesce(p_title, '')));
  if v_title_length < 3 or v_title_length > 120 then
    raise exception 'Title must be between 3 and 120 characters'
      using errcode = '23514';
  end if;

  v_photo_count := coalesce(array_length(p_images, 1), 0);
  if v_photo_count < 1 or v_photo_count > 5 then
    raise exception 'A listing needs between 1 and 5 photos'
      using errcode = '23514';
  end if;

  if p_category is null or length(trim(p_category)) = 0 then
    raise exception 'A category is required' using errcode = '23514';
  end if;

  if p_condition is null or length(trim(p_condition)) = 0 then
    raise exception 'A condition is required' using errcode = '23514';
  end if;

  if p_governorate is null or length(trim(p_governorate)) = 0 then
    raise exception 'A governorate is required' using errcode = '23514';
  end if;

  if p_delivery_available is null then
    raise exception 'Pickup or delivery must be chosen explicitly'
      using errcode = '23514';
  end if;

  if char_length(trim(coalesce(p_pickup_address, ''))) < 3 then
    raise exception 'A pickup address is required' using errcode = '23514';
  end if;

  if p_listing_type = 'sale' then
    if p_price is null or p_price <= 0
       or p_currency is null or p_currency not in ('SYP', 'USD') then
      raise exception 'A priced listing needs a positive price and a currency'
        using errcode = '23514';
    end if;
  elsif p_listing_type = 'donation' then
    if p_price is not null or p_currency is not null then
      raise exception 'A donation cannot carry a price or a currency'
        using errcode = '23514';
    end if;
  else
    raise exception 'Unknown listing type' using errcode = '23514';
  end if;

  -- Idempotent publish. A retry after a lost response finds the row the first
  -- attempt wrote and returns it instead of inserting a second listing; the
  -- pickup address is filled in only if that attempt never got that far.
  select l.seller_id
    into v_owner
    from public.listings l
   where l.id = p_listing_id
   for update;

  if found then
    if v_owner <> v_caller then
      raise exception 'That listing is not yours' using errcode = '42501';
    end if;

    insert into public.listing_pickup_addresses (listing_id, pickup_address)
    values (p_listing_id, trim(p_pickup_address))
    on conflict (listing_id) do nothing;

    return p_listing_id;
  end if;

  insert into public.listings (
    id,
    seller_id,
    title,
    description,
    category,
    condition,
    listing_type,
    price,
    currency,
    images,
    governorate,
    area,
    status,
    delivery_available
  ) values (
    p_listing_id,
    v_caller,
    trim(p_title),
    trim(coalesce(p_description, '')),
    trim(p_category),
    trim(p_condition),
    p_listing_type,
    p_price,
    p_currency,
    p_images,
    trim(p_governorate),
    -- The Create Listing form has no Area step, so a new listing publishes the
    -- governorate only and the public `area` column stays empty.
    '',
    'available',
    p_delivery_available
  );

  insert into public.listing_pickup_addresses (listing_id, pickup_address)
  values (p_listing_id, trim(p_pickup_address));

  return p_listing_id;
end;
$$;

revoke all on function public.publish_listing(uuid, text, text, text, text, text, numeric, text, text[], text, boolean, text) from public;
grant execute on function public.publish_listing(uuid, text, text, text, text, text, numeric, text, text[], text, boolean, text) to authenticated;
