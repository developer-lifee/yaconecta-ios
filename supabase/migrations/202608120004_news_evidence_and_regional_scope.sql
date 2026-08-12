-- Migration 0004: News Evidence Attachments & Regional Scope (Cubarral - El Dorado - Guamal)

alter table public.local_news
    add column if not exists image_url text,
    add column if not exists is_regional boolean not null default false;

-- Create Storage Bucket for News Evidence if it doesn't exist
insert into storage.buckets (id, name, public)
values ('news-evidence', 'news-evidence', true)
on conflict (id) do update set public = true;

-- Security Policies for news-evidence bucket
create policy "news evidence images are publicly accessible"
    on storage.objects for select
    using (bucket_id = 'news-evidence');

create policy "authenticated users can upload news evidence"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'news-evidence');
