-- Migration 0005: Business WhatsApp, Instagram, Custom Tags & User Profile Avatars

alter table public.businesses
    add column if not exists whatsapp_number text,
    add column if not exists instagram_handle text,
    add column if not exists tags text[] default '{}',
    add column if not exists owner_id uuid references auth.users(id) on delete set null;

alter table public.profiles
    add column if not exists avatar_url text;

-- Index for searching business tags efficiently
create index if not exists idx_businesses_tags on public.businesses using gin (tags);
