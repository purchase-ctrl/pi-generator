-- ============================================================
-- Sunshine PI Desk — Client profiles
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
-- Needs is_admin() and set_updated_at() from the earlier setup scripts.
--
-- Everyone signed in can SEE all client profiles (a shared address book, so any
-- team member can pick a client when making a PI). Only the person who added a
-- profile, or an admin, can change or delete it.
-- To make profiles private instead, change the select policy below to:
--   using (auth.uid() = user_id or public.is_admin(auth.uid()))
-- ============================================================
create table if not exists public.client_profiles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_by  text not null,
  name        text not null,
  brand_name  text not null default '',
  contact     text,
  phone       text,
  email       text,
  gst         text,
  address     text,
  other       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- one profile per client + brand (case-insensitive)
create unique index if not exists client_profiles_name_brand_uq
  on public.client_profiles (lower(name), lower(brand_name));

alter table public.client_profiles enable row level security;

drop policy if exists "client_profiles select all" on public.client_profiles;
create policy "client_profiles select all" on public.client_profiles
  for select to authenticated using (true);

drop policy if exists "client_profiles insert own" on public.client_profiles;
create policy "client_profiles insert own" on public.client_profiles
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "client_profiles update own or admin" on public.client_profiles;
create policy "client_profiles update own or admin" on public.client_profiles
  for update to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()))
  with check (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "client_profiles delete own or admin" on public.client_profiles;
create policy "client_profiles delete own or admin" on public.client_profiles
  for delete to authenticated
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop trigger if exists client_profiles_set_updated_at on public.client_profiles;
create trigger client_profiles_set_updated_at before update on public.client_profiles
  for each row execute function public.set_updated_at();
