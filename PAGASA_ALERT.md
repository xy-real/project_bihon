# Feature Deep-Dive 3 (v2): PAGASA Alert Integration (Cloud-to-Local Broadcast)

## 1. Feature Overview
The PAGASA Alert Integration (Process 4.0) retrieves and displays typhoon, rainfall, and hazard alerts relevant to Baybay City and nearby risk zones.

Core objective:
- The app must feel instant and reliable offline.

Core architecture rule:
- The mobile app does not call PAGASA/NDRRMC endpoints directly.
- A Supabase Edge Function ingests upstream feeds into Supabase.
- Flutter syncs Supabase data into a local Hive cache.
- UI reads from Hive only.

## 2. Architecture and Data Flow
1. Edge Function fetches upstream alerts every 15 minutes (cron) and normalizes records.
2. Edge Function upserts alerts into `global_alerts` and marks stale items as inactive/expired.
3. Flutter sync service runs on app start, connectivity regain, and foreground interval.
4. Sync service upserts into Hive `alert_box` and updates `sync_state_box` metadata.
5. Alerts UI renders from Hive listables and shows freshness state.

## 3. Cloud Schema (Supabase PostgreSQL)

Table: `global_alerts`
- `id` (UUID, PK)
- `source` (TEXT) - `PAGASA`, `NDRRMC`, etc.
- `source_alert_id` (TEXT, nullable) - upstream identifier
- `title` (TEXT, required)
- `severity` (TEXT, required) - `High`, `Medium`, `Low`
- `advisory_type` (TEXT, required) - typhoon, rainfall, flood, etc.
- `content` (TEXT, required)
- `region` (TEXT, nullable) - for regional filtering
- `affected_areas` (TEXT[], nullable)
- `risk_tags` (TEXT[], default `{}`) - `flood_prone`, `coastal`, `landslide_prone`
- `latitude` (DOUBLE PRECISION, nullable)
- `longitude` (DOUBLE PRECISION, nullable)
- `published_at` (TIMESTAMPTZ, required)
- `updated_at` (TIMESTAMPTZ, required, default now())
- `expires_at` (TIMESTAMPTZ, nullable)
- `is_active` (BOOLEAN, required, default true)
- `ingested_at` (TIMESTAMPTZ, required, default now())

Recommended indexes:
- `(is_active, published_at desc)`
- GIN index on `risk_tags`
- `(source, source_alert_id)` unique when `source_alert_id` exists

## 4. Local Cache Schema (Hive)

### A. `CachedAlert` (`typeId: 2`)
```dart
import 'package:hive/hive.dart';

part 'cached_alert.g.dart';

@HiveType(typeId: 2)
class CachedAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String severity;

  @HiveField(3)
  final String source;

  @HiveField(4)
  final String advisoryType;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final DateTime publishedAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final DateTime? expiresAt;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final List<String> riskTags;

  @HiveField(11)
  final String? region;

  @HiveField(12)
  final List<String> affectedAreas;

  @HiveField(13)
  final double? latitude;

  @HiveField(14)
  final double? longitude;

  const CachedAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.source,
    required this.advisoryType,
    required this.content,
    required this.publishedAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.isActive,
    required this.riskTags,
    required this.region,
    required this.affectedAreas,
    required this.latitude,
    required this.longitude,
  });
}
```

### B. `AlertSyncState` (`typeId: 3`)
```dart
import 'package:hive/hive.dart';

part 'alert_sync_state.g.dart';

@HiveType(typeId: 3)
class AlertSyncState extends HiveObject {
  @HiveField(0)
  final DateTime? lastSuccessfulSyncAt;

  @HiveField(1)
  final DateTime? lastAttemptedSyncAt;

  @HiveField(2)
  final String? lastError;

  @HiveField(3)
  final int lastSyncedCount;

  const AlertSyncState({
    required this.lastSuccessfulSyncAt,
    required this.lastAttemptedSyncAt,
    required this.lastError,
    required this.lastSyncedCount,
  });
}
```

## 5. Implementation Phases

### Phase 1: Edge Function Ingestion (Supabase)
Location: `supabase/functions/fetch-pagasa-alerts/`

