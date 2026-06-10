-- Create the cloud alert cache populated by trusted Edge Function ingestion.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.global_alerts (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  source_alert_id text,
  title text not null,
  severity text not null,
  advisory_type text not null,
  content text not null,
  region text,
  affected_areas text[] default '{}'::text[],
  risk_tags text[] not null default '{}'::text[],
  latitude double precision,
  longitude double precision,
  published_at timestamptz not null,
  updated_at timestamptz not null default now(),
  expires_at timestamptz,
  is_active boolean not null default true,
  ingested_at timestamptz not null default now()
);
