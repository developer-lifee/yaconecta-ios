create extension if not exists pgcrypto;

create type public.community_role as enum ('neighbor', 'merchant', 'courier', 'moderator');
create type public.news_category as enum ('roads', 'emergency', 'public_service', 'community', 'mourning');
create type public.news_urgency as enum ('informative', 'important', 'urgent');
create type public.verification_status as enum ('unverified', 'community_confirmed', 'verified');
create type public.moderation_status as enum ('published', 'hidden', 'removed');

create table public.towns (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    region text not null,
    country_code text not null default 'CO',
    created_at timestamptz not null default now(),
    unique (name, region, country_code)
);

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    town_id uuid references public.towns(id),
    display_name text not null default 'Vecino',
    avatar_url text,
    role public.community_role not null default 'neighbor',
    reputation integer not null default 0 check (reputation >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.local_news (
    id uuid primary key default gen_random_uuid(),
    town_id uuid not null references public.towns(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    title text not null check (char_length(title) between 8 and 140),
    body text not null check (char_length(body) between 20 and 4000),
    category public.news_category not null,
    urgency public.news_urgency not null default 'important',
    location_text text not null check (char_length(location_text) between 3 and 180),
    source_note text check (char_length(source_note) <= 500),
    verification public.verification_status not null default 'unverified',
    moderation public.moderation_status not null default 'published',
    confirmation_count integer not null default 0 check (confirmation_count >= 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table public.news_confirmations (
    news_id uuid not null references public.local_news(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (news_id, user_id)
);

create table public.news_reports (
    id uuid primary key default gen_random_uuid(),
    news_id uuid not null references public.local_news(id) on delete cascade,
    reporter_id uuid not null references public.profiles(id) on delete cascade,
    reason text not null check (char_length(reason) between 5 and 500),
    created_at timestamptz not null default now(),
    unique (news_id, reporter_id)
);

create index local_news_town_created_idx on public.local_news (town_id, created_at desc);
create index local_news_urgent_idx on public.local_news (town_id, urgency, created_at desc)
where moderation = 'published';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    insert into public.profiles (id, display_name, avatar_url)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, 'Vecino'), '@', 1)),
        new.raw_user_meta_data ->> 'avatar_url'
    );
    return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_town_moderator(requested_town_id uuid)
returns boolean
language sql
stable
security definer set search_path = ''
as $$
    select exists (
        select 1 from public.profiles
        where id = auth.uid()
          and town_id = requested_town_id
          and role = 'moderator'
    );
$$;

create or replace function public.protect_new_news()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    new.author_id := auth.uid();
    new.verification := 'unverified';
    new.moderation := 'published';
    new.confirmation_count := 0;
    return new;
end;
$$;

create trigger protect_new_news_trigger
before insert on public.local_news
for each row execute procedure public.protect_new_news();

create or replace function public.protect_news_moderation_fields()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    -- Allow trusted trigger-driven aggregates such as confirmation_count.
    if pg_trigger_depth() > 1 then
        return new;
    end if;
    if not public.is_town_moderator(old.town_id) then
        new.author_id := old.author_id;
        new.town_id := old.town_id;
        new.verification := old.verification;
        new.moderation := old.moderation;
        new.confirmation_count := old.confirmation_count;
    end if;
    new.updated_at := now();
    return new;
end;
$$;

create trigger protect_news_moderation_fields_trigger
before update on public.local_news
for each row execute procedure public.protect_news_moderation_fields();

create or replace function public.refresh_news_confirmation_count()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    target_news_id uuid := coalesce(new.news_id, old.news_id);
    total integer;
begin
    select count(*) into total
    from public.news_confirmations
    where news_id = target_news_id;

    update public.local_news
    set confirmation_count = total,
        verification = case
            when verification = 'verified' then 'verified'::public.verification_status
            when total >= 3 then 'community_confirmed'::public.verification_status
            else 'unverified'::public.verification_status
        end,
        updated_at = now()
    where id = target_news_id;
    return coalesce(new, old);
end;
$$;

create trigger news_confirmation_changed
after insert or delete on public.news_confirmations
for each row execute procedure public.refresh_news_confirmation_count();

alter table public.towns enable row level security;
alter table public.profiles enable row level security;
alter table public.local_news enable row level security;
alter table public.news_confirmations enable row level security;
alter table public.news_reports enable row level security;

create policy "towns are public"
on public.towns for select using (true);

create policy "profiles are visible"
on public.profiles for select using (true);

create policy "users update their profile"
on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

create policy "published news is public"
on public.local_news for select
using (moderation = 'published' or author_id = auth.uid() or public.is_town_moderator(town_id));

create policy "authenticated users create news"
on public.local_news for insert to authenticated
with check (
    author_id = auth.uid()
    and exists (select 1 from public.profiles where id = auth.uid() and town_id = local_news.town_id)
);

create policy "authors edit unverified news"
on public.local_news for update to authenticated
using (author_id = auth.uid() and verification = 'unverified')
with check (author_id = auth.uid() and verification = 'unverified');

create policy "moderators manage town news"
on public.local_news for update to authenticated
using (public.is_town_moderator(town_id))
with check (public.is_town_moderator(town_id));

create policy "confirmations are public"
on public.news_confirmations for select using (true);

create policy "users confirm as themselves"
on public.news_confirmations for insert to authenticated
with check (user_id = auth.uid());

create policy "users remove their confirmation"
on public.news_confirmations for delete to authenticated
using (user_id = auth.uid());

create policy "users submit one report"
on public.news_reports for insert to authenticated
with check (reporter_id = auth.uid());

insert into public.towns (id, name, region) values
    ('10000000-0000-0000-0000-000000000001', 'Guaduas', 'Cundinamarca'),
    ('10000000-0000-0000-0000-000000000002', 'Honda', 'Tolima'),
    ('10000000-0000-0000-0000-000000000003', 'Jardín', 'Antioquia')
on conflict do nothing;
