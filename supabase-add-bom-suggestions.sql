-- ============================================================
-- Sunshine PI Desk — name suggestions for the BOM sheet
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
-- Returns only buyer name, brand name and product names of every PI the team
-- has created (no prices, contacts, GST or totals), so the BOM drop-downs
-- list everyone, not just your own PIs.
-- ============================================================
create or replace function public.get_pi_names()
returns table (buyer_name text, brand_name text, product text)
language sql security definer set search_path = public as $$
  select distinct p.buyer_name, coalesce(p.brand_name,''), coalesce(i->>'product','')
  from public.pis p
  left join lateral jsonb_array_elements(coalesce(p.items,'[]'::jsonb)) i on true
  where coalesce(p.buyer_name,'') <> '';
$$;
revoke all on function public.get_pi_names() from public;
grant execute on function public.get_pi_names() to authenticated;
