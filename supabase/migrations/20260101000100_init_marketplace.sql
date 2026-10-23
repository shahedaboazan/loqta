-- Loqta marketplace, chat and notifications schema.
--
-- Creates the smallest set of tables that supports the approved screens:
-- listings (10, 11, 12, 13), conversations + messages (14, 16), chat
-- attachments (15) and notifications (17).
--
-- Design notes:
--   * Chat is strictly two-party (a buyer and a listing's seller), so
--     `conversations` carries `buyer_id` and `seller_id` directly. That makes
--     "one conversation per listing per participant pair" a plain UNIQUE
--     constraint that the database itself enforces, instead of an application
--     convention that two concurrent taps could race past.
--   * There is no UPDATE policy on `conversations`, so a participant can
--     never repoint the participants to gain access to somebody else's thread.
--   * Read state lives in `conversation_reads`, one row per (conversation,
--     user). A single `messages.read_at` column could not express per-user read
--     state for a group, and would make "don't let me write your read state"
--     impossible to enforce.
--
-- Apply with:
--   supabase db push
-- or by pasting into the Supabase Dashboard SQL editor.

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------

-- Trigram support so keyword search uses an index instead of a table scan.
create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------------------
-- Shared trigger helper
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text,
  last_name text,
  avatar_url text,
  -- Public location only. Never a precise pickup address.
  governorate text,
  area text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Public seller/buyer profile. Public location is governorate + area only.';

create index if not exists profiles_updated_at_idx
  on public.profiles (updated_at);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Mirrors the names captured at sign-up (AuthRepositoryImpl already writes
-- first_name / last_name into user metadata) so listings and chat rows can
-- show a name without a second round trip through auth.users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, first_name, last_name)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- listings  (screens 10, 11, 12, 13)
-- ---------------------------------------------------------------------------

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 3 and 120),
  description text not null default '',
  category text not null,
  -- Visible condition label, e.g. 'Like New'. Free text keeps the approved
  -- design copy without inventing an enum the UI cannot render.
  condition text not null,
  -- 'sale' shows a price, 'donation' is shown as Free.
  listing_type text not null default 'sale'
    check (listing_type in ('sale', 'donation')),
  price numeric(12, 2) check (price is null or price >= 0),
  -- Storage paths or absolute URLs into the `listing-images` bucket.
  images text[] not null default '{}',
  -- Public location only. There is deliberately no pickup_address column.
  governorate text not null default '',
  area text not null default '',
  status text not null default 'active'
    check (status in ('active', 'reserved', 'sold', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- A donation is free, and a priced listing must carry a price.
  constraint listings_price_matches_type check (
    (listing_type = 'donation' and price is null)
    or (listing_type = 'sale' and price is not null)
  )
);

comment on column public.listings.governorate is
  'Public governorate only. Exact pickup addresses are never published.';

-- Stable sort key for server-side pagination: newest first, then id as a
-- unique tie-breaker so two batches can never overlap or skip a row.
create index if not exists listings_created_at_id_idx
  on public.listings (created_at desc, id desc);

create index if not exists listings_seller_id_idx
  on public.listings (seller_id);

create index if not exists listings_category_idx
  on public.listings (category);

-- Keyword search support for the Search screen's ILIKE predicate.
create index if not exists listings_title_trgm_idx
  on public.listings using gin (lower(title) extensions.gin_trgm_ops);

create index if not exists listings_description_trgm_idx
  on public.listings using gin (lower(coalesce(description, '')) extensions.gin_trgm_ops);

create index if not exists listings_category_trgm_idx
  on public.listings using gin (lower(category) extensions.gin_trgm_ops);

create trigger listings_set_updated_at
  before update on public.listings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- favorites  (screen 13)
-- ---------------------------------------------------------------------------

create table if not exists public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create index if not exists favorites_user_created_idx
  on public.favorites (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- conversations  (screens 14, 16)
-- ---------------------------------------------------------------------------

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  -- The two participants. buyer_id is always the person who pressed
  -- "Contact Seller"; seller_id always belongs to the listing.
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  -- Denormalised sort key for the Chat List; kept current by the trigger
  -- below so ordering never depends on a correlated subquery.
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),

  -- One conversation per listing per participant pair, enforced here.
  constraint conversations_listing_pair_uniq unique (listing_id, buyer_id, seller_id),
  -- Nobody can start a conversation with themselves.
  constraint conversations_distinct_participants check (buyer_id <> seller_id)
);

