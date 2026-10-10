-- ============================================================
-- Sunshine PI Desk — add the "Brand name" field to PIs
-- Run this ONCE in Supabase (SQL Editor -> New query -> paste -> Run)
-- BEFORE the updated index.html / app.js / preview.html go live.
-- Safe to run more than once. Existing PIs are untouched (brand stays empty).
-- ============================================================

alter table public.pis
  add column if not exists brand_name text;
