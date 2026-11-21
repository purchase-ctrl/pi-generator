-- ============================================================
-- Sunshine PI Desk — Cancel a PI
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
-- Adds cancel columns to PIs and lets the shared PI Log show which PIs are cancelled.
-- Cancelled PIs stay in the log (marked CANCELLED); the Order Desk removes their PO.
-- ============================================================
alter table public.pis
  add column if not exists cancelled_at   timestamptz,
  add column if not exists cancelled_by   text,
  add column if not exists cancel_reason  text;

-- the log function gets one extra column (cancelled_at), so it has to be re-created
drop function if exists public.get_pi_log();
create function public.get_pi_log()
returns table (
  id uuid,
  pi_number text,
  pi_date date,
  company text,
  buyer_name text,
  created_by text,
  user_id uuid,
  cancelled_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select id, pi_number, pi_date, company, buyer_name, created_by, user_id, cancelled_at
  from public.pis
  order by created_at desc;
$$;
revoke all on function public.get_pi_log() from public;
grant execute on function public.get_pi_log() to authenticated;