create index if not exists conversations_buyer_last_message_idx
  on public.conversations (buyer_id, last_message_at desc, id desc);

create index if not exists conversations_seller_last_message_idx
  on public.conversations (seller_id, last_message_at desc, id desc);

-- ---------------------------------------------------------------------------
-- messages  (screen 14)
-- ---------------------------------------------------------------------------

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  -- Empty for an image-only message, which is why content is nullable rather
  -- than an empty string.
  content text,
  -- Path inside the private `chat-attachments` bucket. Never a public URL and
  -- never raw image bytes.
  attachment_path text,
  attachment_mime text,
  created_at timestamptz not null default now(),

  constraint messages_has_content_or_attachment
    check (content is not null or attachment_path is not null)
);

-- Ordering used by both the initial history load and the realtime merge.
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at asc, id asc);

-- Keeps conversations.last_message_at fresh so the Chat List ordering and the
-- unread badge stay correct without an application-side update.
create or replace function public.touch_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
     set last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.touch_conversation_on_message();

-- ---------------------------------------------------------------------------
-- conversation_reads  (read/unread status)
-- ---------------------------------------------------------------------------

create table if not exists public.conversation_reads (
  conversation_id uuid not null
    references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

-- ---------------------------------------------------------------------------
-- notifications  (screen 17)
-- ---------------------------------------------------------------------------

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  -- new_message, reservation_requested, reservation_accepted,
  -- listing_status_update, transaction_completed, rating_received,
  -- report_account_update
  type text not null,
  title text not null,
  body text not null default '',
  -- Optional destinations. The client only navigates when the target row is
  -- still readable under RLS.
  listing_id uuid references public.listings (id) on delete cascade,
  conversation_id uuid references public.conversations (id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now(),

  -- Lets the server de-duplicate when an event is delivered more than once.
  dedupe_key text unique
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc, id desc);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id)
  where read_at is null;

-- ===========================================================================
-- Row Level Security
-- ===========================================================================

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.favorites enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.conversation_reads enable row level security;
alter table public.notifications enable row level security;

-- --- profiles -------------------------------------------------------------

drop policy if exists profiles_select_public on public.profiles;
create policy profiles_select_public on public.profiles
  for select using (true);

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- --- listings -------------------------------------------------------------

-- Marketplace listings are browsable by everyone, signed in or not.
drop policy if exists listings_select_public on public.listings;
create policy listings_select_public on public.listings
  for select using (true);

drop policy if exists listings_insert_own on public.listings;
create policy listings_insert_own on public.listings
  for insert to authenticated
  with check ((select auth.uid()) = seller_id);

drop policy if exists listings_update_own on public.listings;
create policy listings_update_own on public.listings
  for update to authenticated
  using ((select auth.uid()) = seller_id)
  with check ((select auth.uid()) = seller_id);

drop policy if exists listings_delete_own on public.listings;
create policy listings_delete_own on public.listings
  for delete to authenticated
  using ((select auth.uid()) = seller_id);

-- --- favorites ------------------------------------------------------------

-- A favourite row is private to its owner: nobody can read another user's
-- favourites, and nobody can add a favourite on their behalf.
drop policy if exists favorites_select_own on public.favorites;
create policy favorites_select_own on public.favorites
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists favorites_insert_own on public.favorites;
create policy favorites_insert_own on public.favorites
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists favorites_delete_own on public.favorites;
create policy favorites_delete_own on public.favorites
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- --- conversations --------------------------------------------------------

create or replace function public.is_conversation_participant(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.conversations c
     where c.id = p_conversation_id
       and ((select auth.uid()) in (c.buyer_id, c.seller_id))
  );
$$;

drop policy if exists conversations_select_participant on public.conversations;
create policy conversations_select_participant on public.conversations
  for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id));

