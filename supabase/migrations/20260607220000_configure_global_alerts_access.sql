-- Configure the existing global_alerts table for offline alert synchronization.
-- Alert ingestion writes are performed by trusted service-role Edge Functions.

create index if not exists global_alerts_active_published_idx
on public.global_alerts (is_active, published_at desc);

create index if not exists global_alerts_risk_tags_idx
on public.global_alerts using gin (risk_tags);

create unique index if not exists global_alerts_source_alert_unique_idx
on public.global_alerts (source, source_alert_id)
where source_alert_id is not null;

alter table public.global_alerts enable row level security;

grant select on table public.global_alerts to anon, authenticated;

drop policy if exists "Allow public read active alerts"
on public.global_alerts;

create policy "Allow public read active alerts"
on public.global_alerts
for select
to anon, authenticated
using (is_active = true);
