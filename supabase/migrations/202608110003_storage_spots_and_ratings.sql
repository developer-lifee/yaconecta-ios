-- Migration: 202608110003_storage_spots_and_ratings.sql
-- Description: Adds Supabase Storage buckets, Town Spots (turismo local), and Completed Deals / Reviews tables.

-- 1. Create Enums
create type public.spot_category as enum ('photo', 'chill', 'nature', 'history');

-- 2. Create Town Spots Table
create table public.town_spots (
    id uuid primary key default gen_random_uuid(),
    town_id uuid not null references public.towns(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    name text not null check (char_length(name) between 3 and 120),
    description text not null check (char_length(description) between 10 and 1500),
    category public.spot_category not null default 'chill',
    photo_url text,
    location_note text not null check (char_length(location_note) <= 250),
    likes_count integer not null default 0 check (likes_count >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 3. Create Completed Deals Table (Contador de tratos)
create table public.completed_deals (
    id uuid primary key default gen_random_uuid(),
    town_id uuid not null references public.towns(id) on delete cascade,
    request_id uuid references public.local_requests(id) on delete set null,
    client_id uuid not null references public.profiles(id) on delete cascade,
    provider_id uuid not null references public.profiles(id) on delete cascade,
    business_id uuid references public.businesses(id) on delete set null,
    agreed_price integer check (agreed_price >= 0),
    completed_at timestamptz not null default now()
);

-- 4. Create Reviews Table (Calificaciones)
create table public.merchant_reviews (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    rating integer not null check (rating >= 1 and rating <= 5),
    comment text check (char_length(comment) <= 600),
    created_at timestamptz not null default now(),
    unique (business_id, author_id)
);

-- Indexes
create index town_spots_town_idx on public.town_spots (town_id, category);
create index completed_deals_provider_idx on public.completed_deals (provider_id);
create index completed_deals_client_idx on public.completed_deals (client_id);
create index merchant_reviews_business_idx on public.merchant_reviews (business_id);

-- Trigger to recalculate business rating automatically
create or replace function public.refresh_business_rating()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    target_business_id uuid := coalesce(new.business_id, old.business_id);
    avg_rating numeric(3,2);
    total_reviews integer;
begin
    select coalesce(avg(rating), 5.0), count(*)
    into avg_rating, total_reviews
    from public.merchant_reviews
    where business_id = target_business_id;

    update public.businesses
    set rating = avg_rating,
        review_count = total_reviews,
        updated_at = now()
    where id = target_business_id;
    return coalesce(new, old);
end;
$$;

create trigger on_merchant_review_changed
after insert or update or delete on public.merchant_reviews
for each row execute procedure public.refresh_business_rating();

-- RLS Policies
alter table public.town_spots enable row level security;
alter table public.completed_deals enable row level security;
alter table public.merchant_reviews enable row level security;

create policy "spots are public" on public.town_spots for select using (true);
create policy "users create spots" on public.town_spots for insert to authenticated with check (author_id = auth.uid());
create policy "authors update spots" on public.town_spots for update to authenticated using (author_id = auth.uid());

create policy "deals visible to participants" on public.completed_deals for select to authenticated
using (client_id = auth.uid() or provider_id = auth.uid());

create policy "reviews are public" on public.merchant_reviews for select using (true);
create policy "users create reviews" on public.merchant_reviews for insert to authenticated with check (author_id = auth.uid());

-- 5. Supabase Storage Buckets Setup
insert into storage.buckets (id, name, public)
values 
    ('product-images', 'product-images', true),
    ('request-attachments', 'request-attachments', true),
    ('spot-photos', 'spot-photos', true),
    ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Storage Policies for Public Reading and Authenticated Uploading
create policy "public read product-images" on storage.objects for select using (bucket_id = 'product-images');
create policy "authenticated upload product-images" on storage.objects for insert to authenticated with check (bucket_id = 'product-images');

create policy "public read spot-photos" on storage.objects for select using (bucket_id = 'spot-photos');
create policy "authenticated upload spot-photos" on storage.objects for insert to authenticated with check (bucket_id = 'spot-photos');

create policy "public read avatars" on storage.objects for select using (bucket_id = 'avatars');
create policy "authenticated upload avatars" on storage.objects for insert to authenticated with check (bucket_id = 'avatars');