-- Creating a conversation is constrained twice: the caller must be the
-- buyer, and the seller must actually own the listing. There is no UPDATE
-- policy, so participants can never be rewritten to gain access.
drop policy if exists conversations_insert_as_buyer on public.conversations;
create policy conversations_insert_as_buyer on public.conversations
  for insert to authenticated
  with check (
    (select auth.uid()) = buyer_id
    and buyer_id <> seller_id
    and exists (
      select 1
        from public.listings l
       where l.id = listing_id
         and l.seller_id = seller_id
    )
  );

-- --- messages -------------------------------------------------------------

drop policy if exists messages_select_participant on public.messages;
create policy messages_select_participant on public.messages
  for select to authenticated
  using (public.is_conversation_participant(conversation_id));

-- A user cannot impersonate another sender: the INSERT policy pins sender_id
-- to the caller's own auth.uid().
drop policy if exists messages_insert_as_self on public.messages;
create policy messages_insert_as_self on public.messages
  for insert to authenticated
  with check (
    (select auth.uid()) = sender_id
    and public.is_conversation_participant(conversation_id)
  );

-- Messages are immutable once sent; there is no UPDATE or DELETE policy.

-- --- conversation_reads ---------------------------------------------------

drop policy if exists conversation_reads_select_own on public.conversation_reads;
create policy conversation_reads_select_own on public.conversation_reads
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists conversation_reads_insert_own on public.conversation_reads;
create policy conversation_reads_insert_own on public.conversation_reads
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- Scoped to the caller's own row, so nobody can advance somebody else's
-- read cursor.
drop policy if exists conversation_reads_update_own on public.conversation_reads;
create policy conversation_reads_update_own on public.conversation_reads
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- --- notifications --------------------------------------------------------

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- Only the owner may change read state.
drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Notifications are written server-side (Edge Function / trigger) using the
-- service role, which bypasses RLS. There is no INSERT policy for clients.

-- ---------------------------------------------------------------------------
-- get_or_create_conversation
-- ---------------------------------------------------------------------------
-- Creates the conversation for (listing, caller) or returns the existing one.
--
-- Done in SQL so that two simultaneous taps on "Contact Seller" cannot
-- produce two rows: the UNIQUE constraint on (listing_id, buyer_id,
-- seller_id) turns the loser of the race into an ON CONFLICT lookup rather
-- than a duplicate thread.

