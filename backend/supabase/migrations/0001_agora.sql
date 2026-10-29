-- Agora Marketplace database
-- Buyers, sellers and Agora staff (admin) share one users table (auth.users) plus a profile.
-- Row-level security makes sure each person only sees their own orders and deliveries.

create extension if not exists pgcrypto;

-- People ------------------------------------------------------------------

create type user_role as enum ('buyer', 'seller', 'admin');

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  role user_role not null default 'buyer',
  full_name text not null default '',
  phone text,
  created_at timestamptz not null default now()
);

create or replace function is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- Stores --------------------------------------------------------------------

create type verify_status as enum ('pending', 'verified', 'rejected', 'suspended');

create table stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles on delete cascade,
  handle text not null unique check (handle ~ '^[a-z0-9]{3,30}$'),   -- agoramarket.ng/<handle>
  name text not null,
  description text not null default '',
  categories text[] not null default '{}',
  logo_url text,
  -- verification
  status verify_status not null default 'pending',
  business_type text not null default 'individual',      -- registered | individual
  cac_number text,
  instagram text,
  -- pickup address used by GIG
  street text not null default '',
  area text not null default '',
  city text not null default '',
  state text not null default '',
  landmark text,
  pickup_phone text,
  -- payouts (Bachs payout destination, resolved name from the bank)
  bank_code text,
  account_number text,
  account_name text,
  bachs_destination_id text,
  created_at timestamptz not null default now()
);
create index on stores (owner_id);

-- Documents sellers upload for verification live in the private "kyc" storage bucket.
create table store_documents (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references stores on delete cascade,
  kind text not null,                     -- id_front | selfie | cac | proof_of_address | shop_photo
  path text not null,                     -- path inside the kyc bucket
  status text not null default 'pending', -- pending | approved | rejected
  note text,
  created_at timestamptz not null default now()
);

-- Products ---------------------------------------------------------------------

create table products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references stores on delete cascade,
  name text not null,
  description text not null default '',
  category text not null,
  price integer not null check (price > 0),          -- naira
  stock integer not null default 1,
  weight_kg numeric not null default 1,               -- used for GIG pricing
  sizes text[],
  images text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index on products (store_id);

-- Orders and escrow ----------------------------------------------------------------

create type order_status as enum ('awaiting_payment', 'held', 'dispatched', 'delivered', 'released', 'refunded', 'disputed', 'cancelled', 'failed');

create table orders (
  id text primary key,                                -- AGR-XXXX-XXXX
  buyer_id uuid not null references profiles,
  store_id uuid not null references stores,
  status order_status not null default 'awaiting_payment',
  items jsonb not null,                               -- [{product_id, name, price, qty, size}]
  subtotal integer not null,
  delivery_fee integer not null,
  total integer generated always as (subtotal + delivery_fee) stored,
  delivery_service text not null default 'home',      -- home | centre
  ship_name text not null,
  ship_phone text not null,
  ship_address text not null,
  ship_city text not null,
  ship_state text not null,
  ship_notes text,
  -- payments (Bachs)
  bachs_checkout_id text,
  bachs_charge_id text,
  paid_at timestamptz,
  delivered_at timestamptz,
  confirmed_at timestamptz,                           -- buyer confirmed delivery
  released_at timestamptz,                            -- money paid out to seller
  bachs_payout_id text,
  confirm_photo text,
  created_at timestamptz not null default now()
);
create index on orders (buyer_id);
create index on orders (store_id);

-- Deliveries (GIG Logistics) -----------------------------------------------------------

create type ship_stage as enum ('booked', 'picked', 'transit', 'arrived', 'out', 'delivered', 'failed', 'cancelled');

create table shipments (
  id uuid primary key default gen_random_uuid(),
  order_id text not null unique references orders on delete cascade,
  carrier text not null default 'gig',
  waybill text unique,
  service text not null default 'home',
  stage ship_stage not null default 'booked',
  price integer not null default 0,
  eta text,
  from_name text, from_city text,
  to_name text, to_city text, to_phone text,
  pod_name text,
  pod_photo text,
  last_error text,                                    -- booking errors, retried by gig-sync
  attempts integer not null default 0,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table shipment_events (
  id bigint generated always as identity primary key,
  shipment_id uuid not null references shipments on delete cascade,
  stage ship_stage not null,
  code text,                                          -- GIG status code
  title text not null,                                -- GIG status description
  location text,
  at timestamptz not null,
  unique (shipment_id, code, at)
);
create index on shipment_events (shipment_id, at);

-- Who can see what ----------------------------------------------------------------------

alter table profiles enable row level security;
alter table stores enable row level security;
alter table store_documents enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table shipments enable row level security;
alter table shipment_events enable row level security;

create policy "own profile" on profiles for select using (id = auth.uid() or is_admin());
create policy "update own profile" on profiles for update using (id = auth.uid()) with check (role = (select role from profiles where id = auth.uid()));

-- Verified stores are public (store links work for anyone). Owners and admins see all fields.
create policy "public stores" on stores for select using (status = 'verified' or owner_id = auth.uid() or is_admin());
create policy "owner creates store" on stores for insert with check (owner_id = auth.uid() and status = 'pending');
create policy "owner edits store" on stores for update using (owner_id = auth.uid() or is_admin());

create policy "owner docs" on store_documents for all using (exists (select 1 from stores s where s.id = store_id and s.owner_id = auth.uid()) or is_admin());

create policy "public products" on products for select using (active and exists (select 1 from stores s where s.id = store_id and s.status = 'verified') or exists (select 1 from stores s where s.id = store_id and s.owner_id = auth.uid()) or is_admin());
create policy "owner manages products" on products for all using (exists (select 1 from stores s where s.id = store_id and s.owner_id = auth.uid()));

-- Orders: the buyer, the store owner and Agora staff. Money states only change on the server.
create policy "order parties" on orders for select using (buyer_id = auth.uid() or exists (select 1 from stores s where s.id = store_id and s.owner_id = auth.uid()) or is_admin());
create policy "buyer creates order" on orders for insert with check (buyer_id = auth.uid() and status = 'awaiting_payment');

create policy "shipment parties" on shipments for select using (exists (
  select 1 from orders o join stores s on s.id = o.store_id
  where o.id = order_id and (o.buyer_id = auth.uid() or s.owner_id = auth.uid())) or is_admin());
create policy "event parties" on shipment_events for select using (exists (select 1 from shipments sh where sh.id = shipment_id));

-- Store links: look up a verified store by handle without signing in.
create or replace function store_by_handle(h text) returns setof stores language sql stable as $$
  select * from stores where handle = lower(h) and status = 'verified'
$$;

-- Live tracking: the app subscribes to these tables.
alter publication supabase_realtime add table shipments, shipment_events, orders;

-- Background jobs (needs pg_cron and pg_net, both available on Supabase):
--   every 15 minutes, pull GIG tracking for parcels on the move and retry failed bookings
--   every hour, release escrow for orders delivered more than 72 hours ago without a dispute
-- Run once after deploying the functions (replace <project> and <service key>):
-- select cron.schedule('gig-sync', '*/15 * * * *', $$select net.http_post('https://<project>.supabase.co/functions/v1/gig-sync', '{}'::jsonb, headers => '{"Authorization":"Bearer <service key>"}'::jsonb)$$);
-- select cron.schedule('escrow-auto-release', '7 * * * *', $$select net.http_post('https://<project>.supabase.co/functions/v1/escrow', '{"action":"auto_release"}'::jsonb, headers => '{"Authorization":"Bearer <service key>"}'::jsonb)$$);
