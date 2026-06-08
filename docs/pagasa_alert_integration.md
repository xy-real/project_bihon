# PAGASA Alert Integration

This project uses a server-side Supabase ingestion layer for PAGASA-style alert
data. The Flutter app does not scrape PAGASA pages and does not write alert rows
directly. Flutter reads active alerts from Hive after the sync service copies
rows from Supabase into the local cache.

## Supabase Requirements

Required table:

- `public.global_alerts`

Required Edge Function:

- `fetch-pagasa-alerts`

Required hosted Edge Function secret:

- `PAGASA_ALERT_SOURCE_URL`

Do not commit real secret values. Do not put the service role key in Flutter.

## Deploy

Push database migrations:

```powershell
supabase db push
```

Deploy the function:

```powershell
supabase functions deploy fetch-pagasa-alerts
```

Set the public source URL as a Supabase function secret:

```powershell
supabase secrets set PAGASA_ALERT_SOURCE_URL="https://example-public-alert-page"
```

## Schedule

The schedule uses Supabase Cron (`pg_cron`), `pg_net`, and Vault. Add these
Vault secrets in the Supabase SQL Editor:

```sql
select vault.create_secret(
  'https://<project-ref>.supabase.co',
  'fetch_pagasa_alerts_project_url',
  'Project URL used by the PAGASA alert cron job'
);

select vault.create_secret(
  '<service-role-or-dedicated-function-invoke-token>',
  'fetch_pagasa_alerts_function_token',
  'Bearer token used by the PAGASA alert cron job'
);
```

Then enable the job:

```sql
select private.schedule_fetch_pagasa_alerts_cron();
```

Verify:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'fetch-pagasa-alerts-every-15-minutes';

select jobid, job_pid, status, return_message, start_time, end_time
from cron.job_run_details
where jobid = (
  select jobid
  from cron.job
  where jobname = 'fetch-pagasa-alerts-every-15-minutes'
)
order by start_time desc
limit 10;
```

Disable if needed:

```sql
select private.unschedule_fetch_pagasa_alerts_cron();
```

## Flutter Sync Behavior

Flutter syncs from `public.global_alerts` into Hive `alert_box` through the
alert sync service. The Alerts UI reads Hive only and uses `sync_state_box` for
freshness and error state.

Sync triggers:

- app launch
- Alerts screen manual refresh
- app resume when due
- foreground interval, at most once every 15 minutes

Manual refresh bypasses the 15-minute rate limit because it is explicitly
user-triggered.

## Offline Behavior

If the device is offline, the coordinator skips Supabase sync and keeps existing
Hive alerts. The UI continues to render cached alerts and shows the freshness or
offline banner from `sync_state_box`.

## Parser Limitations

This is not an official PAGASA API integration yet. It is a server-side
public-source ingestion layer that fetches and parses one configured public
page. The parser extracts simple readable text, infers advisory type, severity,
risk tags, and Baybay/Eastern Visayas relevance from keywords. It can later be
replaced with an approved official API parser without changing Flutter's local
Hive render path.
