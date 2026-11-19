-- ============================================================
-- Sunshine PI Desk — per-PI "Payment terms"
-- Run ONCE in Supabase (SQL Editor -> New query -> paste -> Run).
-- Safe to run more than once. Existing PIs are untouched (payment terms stay empty).
-- ============================================================
alter table public.pis
  add column if not exists payment_terms text;
