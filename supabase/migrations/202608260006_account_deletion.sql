-- Migration: 202608260006_account_deletion.sql
-- Description: Adds RPC function to permanently delete the authenticated user's account and all associated data (Apple App Store Guideline 5.1.1(v) compliance).

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer set search_path = ''
as $$
declare
    current_uid uuid := auth.uid();
begin
    if current_uid is null then
        raise exception 'No autenticado o sesión inválida';
    end if;

    -- Deleting the user from auth.users cascades to public.profiles and all related records:
    -- (businesses, products, local_news, news_confirmations, news_reports, local_requests,
    -- request_offers, town_spots, completed_deals, merchant_reviews)
    delete from auth.users where id = current_uid;
end;
$$;

grant execute on function public.delete_user_account() to authenticated;
