-- ============================================================
-- Sunshine PI Desk — hide totals from the shared log + add an admin role
-- Run this in Supabase's SQL Editor (New snippet) on your EXISTING project.
-- ============================================================

-- ---------- 1. Stop exposing the grand total in the shared log ----------
-- Only the creator (via View, which is already creator-only) sees the
-- actual total. The shared list only shows who/what/when, not money.
create or replace function public.get_pi_log()
returns table (
  id uuid,
  pi_number text,
  pi_date date,
  company text,
  buyer_name text,
  created_by text,
  user_id uuid
)
language sql
security definer
set search_path = public
as $$
  select id, pi_number, pi_date, company, buyer_name, created_by, user_id
  from public.pis
  order by created_at desc;
$$;

-- ---------- 2. Add a profile per user, with an is_admin flag ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  is_admin boolean not null default false
);

alter table public.profiles enable row level security;

drop policy if exists "Users can view their own profile" on public.profiles;
create policy "Users can view their own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

-- Auto-create a profile row whenever someone signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Backfill profiles for anyone who signed up before this migration existed
insert into public.profiles (id, full_name)
select id, raw_user_meta_data->>'full_name' from auth.users
on conflict (id) do nothing;

-- Helper usable inside RLS policies to check admin status
create or replace function public.is_admin(uid uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = uid), false);
$$;

-- ---------- 3. Let admins view/edit/delete ANY PI, not just their own ----------
drop policy if exists "Users can view their own PIs" on public.pis;
create policy "Users can view their own PIs, admins view all"
on public.pis
for select
to authenticated
using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "Users can update their own PIs" on public.pis;
create policy "Users can update their own PIs, admins update all"
on public.pis
for update
to authenticated
using (auth.uid() = user_id or public.is_admin(auth.uid()))
with check (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "Users can delete their own PIs" on public.pis;
create policy "Users can delete their own PIs, admins delete all"
on public.pis
for delete
to authenticated
using (auth.uid() = user_id or public.is_admin(auth.uid()));

-- ============================================================
-- LAST STEP (do this manually, once, for whoever should be admin):
--   Table Editor → profiles → find their row → set is_admin to true.
--   You can match the row by full_name, or cross-check the id against
--   Authentication → Users to find the right person by email.
-- ============================================================
