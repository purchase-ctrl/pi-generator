-- ============================================================
-- Sunshine PI Desk — BOM (Bill of Materials) generator
-- Run this ONCE in Supabase (SQL Editor -> New query -> paste -> Run)
-- BEFORE the BOM pages go live. Safe to run more than once.
-- Requires the is_admin() function from supabase-update-admin-role.sql.
-- ============================================================

create table if not exists public.boms (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_by  text not null,
  pi_id       uuid references public.pis(id) on delete set null,
  pi_number   text,
  bom_date    date,
  recv_date   date,
  company_name text,
  brand_name  text,
  product_name text,
  sku_size    text,
  mrp         text,
  usp         text,
  rows        jsonb not null default '[]'::jsonb,
  special     text,
  prepared_by text,
  checked_by  text,
  approved_by text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists boms_pi_id_idx on public.boms(pi_id);

alter table public.boms enable row level security;

drop policy if exists "boms select own or admin" on public.boms;
create policy "boms select own or admin" on public.boms
  for select to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "boms insert own" on public.boms;
create policy "boms insert own" on public.boms
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "boms update own or admin" on public.boms;
create policy "boms update own or admin" on public.boms
  for update to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()))
  with check (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "boms delete own or admin" on public.boms;
create policy "boms delete own or admin" on public.boms
  for delete to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

-- keep updated_at fresh (set_updated_at() already exists from supabase-setup.sql)
drop trigger if exists boms_set_updated_at on public.boms;
create trigger boms_set_updated_at before update on public.boms
  for each row execute function public.set_updated_at();

-- Shared log: every signed-in user can see WHO made WHICH BOM, nothing more.
create or replace function public.get_bom_log()
returns table (
  id uuid, user_id uuid, created_by text, pi_id uuid, pi_number text,
  bom_date date, company_name text, brand_name text, product_name text, created_at timestamptz
)
language sql security definer set search_path = public as $$
  select b.id, b.user_id, b.created_by, b.pi_id, b.pi_number,
         b.bom_date, b.company_name, b.brand_name, b.product_name, b.created_at
  from public.boms b
  order by b.created_at desc;
$$;
revoke all on function public.get_bom_log() from public;
grant execute on function public.get_bom_log() to authenticated;
