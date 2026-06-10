# Crisync

Crisync is a local-first, offline-capable emergency preparedness and response app for households. It supports emergency supply tracking, emergency contacts, SMS safety status broadcasts, location-specific alerts, preparedness guides, evacuation center lookup, AI preparedness scoring, and first-launch household risk onboarding.

The app is built as a Flutter application with Hive for local persistence, Supabase for cloud alert and evacuation-center sync, and a Supabase Edge Function for PAGASA-style alert ingestion. The mobile UI reads from local Hive caches wherever possible so core emergency information can still render when connectivity is weak or unavailable.

## 📥 Download Latest Release

**[Download v1.0.0-beta](https://github.com/xy-real/project_bihon/releases/tag/v1.0.0-beta)** — Get the latest beta APK for Android devices

## Features

- Emergency Supply Tracker with add/edit/delete, category tracking, expiration dates, photos, and local expiration reminders.
- Emergency Contacts with seeded Baybay emergency contacts, validation, grouping, and phone/SMS launch flows.
- SMS Safety Status / Safety Broadcast using the device's native SMS compose screen.
- Household Risk/Location Category Onboarding for `coastal`, `flood_prone`, `landslide_prone`, or `unknown`.
- Location-Specific Alerts backed by cached Supabase `global_alerts` rows and household risk matching.
- PAGASA Alert Integration through a Supabase Edge Function that ingests a public source into `global_alerts`.
- Preparedness Guides with bundled local guide images and Hive read/completion state.
- Evacuation Center Locator with list/map views, cached center data, marker status colors, and nearest sorting when location is available.
- AI Preparedness Score using local supplies and household risk data, with Gemini recalculation when online and cached results offline.
- Offline/local-first support through Hive boxes for supplies, contacts, household profile, alerts, evacuation centers, guides, and AI score.
- Swipeable main tab navigation for Dashboard, Alerts, Evacuation Centers, Supplies, and Contacts.

## Tech Stack

- Flutter 3.41.5 stable and Dart 3.11.3 were used in this checkout; `pubspec.yaml` requires Dart SDK `^3.8.0`.
- Hive / Hive Flutter with generated adapters from `hive_generator` and `build_runner`.
- Supabase via `supabase_flutter`.
- Supabase Edge Functions written for Deno.
- Supabase PostgreSQL migrations, RLS, `pg_cron`, `pg_net`, and Vault for alert scheduling.
- Flutter Map, `latlong2`, `geolocator`, `permission_handler`, and `flutter_map_tile_caching`.
- Gemini via `google_generative_ai`.
- Local notifications via `flutter_local_notifications`, `timezone`, and `flutter_timezone`.
- Device integrations through `url_launcher`, `image_picker`, `path_provider`, `video_player`, and platform manifests.
- UI libraries include `shadcn_ui`, `lucide_icons`, and Flutter Material/Cupertino.

## Project Structure

- `lib/main.dart` initializes Hive, repositories, Supabase, alert sync, evacuation center sync, local notifications, FMTC, and route wiring.
- `lib/features/ai_preparedness_score/` contains the Gemini prompt builder, score service, Hive model, repository, and detail UI.
- `lib/features/alerts/` contains cached alert models, sync services, threat classification, and the alerts UI.
- `lib/features/dashboard/` contains the main tab shell, dashboard, bottom navigation, and shared dashboard styling.
- `lib/features/emergency_contacts/` contains contacts, seeded Baybay contacts, validation, calling, and SMS safety status flows.
- `lib/features/evacuation_centers/` contains Supabase-to-Hive sync, location sorting, map/list UI, and offline map download UI.
- `lib/features/household/` and `lib/shared/models/household.dart` contain first-launch onboarding, profile settings, and household risk storage.
- `lib/features/preparedness_instruction/` contains offline preparedness guide models, seed data, category UI, and guide viewer.
- `lib/features/supply_tracker/` contains supply models, repository, widgets, and inventory payload support for AI scoring.
- `lib/shared/` contains common widgets, theme, Supabase service, notification service, and preparedness service helpers.
- `supabase/functions/fetch-pagasa-alerts/` contains the PAGASA ingestion Edge Function and Deno tests.
- `supabase/migrations/` contains `global_alerts` schema/RLS/upsert and alert-ingestion cron scheduling migrations.
- `supabase/.env.example` documents local Edge Function environment variable names.
- `assets/images/guides/` contains bundled preparedness guide images.
- `test/` contains unit and widget tests for AI scoring, alerts, dashboard, evacuation centers, household onboarding, preparedness guides, supply models, and utilities.
- `docs/pagasa_alert_integration.md` contains additional PAGASA integration notes.

## Prerequisites

- Flutter SDK. This checkout was verified with Flutter 3.41.5 stable / Dart 3.11.3; use Dart `^3.8.0` or newer compatible with the installed Flutter SDK.
- Android Studio, Android SDK, and an emulator or physical Android device.
- Xcode if targeting iOS/macOS.
- Supabase CLI for local development, migrations, Edge Functions, and secrets.
- A Supabase project for hosted alert ingestion and evacuation center sync.
- A Google Gemini API key if AI preparedness score recalculation is enabled.
- Deno for running Edge Function tests directly.
- Network access for Supabase sync, Gemini recalculation, OpenStreetMap tile loading, and Edge Function deployment.

## Flutter App Setup

Install Flutter dependencies:

```bash
flutter pub get
```

Generate Hive adapters after changing any Hive model annotations or fields:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The generated `.g.dart` adapter files are committed in this repository. Regenerate them only when the model definitions change, and review Hive `typeId` compatibility before shipping an update to existing users.

Analyze and test:

```bash
flutter analyze
flutter test
```

Run the app:

```bash
flutter run
```

Run with Gemini enabled:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Optionally override the Gemini model:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=GEMINI_MODEL=gemini-2.5-flash
```

## Environment Variables / Secrets

Do not commit real API keys, service-role keys, or local `.env` files. The repository includes `supabase/.env.example`; local files such as `supabase/.env.local` are ignored and should remain private.

Flutter app configuration:

- Gemini uses compile-time Dart defines:
  - `GEMINI_API_KEY`
  - `GEMINI_MODEL` optional, defaults to `gemini-2.5-flash`
- Supabase app access requires a Supabase project URL and anon/publishable key. In this checkout, `lib/main.dart` passes those values directly into `SupabaseService.initialize(...)`; it is not currently wired to `.env`.
- The Flutter app must use only the Supabase anon/publishable key. Never put a Supabase service-role key in Flutter code or Dart defines.

Supabase Edge Function environment:

- `SUPABASE_URL` or `PAGASA_SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` or `PAGASA_SUPABASE_SERVICE_ROLE_KEY`
- `PAGASA_ALERT_SOURCE_URL`
- `PAGASA_ENABLE_LOCAL_FIXTURE` optional local test flag

The Edge Function uses the service-role key server-side so it can upsert trusted rows into `global_alerts`. Store hosted values with Supabase secrets, not in source control.

## Supabase Setup

Install and authenticate the Supabase CLI:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Apply migrations:

```bash
supabase db push
```

Deploy the PAGASA ingestion function:

```bash
supabase functions deploy fetch-pagasa-alerts
```

Set required hosted function secrets:

```bash
supabase secrets set PAGASA_ALERT_SOURCE_URL="https://www.pagasa.dost.gov.ph/weather"
```

Hosted Supabase automatically supplies `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to Edge Functions. For local function serving, copy `supabase/.env.example` to a private local env file and fill in placeholder values from `supabase status`.

Required tables found in this checkout:

- `public.global_alerts`, created by migrations in `supabase/migrations/`.
- `public.evacuation_centers`, read by Flutter but not created by the current migrations.

`global_alerts` columns from migrations:

- `id`
- `source`
- `source_alert_id`
- `title`
- `severity`
- `advisory_type`
- `content`
- `region`
- `affected_areas`
- `risk_tags`
- `latitude`
- `longitude`
- `published_at`
- `updated_at`
- `expires_at`
- `is_active`
- `ingested_at`

`global_alerts` RLS and access from migrations:

- RLS is enabled.
- `anon` and `authenticated` are granted `select`.
- Policy `Allow public read active alerts` allows reads only where `is_active = true`.
- Edge Function writes are expected to use the server-side service-role key.

## PAGASA Alert Integration Setup

Architecture:

- Flutter does not call or scrape PAGASA directly.
- Supabase Edge Function `fetch-pagasa-alerts` fetches and parses a configured public source.
- The function normalizes alert data and upserts rows into `public.global_alerts`.
- Flutter syncs active `global_alerts` rows into Hive `alert_box`.
- The Alerts UI reads Hive and freshness/error state from `sync_state_box`.

Set the public source URL as a hosted Edge Function secret:

```bash
supabase secrets set PAGASA_ALERT_SOURCE_URL="https://www.pagasa.dost.gov.ph/weather"
```

Deploy the function:

```bash
supabase functions deploy fetch-pagasa-alerts
```

Invoke manually:

```bash
supabase functions invoke fetch-pagasa-alerts
```

The function supports `GET` and `POST`. To call the hosted function with curl, include your project anon/service invoke token as both `apikey` and bearer authorization:

```bash
curl -X POST "https://YOUR_PROJECT_REF.functions.supabase.co/fetch-pagasa-alerts" \
  -H "apikey: YOUR_FUNCTION_INVOKE_TOKEN" \
  -H "Authorization: Bearer YOUR_FUNCTION_INVOKE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"trigger":"manual"}'
```

Local fixture mode exists for development only. Enable it with `PAGASA_ENABLE_LOCAL_FIXTURE=true`, then call one of the fixture query modes:

```bash
curl -X POST "http://127.0.0.1:54321/functions/v1/fetch-pagasa-alerts?fixture=sample"
curl -X POST "http://127.0.0.1:54321/functions/v1/fetch-pagasa-alerts?fixture=html"
```

Manual alert sync test:

1. Ingest an active row into `global_alerts` by invoking the function, or insert a valid active row manually.
2. Open the app with network access.
3. Go to Alerts and refresh.
4. Confirm the alert appears.
5. Turn off internet.
6. Reopen Alerts and confirm the cached alert still appears with the offline/freshness state.

## Supabase Edge Function Scheduling

The migration `20260608034500_schedule_fetch_pagasa_alerts_cron.sql` adds private scheduling helpers for `fetch-pagasa-alerts`.

It uses:

- Supabase Cron / `pg_cron`
- `pg_net`
- Supabase Vault
- Function name `fetch-pagasa-alerts`
- Recommended schedule: every 15 minutes

Before enabling the hosted schedule, add Vault secrets in the Supabase SQL Editor:

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

Enable the cron job:

```sql
select private.schedule_fetch_pagasa_alerts_cron();
```

Check schedule status:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'fetch-pagasa-alerts-every-15-minutes';
```

Check recent runs:

```sql
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

Disable the cron job:

```sql
select private.unschedule_fetch_pagasa_alerts_cron();
```

If `pg_cron`, `pg_net`, or Vault are not enabled automatically by the migration, enable them in the Supabase Dashboard and rerun the scheduling function.

## Evacuation Center Setup

Flutter syncs evacuation centers from Supabase table `evacuation_centers` into Hive box `evac_center_box`. The UI reads the cached Hive data for both list and map rendering. If Supabase sync fails, existing cached centers are preserved.

The repository queries these columns:

- `center_id`
- `name`
- `latitude`
- `longitude`
- `capacity`
- `status`
- `updated_at`

Supported status values in the UI include:

- `Open`
- `Near Capacity`
- `Full`
- `Closed`
- unknown/custom values, displayed as provided after normalization

Minimum table setup if creating the table manually:

```sql
create table if not exists public.evacuation_centers (
  center_id text primary key,
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  capacity integer not null default 0,
  status text not null default 'Unknown',
  updated_at timestamptz not null default now()
);

alter table public.evacuation_centers enable row level security;

create policy "Allow public read evacuation centers"
on public.evacuation_centers
for select
to anon, authenticated
using (true);
```

No evacuation center migration or seed file exists in this checkout, so create the table and sample/production rows manually in Supabase until a migration is added.

Location behavior:

- If location permission is granted and GPS succeeds, centers are sorted nearest-first.
- If permission is denied, permanently denied, or GPS fails, the list still works and sorts alphabetically.
- Map markers use cached/local center data.
- Directions open externally through Google Maps URLs.

## Offline Map Setup

Packages present:

- `flutter_map`
- `flutter_map_tile_caching`
- `latlong2`

Startup initializes the FMTC ObjectBox backend. Settings includes an Offline Maps card at Profile Settings -> Offline Maps, and the download button creates an FMTC store named `BaybayCity`.

Current behavior in this checkout:

- The map view uses an OpenStreetMap `TileLayer` URL directly.
- The download button initializes the FMTC store and displays progress/success UI.
- A full tile-region download and FMTC-backed tile provider are not fully wired in the map view yet.

Expected offline behavior today:

- Evacuation center list and markers can still render from Hive `evac_center_box`.
- Map base tiles may not be available offline unless they are already cached by the underlying map/tile stack.
- Full offline map tile download/use should be treated as future setup until the tile download region and cached tile provider are implemented.

## AI Preparedness Score Setup

The AI score uses:

- Local supplies from `supply_box`
- Household risk/category data from `household_box`
- Gemini via `google_generative_ai`
- Cached result in Hive `ai_score_box` under key `latest_score`

The prompt builder sanitizes inventory and household risk data. It does not include names, phone numbers, emergency contacts, GPS coordinates, exact addresses, or household member names. Recalculation requires internet access and a Gemini API key; dashboard/detail UI can show the cached score offline.

Run with Gemini configured:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Optional model override:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=GEMINI_MODEL=gemini-2.5-flash
```

If `GEMINI_API_KEY` is missing, recalculation returns a configuration message and keeps any cached score visible.

## Hive Storage

Hive is initialized in `lib/main.dart` with these adapters and boxes:

- `SupplyItem`, `typeId: 0`, `supply_box`
- `Contact`, `typeId: 1`, `contact_box`
- `CachedAlert`, `typeId: 2`, `alert_box`
- `CachedEvacCenter`, `typeId: 3`, `evac_center_box`
- `Household`, `typeId: 4`, `household_box`
- `InstructionGuide`, committed generated adapter currently uses `typeId: 5`, `guide_box`
- `AIScoreCache`, `typeId: 6`, `ai_score_box`
- `AlertSyncState`, `typeId: 7`, `sync_state_box`
- Household onboarding completion is stored in `household_settings_box`

If Hive model fields or `typeId` values change, regenerate adapters and test migration behavior against existing local data. TypeId changes can make existing user boxes unreadable.

## Android Permissions

`android/app/src/main/AndroidManifest.xml` declares:

- `android.permission.INTERNET` for Supabase, Gemini, map tiles, and network checks.
- `android.permission.CAMERA` for supply item photos.
- `android.permission.READ_MEDIA_IMAGES` for Android 13+ image access.
- `android.permission.READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"` for older image access.
- `android.permission.ACCESS_FINE_LOCATION` for nearest evacuation center sorting and user map marker.
- `android.permission.ACCESS_COARSE_LOCATION` as a fallback location permission.

The manifest intentionally does not declare `SEND_SMS` or `READ_PHONE_STATE`. SMS safety status uses the native SMS compose intent through `url_launcher`.

The manifest includes Android package visibility queries for:

- `android.intent.action.PROCESS_TEXT`
- `android.intent.action.SENDTO` with `sms:` scheme

Local notification permission is requested at runtime by `flutter_local_notifications`.

## iOS Notes

`ios/Runner/Info.plist` currently includes:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

If iOS support is expanded for location-based evacuation sorting or SMS/phone URL launching, add the required iOS location usage descriptions and URL scheme configuration before release.

## Assets

Configured in `pubspec.yaml`:

- `assets/logo_opener.mp4`
- `assets/logo.png`
- `assets/images/guides/`

Preparedness guide images currently include typhoon, flood, earthquake, go-bag, window/building safety, and preparedness artwork under `assets/images/guides/`.

After changing `pubspec.yaml` or adding asset paths, run:

```bash
flutter pub get
```

Preparedness guide seed data is only inserted when `guide_box` is empty. Existing installs may keep old seeded image paths until the local guide box is cleared or a migration/reseed strategy is added.

## Running the App

Basic run:

```bash
flutter pub get
flutter run
```

Run with Gemini AI scoring:

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

For a fully configured run, also make sure:

- Supabase project URL and anon/publishable key are configured in the Flutter startup path.
- Supabase migrations have been pushed.
- `fetch-pagasa-alerts` is deployed and has `PAGASA_ALERT_SOURCE_URL`.
- `evacuation_centers` table exists and has readable rows.

## Testing

Run Flutter checks:

```bash
flutter analyze
flutter test
```

Run Edge Function tests:

```bash
cd supabase/functions/fetch-pagasa-alerts
deno test --allow-net --allow-env index_test.ts
```

Important manual tests:

- First-launch household risk onboarding and skip flow.
- Settings location category update.
- Supply add/edit/delete, image picking, and expiration reminder scheduling.
- Emergency contact add/update/delete, protected seeded-contact behavior, call launch, and SMS compose.
- Safety status recipient selection and SMS broadcast compose.
- AI score recalculation online, missing-key message, and cached offline display.
- Alert Edge Function ingestion, alert refresh, active-alert display, and offline cached alert display.
- Evacuation center Supabase sync, list fallback when offline, map markers, location permission denied, and external directions launch.
- Preparedness guide category browsing, image loading, page navigation, and completion/read state.
- Swipeable tab navigation, especially map interaction disabling page swipe while the map is being dragged.

## Troubleshooting

Hive adapter/typeId errors:

- Run `dart run build_runner build --delete-conflicting-outputs` after changing Hive model annotations.
- Confirm each model has a unique stable `typeId`.
- If local boxes were created with old incompatible adapters during development, clear app data or delete the affected Hive box.

Missing generated `.g.dart` files:

- Run `flutter pub get`.
- Run `dart run build_runner build --delete-conflicting-outputs`.
- Do not hand-edit generated adapter files.

Supabase connection errors:

- Confirm the Flutter app is using the correct Supabase project URL and anon/publishable key.
- Confirm the device/emulator has internet access.
- Confirm migrations were applied with `supabase db push`.
- Check RLS policies for readable `global_alerts` and `evacuation_centers`.

Edge Function not deployed:

- Run `supabase functions deploy fetch-pagasa-alerts`.
- Invoke it manually with `supabase functions invoke fetch-pagasa-alerts`.
- Check function logs in the Supabase Dashboard.

Missing `PAGASA_ALERT_SOURCE_URL`:

- Set it with `supabase secrets set PAGASA_ALERT_SOURCE_URL="https://www.pagasa.dost.gov.ph/weather"`.
- Redeploy or reinvoke the function after setting secrets.

Alerts not appearing:

- Confirm `global_alerts` contains rows where `is_active = true`.
- Confirm the row has required fields such as `title`, `severity`, `advisory_type`, `content`, `published_at`, and `updated_at`.
- Pull to refresh the Alerts screen.
- Check `sync_state_box` behavior by reproducing online and offline.

Evacuation centers not appearing:

- Confirm `evacuation_centers` exists; this checkout does not include its migration.
- Confirm rows include `center_id`, `name`, `latitude`, `longitude`, `capacity`, `status`, and `updated_at`.
- Confirm anon/authenticated users can select rows through RLS.
- Refresh the Evacuation Centers screen.

Gemini API key missing:

- Run with `--dart-define=GEMINI_API_KEY=your_key_here`.
- Confirm the device can reach `generativelanguage.googleapis.com`.
- Cached AI scores can still display offline, but recalculation requires internet.

Map or location permission denied:

- The center list should still display cached centers alphabetically.
- Grant location permission in Android app settings for nearest sorting and user marker.
- Map base tiles require network unless cached by the map stack.

Assets not loading:

- Confirm the asset is under a path declared in `pubspec.yaml`.
- Run `flutter pub get`.
- Restart the app, not only hot reload, after asset manifest changes.

SMS compose not opening:

- Test on a device or emulator with an SMS app.
- The app opens native compose and does not send SMS directly.
- Android intentionally avoids `SEND_SMS` and `READ_PHONE_STATE`.

## Known Limitations

- PAGASA official API access is not implemented in this checkout. The Edge Function currently uses a server-side public-source parser and includes a TODO to replace it with an approved official API parser when available.
- Public-page scraping/parsing can break if PAGASA changes HTML structure or content wording.
- No push notification fan-out for cloud alerts is implemented; alerts are synced/pulled into Hive.
- `public.evacuation_centers` is required by the Flutter app but has no migration or seed file in the current repository.
- Offline map support is only partially wired: FMTC is initialized and a store can be created from Settings, but the visible map still uses a direct OpenStreetMap tile URL and does not yet use a fully configured cached tile provider.
- AI score recalculation requires internet and a Gemini API key. Cached score display works offline.
- iOS location/SMS platform configuration is not fully documented in `Info.plist`; Android is the clearest supported mobile target in the current manifests.
- Release Android signing still uses the debug signing config in `android/app/build.gradle.kts`; configure production signing before publishing.

## Security Notes

- Never commit API keys, service-role keys, `.env.local`, or dashboard tokens.
- Never put the Supabase service-role key in Flutter code, Dart defines, or client-side assets.
- Flutter should use only the Supabase anon/publishable key.
- Use Supabase secrets for hosted Edge Function secrets.
- Use Supabase Vault for cron invoke URL/token values used by `pg_net`.
- Keep Gemini prompts free of PII. The current AI prompt should not include names, phone numbers, contacts, GPS coordinates, or exact addresses.
- Keep JWT verification enabled for hosted Edge Functions. Do not use local `--no-verify-jwt` behavior as production policy.

## Release History

| Version | Date Released |
|:--------|:--------------|
| v1.0.0-beta | 2026-06-10 |
| PB.010.004 | 2026-06-10 |
| PB.010.003 | 2026-05-23 |
| PB.010.002 | 2026-04-13 |
| PB.010.001 | 2026-04-05 |
| PB.010.000 | 2026-03-01 |

### v1.0.0-beta - Initial Release (Beta)

⚠️ **Beta Release** — This version contains known issues and ongoing testing. Not recommended for production use.

**Your Family's Emergency Preparedness Companion**

#### What's Included

**📦 Emergency Supply Tracker**
- Organize household supplies by category with expiration tracking
- Photo documentation for quick identification
- Local reminders before items expire

**🚨 Location-Specific Alerts**
- Real-time PAGASA typhoon and weather alerts synced to your app
- Alerts filtered by your household risk profile (coastal, flood-prone, landslide-prone)
- Works completely offline with cached data

**📍 Evacuation Center Locator**
- Browse nearby evacuation centers on an interactive map
- Offline maps with OpenStreetMap tiles
- Location-based sorting for quick access

**🤖 AI Preparedness Score**
- Powered by Google Gemini - get an instant assessment of your household's disaster readiness
- Smart recommendations based on your supplies and risk factors
- Results cached for offline access

**📞 Emergency Contacts**
- Pre-loaded with Baybay City emergency services
- Quick SMS broadcast to send your safety status to contacts
- Easy contact management

**📚 Preparedness Guides**
- Offline-first disaster preparedness guides bundled with local images
- No internet required to access critical information

**✈️ Easy Navigation**
- Swipeable tab interface for quick access to Dashboard, Alerts, Evacuation Centers, Supplies, and Contacts
- Intuitive household onboarding on first launch

#### Key Features

✅ **Offline-First Design** — All critical data synced and cached locally  
✅ **Designed for Philippines** — PAGASA integration + Baybay City emergency contacts  
✅ **Supports Weak Connectivity** — Works with slow or no internet  
✅ **AI-Powered Insights** — Gemini-based household preparedness assessment  
✅ **Emergency-Ready** — SMS broadcast capability for family safety alerts  

#### Installation & Setup

1. Go to [Releases](https://github.com/xy-real/project_bihon/releases)
2. Download the APK file
3. Install on your Android device
4. Complete the household risk profile setup on first launch

#### Requirements

- **Android 8.0 or higher**
- **Internet connection** (recommended for alerts sync; app functions offline)
- **Google Gemini API key** (for preparedness scoring feature)

#### Known Limitations

- Android-only (iOS coming soon)
- Gemini API key must be provided at build time
- Official PAGASA REST API endpoints not yet available; currently uses public-source parser
- Offline map support is partially wired; full cached tile provider integration pending
- Release Android signing currently uses debug signing config; production signing required before publishing

#### Getting Started

1. Install and open Crisync
2. Set your household risk profile during onboarding
3. Add your emergency supplies to the tracker
4. Review local preparedness guides
5. Check your household's preparedness score
6. Save emergency contacts
7. Enable push notifications for timely alerts

**Stay safe and prepared! 🛡️**

### PB.010.004 Release Notes

#### Implemented Features

- *AI Preparedness Score (Gemini Integration)*
  - Calculates a localized household readiness score (0-100) and generates personalized "Go-Bag" recommendations.
  - Aggregates local unexpired supply inventory and household risk data dynamically.
  - Enforces strict privacy sanitization; strips all Personally Identifiable Information (PII) before interacting with the Gemini API.
  - Caches the AI's response and custom advice in Hive, allowing the dashboard to render the last known score instantly during network blackouts.
- *Preparedness Instruction Module*
  - Provides categorized, step-by-step interactive survival guides (e.g., Typhoons, Floods, Earthquakes, First Aid).
  - Operates 100% offline using highly-compressed bundled asset images and predefined text.
  - Tracks reading/completion state via Hive.
- *PAGASA Cloud-to-Local Ingestion Pipeline*
  - Deployed Supabase Edge Function (fetch-pagasa-alerts) to securely fetch, parse, and normalize upstream weather data.
  - Configured Supabase pg_cron to automate data fetching every 15 minutes.
  - Finalized the offline-first Flutter sync service to pull active cloud rows directly into the local Hive alert_box.

#### App Integration

- Integrated the google_generative_ai package and wired the GEMINI_API_KEY environment variable.
- Added the AI Preparedness dashboard widget and detailed recalculation screen with offline-blocking safety checks.
- Wired the Preparedness Instruction category grid and swipeable page viewers into the main application routing.
- Established the single-source-of-truth UI contract: the app now reads alerts exclusively from the local Hive cache.

#### Quality and Stability Updates

- Verified AI prompt sanitization to ensure zero data leakage of exact GPS coordinates, names, or phone numbers.
- Added graceful offline fallback for the AI Score screen: it successfully displays the calculatedAt timestamp and cached data when Wi-Fi/Data is disabled.
- Ensured local guide images load instantly in Airplane Mode without causing application UI thread stuttering.
- Tested Supabase Edge Function timeout and retry logic to prevent mobile app crashes during upstream PAGASA server degradation.

#### Known Issues

- Official PAGASA REST API endpoints are not yet available; the Edge Function currently relies on a public-source parser which may require updates if upstream HTML structures change.
- Preparedness guide seed data is currently inserted only when the Hive box is empty; future updates to guide text may require a migration script.

### PB.010.003 Release Notes

#### Implemented Features

- Evacuation Center Locator
  - Added a new evacuation center locator with List View and Map View
  - Shows nearest centers using GPS-based distance sorting
  - Displays center name, distance, capacity, and status in color-coded cards
- Offline-Capable Map Experience
  - Added offline-capable map rendering with pre-cached Baybay City tiles
  - Added marker colors by center status (Open, Near Capacity, Full/Closed)
  - Added center detail bottom sheet when markers are tapped
- Data Sync and Local Cache
  - Added evacuation center local caching using Hive
  - Added Supabase-to-Hive sync flow for evacuation centers
  - Kept UI reads local-only from cache for offline reliability

#### App Integration

- Added a centralized Supabase service initialized at app startup
- Added evacuation center access from Home page AppBar
- Added Offline Maps download action in Profile Settings
- Added offline connectivity banner for map/list awareness
- Added Android location and internet permissions for locator and map features

#### Quality and Stability Updates

- Added graceful fallback to alphabetical sorting when location permission is denied or GPS is unavailable
- Preserved crash-safe behavior for offline mode and missing location access
- Verified manual scenarios for status variants and nearest-center behavior

#### Known Issues

- None.

### PB.010.002 Release Notes

#### Implemented Features

- Location-Specific Alert Prioritization
  - Prioritizes warnings based on the household risk profile
  - Highlights higher-risk alerts clearly for faster decision-making
- Household Profile Experience
  - Added onboarding and settings options for updating household risk classification
- Improved Alerts Display
  - Added direct-threat and general-advisory card variants
  - Improved alert ordering so critical items appear first
  - Added graceful empty-state behavior when no alerts are available

#### App Integration

- Added local profile and cached-alert support in the main app flow
- Preserved offline-first behavior with no network requirement in alert rendering
- Kept fallback-safe behavior for missing profile or tag data

#### Quality and Stability Updates

- Added unit, widget, and integration test coverage for prioritization and fallback scenarios
- Verified stable behavior during profile changes and offline usage
- No compilation errors reported

#### Known Issues

- None.

### PB.010.001 Release Notes

#### Implemented Features

- Emergency Supply Tracker
  - Add, edit, and remove supply items
  - Track quantity, category, and expiration date
  - Use either card view or table view based on preference
  - Get local reminders for items nearing expiration
- Emergency Contacts Manager
  - Add and update emergency contacts with validation
  - View contacts grouped by type for faster access
  - Use prefilled Baybay emergency contacts with safety protection rules
  - Start direct calls from the app using the phone dialer
- SMS Safety Status
  - Select recipients from Family and Barangay Official groups
  - Choose from predefined safety status templates
  - Open native SMS compose screen with recipients and message prefilled
  - Show clear feedback when sending cannot proceed

#### App Integration

- Integrated Contacts and Safety Status into the main app flow
- Preserved existing splash and home experience
- Added Android SMS intent query support required for compose flow
- Kept release-safe permission policy (no direct SMS or phone-state permissions)

#### Quality and Stability Updates

- Verified offline persistence and seeded-contact consistency
- Verified validation, deduplication, and protected-contact behavior
- Stabilized contact modal behavior and improved interaction reliability
- Refined contact list spacing and action visibility for better usability

#### Known Issues

- SMS sending depends on the device's installed SMS app, and behavior may vary by device brand.
- The app currently opens the SMS compose screen, but it does not track final delivery status.
- PAGASA Global Alerts and Evacuation Centers sync are documented and planned, but not part of this release.
- Main navigation in this branch is route-based from the home app bar while bottom navigation is handled separately.

### PB.010.000 Release Notes

- Setup repository README with tracking table and documentation
- Initialize new Flutter project

### Important Links

- Design Specs: https://github.com/xy-real/bihon-docportal
