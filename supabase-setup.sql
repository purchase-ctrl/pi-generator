-- ============================================================
-- Sunshine PI Desk — Supabase database setup
-- Run this once in your Supabase project's SQL Editor
-- (Dashboard → SQL Editor → New query → paste all of this → Run)
-- ============================================================

create table public.pis (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_by text not null,
  company text not null,
  pi_number text not null,
  ref_po text,
  buyer_name text not null,
  buyer_contact text,
  buyer_phone text,
  buyer_email text,
  buyer_gst text,
  buyer_address text,
  pi_date date,
  valid_until date,
  currency text default '₹',
  tax_pct numeric default 18,
  tc_version text,
  notes text,
  items jsonb not null default '[]',
  subtotal numeric default 0,
  tax numeric default 0,
  grand_total numeric default 0,
  advance_without_gst numeric default 0,
  advance_with_gst numeric default 0,
  advance_total numeric default 0,
  balance_due numeric default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Row Level Security: this is the real security boundary.
-- Even if someone guesses or is given a PI's link/id, the database
-- itself will refuse to return it unless user_id matches their own
-- logged-in account. This is enforced server-side and cannot be
-- bypassed from the browser, unlike a client-side passcode check.
alter table public.pis enable row level security;

create policy "Users manage only their own PIs"
on public.pis
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Keep updated_at current on every edit
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger pis_set_updated_at
before update on public.pis
for each row execute function public.set_updated_at();
