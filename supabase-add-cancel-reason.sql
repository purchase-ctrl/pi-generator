-- ============================================================
-- Sunshine PI Desk — Cancel reason is REQUIRED and PRIVATE
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run). Safe to re-run.
--   * A PI can only be cancelled with a written reason (enforced in the database).
--   * The reason is stored in its own table that only the PI's creator and admins can read.
--   * Existing reasons are moved over from pis.cancel_reason (which is then cleared).
-- Requires supabase-add-cancel-pi.sql to have been run before.
-- ============================================================
create table if not exists public.pi_cancel_reasons (
  pi_id        uuid primary key references public.pis(id) on delete cascade,
  reason       text not null,
  cancelled_by text,
  cancelled_at timestamptz not null default now()
);
alter table public.pi_cancel_reasons enable row level security;

drop policy if exists "cancel reasons: creator or admin read" on public.pi_cancel_reasons;
create policy "cancel reasons: creator or admin read" on public.pi_cancel_reasons
  for select to authenticated
  using (exists (select 1 from public.pis p
                 where p.id = pi_cancel_reasons.pi_id
                   and (p.user_id = auth.uid() or public.is_admin(auth.uid()))));
-- no insert/update/delete policies on purpose: reasons are written only by cancel_pi() below

-- move reasons that were saved before this change, then clear the old, publicly readable column
insert into public.pi_cancel_reasons (pi_id, reason, cancelled_by, cancelled_at)
  select id, btrim(cancel_reason), cancelled_by, coalesce(cancelled_at, now())
  from public.pis
  where cancelled_at is not null and btrim(coalesce(cancel_reason,'')) <> ''
on conflict (pi_id) do nothing;
update public.pis set cancel_reason = null where cancel_reason is not null;

-- the only way to cancel: creator or admin, with a reason
create or replace function public.cancel_pi(p_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  owner uuid;
  already timestamptz;
  nm text;
  r text := btrim(coalesce(p_reason, ''));
begin
  if uid is null then raise exception 'Not signed in'; end if;
  if length(r) < 3 then raise exception 'A reason for cancelling is required'; end if;
  select user_id, cancelled_at into owner, already from public.pis where id = p_id;
  if not found then raise exception 'PI not found'; end if;
  if owner is distinct from uid and not public.is_admin(uid) then
    raise exception 'Only the PI creator or an admin can cancel this PI';
  end if;
  if already is not null then raise exception 'This PI is already cancelled'; end if;

  select nullif(btrim(full_name), '') into nm from public.profiles where id = uid;
  nm := coalesce(nm, (select email from auth.users where id = uid));

  -- reason first, then the cancel flag (the trigger below checks that the reason exists)
  insert into public.pi_cancel_reasons (pi_id, reason, cancelled_by)
    values (p_id, r, nm)
  on conflict (pi_id) do update set reason = excluded.reason, cancelled_by = excluded.cancelled_by, cancelled_at = now();
  update public.pis set cancelled_at = now(), cancelled_by = nm, cancel_reason = null where id = p_id;
end;
$$;
revoke all on function public.cancel_pi(uuid, text) from public;
grant execute on function public.cancel_pi(uuid, text) to authenticated;

-- safety net: a PI can never be flipped to cancelled without a stored reason, even by a direct update
create or replace function public.pis_require_cancel_reason()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.cancelled_at is not null and old.cancelled_at is null
     and not exists (select 1 from public.pi_cancel_reasons where pi_id = new.id) then
    raise exception 'A reason is required to cancel a PI';
  end if;
  return new;
end;
$$;
drop trigger if exists pis_require_cancel_reason on public.pis;
create trigger pis_require_cancel_reason before update on public.pis
  for each row execute function public.pis_require_cancel_reason();
