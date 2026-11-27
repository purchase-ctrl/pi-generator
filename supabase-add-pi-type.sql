-- ============================================================
-- Sunshine PI Desk — PI Type
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
-- Adds a "PI type" to every PI (FG, Primary Packaging, Secondary Packaging, RM+C, All Four)
-- and a shared, editable list of types.
--   * any signed-in user can ADD a type
--   * a type can be REMOVED only by the person who added it, or by an admin
--     (the five starting types are owned by admins)
-- Removing a type from the list never changes PIs that already use it.
-- ============================================================
alter table public.pis add column if not exists pi_type text;

create table if not exists public.pi_types (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  sort_order      int  not null default 100,
  created_by      uuid references auth.users(id) on delete set null,
  created_by_name text,
  created_at      timestamptz not null default now()
);
create unique index if not exists pi_types_name_uq on public.pi_types (lower(name));
alter table public.pi_types enable row level security;

drop policy if exists "pi_types read"   on public.pi_types;
drop policy if exists "pi_types add"    on public.pi_types;
drop policy if exists "pi_types remove" on public.pi_types;
create policy "pi_types read"   on public.pi_types for select to authenticated using (true);
create policy "pi_types add"    on public.pi_types for insert to authenticated with check (created_by = auth.uid());
create policy "pi_types remove" on public.pi_types for delete to authenticated
  using (created_by = auth.uid() or public.is_admin(auth.uid()));

insert into public.pi_types (name, sort_order) values
  ('FG (Finished Good)', 1),
  ('Primary Packaging',  2),
  ('Secondary Packaging',3),
  ('RM+C',               4),
  ('All Four',           5)
on conflict do nothing;

-- the shared PI log gets one extra column (pi_type), so the function has to be re-created
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
  cancelled_at timestamptz,
  pi_type text
)
language sql
security definer
set search_path = public
as $$
  select id, pi_number, pi_date, company, buyer_name, created_by, user_id, cancelled_at, pi_type
  from public.pis
  order by created_at desc;
$$;
revoke all on function public.get_pi_log() from public;
grant execute on function public.get_pi_log() to authenticated;