1. Fetch upstream feeds (PAGASA/NDRRMC) with timeout and retries.
2. Normalize payload into a strict internal DTO.
3. Map to Baybay/Eastern Visayas relevance.
4. Upsert into `global_alerts` by stable key:
   - use `source + source_alert_id` when available
   - fallback to deterministic hash key when upstream ID missing
5. Mark stale alerts inactive when expired or absent from active source set.
6. Emit structured logs (`ingest_started`, `ingest_success`, `ingest_failed`).

Reliability requirements:
- timeout: 10s per upstream call
- retries: max 3 with exponential backoff
- partial source failure must not block saving successful sources

Security requirements:
- function invocation restricted to service role / cron path
- no public write path to `global_alerts`
- sanitize all external text payloads before insert

### Phase 2: Supabase Cron
1. Configure `pg_cron` every 15 minutes.
2. Add alerting for repeated failures (for example 3 consecutive failed runs).

### Phase 3: Flutter Sync Service (Offline-First)
1. Add connectivity trigger with `connectivity_plus`.
2. Add sync triggers:
   - app launch
   - connectivity regained
   - periodic foreground interval (max once per 15 minutes)
   - optional manual pull-to-refresh
3. Pull active and recently updated rows from Supabase.
4. Upsert into Hive `alert_box` by `id`.
5. Process deactivations/expiries:
   - either remove inactive items or keep with `isActive=false` (choose one policy and keep consistent)
6. Save sync metadata into `sync_state_box`.

Data retention policy:
- keep max 30 days locally
- purge records older than retention window unless pinned by product requirements

### Phase 4: UI Data Source Contract
1. Alerts screens read from Hive only (`ValueListenableBuilder`).
2. No direct await on Supabase in UI build paths.
3. Show freshness banner from `AlertSyncState`:
   - "Updated X minutes ago"
   - "Offline: showing cached alerts"
   - "No cached alerts yet"

### Phase 5: Location-Specific Warning Highlighting (UR4a)
1. Read household `risk_classification` from local profile.
2. Match against `CachedAlert.riskTags`.
3. Visually elevate matching high-priority alerts.
4. Include fallback when household profile is missing.

### Phase 6: Typhoon Tracking Map (UR4b)
1. Use `flutter_map` with cached tile strategy.
2. Cache map tiles and last known storm coordinates.
3. Offline behavior:
   - if cached tiles exist, render map
   - else show fallback card with coordinates and timestamp
4. Define tile cache limit and eviction policy.

## 6. Failure Handling Rules
1. Upstream API timeout/failure:
   - keep last local cache
   - update sync state error
   - do not crash UI
2. Supabase unavailable:
   - skip cloud pull
   - show stale-data banner
3. Corrupt alert record:
   - skip bad record
   - log parse error with source identifier

## 7. Acceptance Criteria (Measurable)
1. Edge Function inserts/upserts valid alerts into `global_alerts` every 15 minutes.
2. Mobile sync writes Supabase alerts to Hive and records `lastSuccessfulSyncAt`.
3. Alerts screen renders from Hive in under 300 ms after open (warm start target).
4. App remains stable with Wi-Fi/data off; alerts screen still renders cached content.
5. Freshness banner appears when cache age exceeds 30 minutes.
6. Location-specific risk matching highlights relevant alerts from `risk_tags`.
7. SMS/contacts features remain unaffected by alert sync changes.
8. No dangerous SMS/phone permissions introduced by this feature.

## 8. QA Checklist
1. Online first launch: sync completes and list populates.
2. Offline reopen: cached alerts still render.
3. Relauch repeatedly: no duplicate local alerts by `id`.
4. Expired cloud alert: local inactive/removal behavior follows chosen policy.
5. Risk-tag highlight appears for matching household risk class.
6. Map view:
   - online fetch and cache works
   - offline fallback behavior works
7. `flutter analyze` passes with no new relevant warnings/errors.

## 9. Non-Goals (Current Scope)
1. Direct mobile polling of PAGASA/NDRRMC from Flutter.
2. Push notification fan-out of alerts.
3. Crowd-sourced community reporting.
