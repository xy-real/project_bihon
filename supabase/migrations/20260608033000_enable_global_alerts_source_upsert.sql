-- Allow Edge Function upserts to target (source, source_alert_id).
-- PostgreSQL unique indexes still permit multiple null source_alert_id values.

drop index if exists public.global_alerts_source_alert_unique_idx;

create unique index global_alerts_source_alert_unique_idx
on public.global_alerts (source, source_alert_id);
