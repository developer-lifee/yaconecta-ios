-- Migration: 202608110002_businesses_products_requests.sql
-- Description: Adds businesses, products, local requests, and request offers with RLS security policies.

create type public.business_category as enum ('food', 'market', 'pharmacy', 'transport', 'services');
create type public.request_category as enum ('delivery', 'transport', 'errand', 'service', 'wanted');
create type public.request_status as enum ('published', 'agreed', 'on_the_way', 'completed');

-- 1. Businesses Table
create table public.businesses (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references public.profiles(id) on delete cascade,
    town_id uuid not null references public.towns(id) on delete cascade,
    name text not null check (char_length(name) between 3 and 100),
    category public.business_category not null default 'services',
    summary text not null check (char_length(summary) <= 300),
    eta_minutes integer not null default 20 check (eta_minutes >= 0),
    delivery_price integer not null default 0 check (delivery_price >= 0),
    rating numeric(3,2) not null default 5.0 check (rating >= 0 and rating <= 5.0),
    review_count integer not null default 0 check (review_count >= 0),
    is_open boolean not null default true,
    symbol text not null default 'storefront.fill',
    color_name text not null default 'coral',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Products Table (Inventory for stores/ferreterías/remates)
create table public.products (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    name text not null check (char_length(name) between 2 and 150),
    detail text check (char_length(detail) <= 500),
    price integer not null default 0 check (price >= 0),
    stock_available integer check (stock_available >= 0),
    category_tag text check (char_length(category_tag) <= 50),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 3. Local Requests Table
create table public.local_requests (
    id uuid primary key default gen_random_uuid(),
    town_id uuid not null references public.towns(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    title text not null check (char_length(title) between 5 and 140),
    detail text not null check (char_length(detail) between 8 and 2000),
    category public.request_category not null default 'delivery',
    area text not null default 'Centro' check (char_length(area) <= 100),
    budget integer check (budget >= 0),
    offer_count integer not null default 0 check (offer_count >= 0),
    status public.request_status not null default 'published',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 4. Request Offers Table
create table public.request_offers (
    id uuid primary key default gen_random_uuid(),
    request_id uuid not null references public.local_requests(id) on delete cascade,
    offerer_id uuid not null references public.profiles(id) on delete cascade,
    business_id uuid references public.businesses(id) on delete cascade,
    price integer check (price >= 0),
    message text not null check (char_length(message) between 2 and 1000),
    created_at timestamptz not null default now(),
    unique (request_id, offerer_id)
);

-- Indexes for efficient querying & matching
create index businesses_town_category_idx on public.businesses (town_id, category);
create index products_business_idx on public.products (business_id);
create index products_name_trgm_idx on public.products using gin (to_tsvector('spanish', name));
create index local_requests_town_created_idx on public.local_requests (town_id, created_at desc);

-- RLS (Row Level Security)
alter table public.businesses enable row level security;
alter table public.products enable row level security;
alter table public.local_requests enable row level security;
alter table public.request_offers enable row level security;

-- Policies for Businesses
create policy "businesses are public" on public.businesses for select using (true);

create policy "merchants create business" on public.businesses for insert to authenticated
with check (owner_id = auth.uid());

create policy "merchants update own business" on public.businesses for update to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "merchants delete own business" on public.businesses for delete to authenticated
using (owner_id = auth.uid());

-- Policies for Products
create policy "products are public" on public.products for select using (true);

create policy "merchants manage own products" on public.products for all to authenticated
using (exists (select 1 from public.businesses where id = products.business_id and owner_id = auth.uid()))
with check (exists (select 1 from public.businesses where id = products.business_id and owner_id = auth.uid()));

-- Policies for Requests
create policy "requests are public" on public.local_requests for select using (true);

create policy "users create requests" on public.local_requests for insert to authenticated
with check (author_id = auth.uid());

create policy "authors manage own requests" on public.local_requests for update to authenticated
using (author_id = auth.uid()) with check (author_id = auth.uid());

-- Policies for Offers
create policy "offers visible to author and offerer" on public.request_offers for select to authenticated
using (
    offerer_id = auth.uid() or
    exists (select 1 from public.local_requests where id = request_offers.request_id and author_id = auth.uid())
);

create policy "users create offers" on public.request_offers for insert to authenticated
with check (offerer_id = auth.uid());
