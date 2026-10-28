-- Create reservations table
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for performance
create index if not exists reservations_listing_id_idx on public.reservations (listing_id);
create index if not exists reservations_buyer_id_idx on public.reservations (buyer_id);

-- Create transactions table
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for performance
create index if not exists transactions_listing_id_idx on public.transactions (listing_id);
create index if not exists transactions_buyer_id_idx on public.transactions (buyer_id);
create index if not exists transactions_seller_id_idx on public.transactions (seller_id);

-- Add RLS policies
alter table public.reservations enable row level security;
alter table public.transactions enable row level security;

create policy "Users can view their own reservations" on public.reservations
  for select to authenticated using (buyer_id = auth.uid() or exists (select 1 from public.listings where id = listing_id and seller_id = auth.uid()));

create policy "Users can view their own transactions" on public.transactions
  for select to authenticated using (buyer_id = auth.uid() or seller_id = auth.uid());
