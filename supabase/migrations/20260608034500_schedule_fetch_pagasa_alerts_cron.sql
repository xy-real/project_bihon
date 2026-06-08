-- Schedule the fetch-pagasa-alerts Edge Function every 15 minutes.
--
-- This migration intentionally does not store any real tokens. Before enabling
-- the hosted schedule, add these Vault secrets in Supabase Dashboard or SQL:
--
--   select vault.create_secret(
--     'https://<project-ref>.supabase.co',
--     'fetch_pagasa_alerts_project_url',
--     'Project URL used by the PAGASA alert cron job'
--   );
--
--   select vault.create_secret(
--     '<service-role-or-dedicated-function-invoke-token>',
--     'fetch_pagasa_alerts_function_token',
--     'Bearer token used by the PAGASA alert cron job'
--   );
--
-- Then run:
--
--   select private.schedule_fetch_pagasa_alerts_cron();
--
-- Production note: keep JWT verification enabled for the Edge Function. The
-- local-only --no-verify-jwt serve flag must not be used as production policy.

create schema if not exists private;

revoke all on schema private from anon, authenticated;

do $$
begin
  create extension if not exists pg_cron with schema extensions;
exception
  when others then
    raise notice 'pg_cron extension was not enabled by migration. Enable Supabase Cron/pg_cron in the Dashboard if needed. Error: %', sqlerrm;
end
$$;

do $$
begin
  create extension if not exists pg_net with schema extensions;
exception
  when others then
    raise notice 'pg_net extension was not enabled by migration. Enable pg_net in the Dashboard if needed. Error: %', sqlerrm;
end
$$;

do $$
begin
  create schema if not exists vault;
  create extension if not exists supabase_vault with schema vault;
exception
  when others then
    raise notice 'Supabase Vault was not enabled by migration. Enable Vault in the Dashboard if needed. Error: %', sqlerrm;
end
$$;

create or replace function private.schedule_fetch_pagasa_alerts_cron()
returns text
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  job_name constant text := 'fetch-pagasa-alerts-every-15-minutes';
  project_url_secret constant text := 'fetch_pagasa_alerts_project_url';
  function_token_secret constant text := 'fetch_pagasa_alerts_function_token';
begin
  if to_regnamespace('cron') is null then
    return 'pg_cron is not available. Enable Supabase Cron/pg_cron, then rerun this function.';
  end if;

  if to_regclass('cron.job') is null then
    return 'cron.job is not available. Enable Supabase Cron/pg_cron, then rerun this function.';
  end if;

  if to_regnamespace('net') is null then
    return 'pg_net is not available. Enable pg_net, then rerun this function.';
  end if;

  if to_regclass('vault.decrypted_secrets') is null then
    return 'Supabase Vault is not available. Enable Vault, add secrets, then rerun this function.';
  end if;

  if not exists (
    select 1
    from vault.decrypted_secrets
    where name = project_url_secret
  ) then
    return 'Missing Vault secret: fetch_pagasa_alerts_project_url';
  end if;

  if not exists (
    select 1
    from vault.decrypted_secrets
    where name = function_token_secret
  ) then
    return 'Missing Vault secret: fetch_pagasa_alerts_function_token';
  end if;

  if exists (
    select 1
    from cron.job
    where jobname = job_name
  ) then
    perform cron.unschedule(job_name);
  end if;

  perform cron.schedule(
    job_name,
    '*/15 * * * *',
    $cron$
      select
        net.http_post(
          url := (
            select decrypted_secret
            from vault.decrypted_secrets
            where name = 'fetch_pagasa_alerts_project_url'
          ) || '/functions/v1/fetch-pagasa-alerts',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'apikey', (
              select decrypted_secret
              from vault.decrypted_secrets
              where name = 'fetch_pagasa_alerts_function_token'
            ),
            'Authorization', 'Bearer ' || (
              select decrypted_secret
              from vault.decrypted_secrets
              where name = 'fetch_pagasa_alerts_function_token'
            )
          ),
          body := jsonb_build_object(
            'trigger', 'pg_cron',
            'job', 'fetch-pagasa-alerts-every-15-minutes',
            'scheduled_at', now()
          ),
          timeout_milliseconds := 10000
        ) as request_id;
    $cron$
  );

  return 'Scheduled fetch-pagasa-alerts-every-15-minutes every 15 minutes.';
end;
$$;

create or replace function private.unschedule_fetch_pagasa_alerts_cron()
returns text
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  job_name constant text := 'fetch-pagasa-alerts-every-15-minutes';
begin
  if to_regnamespace('cron') is null then
    return 'pg_cron is not available; no cron job was changed.';
  end if;

  if to_regclass('cron.job') is null then
    return 'cron.job is not available; no cron job was changed.';
  end if;

  if exists (
    select 1
    from cron.job
    where jobname = job_name
  ) then
    perform cron.unschedule(job_name);
    return 'Unscheduled fetch-pagasa-alerts-every-15-minutes.';
  end if;

  return 'Cron job fetch-pagasa-alerts-every-15-minutes was not found.';
end;
$$;

revoke all on function private.schedule_fetch_pagasa_alerts_cron() from public, anon, authenticated;
revoke all on function private.unschedule_fetch_pagasa_alerts_cron() from public, anon, authenticated;

do $$
declare
  result text;
begin
  select private.schedule_fetch_pagasa_alerts_cron() into result;
  raise notice '%', result;
end
$$;