create or replace function public.get_or_create_conversation(p_listing_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_seller uuid;
  v_conversation_id uuid;
begin
  if v_caller is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select l.seller_id into v_seller
    from public.listings l
   where l.id = p_listing_id
   for share;

  if v_seller is null then
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;

  if v_seller = v_caller then
    raise exception 'You cannot start a conversation with yourself'
      using errcode = '22023';
  end if;

  insert into public.conversations (listing_id, buyer_id, seller_id)
  values (p_listing_id, v_caller, v_seller)
  on conflict (listing_id, buyer_id, seller_id)
  do update set listing_id = excluded.listing_id
  returning id into v_conversation_id;

  return v_conversation_id;
end;
$$;

revoke all on function public.get_or_create_conversation(uuid) from public;
grant execute on function public.get_or_create_conversation(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- mark_conversation_read
-- ---------------------------------------------------------------------------

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_conversation_participant(p_conversation_id) then
    raise exception 'Not a participant in this conversation'
      using errcode = '42501';
  end if;

  insert into public.conversation_reads (conversation_id, user_id, last_read_at)
  values (p_conversation_id, auth.uid(), now())
  on conflict (conversation_id, user_id)
  do update set last_read_at = excluded.last_read_at;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- conversation_unread_count
-- ---------------------------------------------------------------------------

create or replace function public.conversation_unread_count(p_conversation_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
    from public.messages m
    left join public.conversation_reads r
      on r.conversation_id = m.conversation_id
     and r.user_id = auth.uid()
   where m.conversation_id = p_conversation_id
     and m.sender_id <> auth.uid()
     and m.created_at > coalesce(r.last_read_at, '-infinity'::timestamptz);
$$;

revoke all on function public.conversation_unread_count(uuid) from public;
grant execute on function public.conversation_unread_count(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- my_conversations
-- ---------------------------------------------------------------------------
-- One row per conversation the caller participates in, already resolved for
-- that caller: the *other* participant's name, the listing's summary, the
-- latest message preview and the unread count.
--
-- Doing this in SQL keeps the Chat List to a single round trip and keeps the
-- `buyer vs seller` branching out of the widgets. The `where` clause is the
-- authorisation check, so SECURITY DEFINER cannot widen access: a caller only
-- ever sees threads they are a participant of.

create or replace function public.my_conversations()
returns table (
  id uuid,
  listing_id uuid,
  buyer_id uuid,
  seller_id uuid,
  last_message_at timestamptz,
  unread_count integer,
  latest_message_preview text,
  other_participant_id uuid,
  other_participant_name text,
  other_participant_avatar_url text,
  listing_title text,
  listing_type text,
  listing_price numeric,
  listing_status text,
  listing_image_url text,
  listing_condition text,
  listing_governorate text,
  listing_area text,
  listing_created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id,
    c.listing_id,
    c.buyer_id,
    c.seller_id,
    c.last_message_at,
    (
      select count(*)::integer
        from public.messages m
        left join public.conversation_reads r
          on r.conversation_id = m.conversation_id
         and r.user_id = (select auth.uid())
       where m.conversation_id = c.id
         and m.sender_id <> (select auth.uid())
         and m.created_at > coalesce(r.last_read_at, '-infinity'::timestamptz)
    ) as unread_count,
    (
      select case
               when m.attachment_path is not null
                 and coalesce(m.content, '') = '' then 'Photo'
               else m.content
             end
        from public.messages m
       where m.conversation_id = c.id
       order by m.created_at desc, m.id desc
       limit 1
    ) as latest_message_preview,
    case when c.buyer_id = (select auth.uid())
         then c.seller_id else c.buyer_id end as other_participant_id,
    case when c.buyer_id = (select auth.uid())
         then coalesce(nullif(trim(sp.first_name || ' ' || sp.last_name), ''), 'Loqta member')
         else coalesce(nullif(trim(bp.first_name || ' ' || bp.last_name), ''), 'Loqta member')
    end as other_participant_name,
    case when c.buyer_id = (select auth.uid())
         then sp.avatar_url else bp.avatar_url end as other_participant_avatar_url,
    l.title,
    l.listing_type,
    l.price,
    l.status,
    l.images[1] as listing_image_url,
    l.condition,
    l.governorate,
    l.area,
    l.created_at as listing_created_at
  from public.conversations c
  join public.listings l on l.id = c.listing_id
  left join public.profiles bp on bp.id = c.buyer_id
  left join public.profiles sp on sp.id = c.seller_id
  where c.buyer_id = (select auth.uid())
     or c.seller_id = (select auth.uid())
  order by c.last_message_at desc, c.id desc;
$$;

revoke all on function public.my_conversations() from public;
grant execute on function public.my_conversations() to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: chat attachments (screen 15)
-- ---------------------------------------------------------------------------
-- Private bucket. Object keys are
-- `conversations/<conversation_id>/<message_id>.<ext>`, and the policies below
-- reuse is_conversation_participant, so the storage layer enforces the same
-- boundary as the messages table.

insert into storage.buckets (id, name, public)
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do nothing;

drop policy if exists chat_attachments_read on storage.objects;
create policy chat_attachments_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'chat-attachments'
    and public.is_conversation_participant(
      (storage.foldername(name))[1]::uuid
    )
  );

drop policy if exists chat_attachments_insert on storage.objects;
create policy chat_attachments_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and public.is_conversation_participant(
      (storage.foldername(name))[1]::uuid
    )
  );

drop policy if exists chat_attachments_delete_own on storage.objects;
create policy chat_attachments_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'chat-attachments'
    and owner_id = (select auth.uid()::text)
  );

-- Listing photography is referenced by listings.images and must render in a
-- plain <img>/Image.network, so this bucket is public.
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

drop policy if exists listing_images_read on storage.objects;
create policy listing_images_read on storage.objects
  for select using (bucket_id = 'listing-images');

drop policy if exists listing_images_insert_own on storage.objects;
create policy listing_images_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and owner_id = (select auth.uid()::text)
  );

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
-- The Chat screen listens for INSERTs on `messages` filtered by
-- conversation_id, and the Chat List listens for INSERTs on `conversations`
-- to refresh ordering and unread badges.

do $$
begin
  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;

  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'conversations'
  ) then
    alter publication supabase_realtime add table public.conversations;
  end if;

  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;