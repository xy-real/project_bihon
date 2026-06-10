import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_service.dart';

void main() {
  late Directory hiveDirectory;
  late Box<CachedAlert> alertBox;
  late Box<AlertSyncState> syncStateBox;
  late List<Map<String, dynamic>> remoteRows;
  final now = DateTime.utc(2026, 6, 7, 12);

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('alert_sync_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CachedAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AlertSyncStateAdapter());
    }

    alertBox = await Hive.openBox<CachedAlert>(CachedAlert.boxName);
    syncStateBox =
        await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);
    remoteRows = [];
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  AlertSyncService createService({
    AlertRowsFetcher? rowsFetcher,
  }) {
    return AlertSyncService(
      rowsFetcher: rowsFetcher ?? () async => remoteRows,
      alertBox: alertBox,
      syncStateBox: syncStateBox,
      now: () => now,
    );
  }

  Map<String, dynamic> validRow({
    String id = 'alert-1',
    String title = 'Heavy Rainfall Warning',
    String publishedAt = '2026-06-07T10:00:00Z',
    List<String> riskTags = const [' Flood Prone ', 'flood-prone'],
  }) {
    return {
      'id': id,
      'source': 'PAGASA',
      'source_alert_id': 'pagasa-$id',
      'title': title,
      'severity': 'High',
      'advisory_type': 'rainfall',
      'content': 'Heavy rainfall is expected.',
      'region': 'Eastern Visayas',
      'affected_areas': [' Baybay City ', 'Ormoc City'],
      'risk_tags': riskTags,
      'latitude': '10.678',
      'longitude': 124.8,
      'published_at': publishedAt,
      'updated_at': '2026-06-07T10:30:00Z',
      'expires_at': '2026-06-08T10:00:00Z',
      'is_active': true,
      'ingested_at': '2026-06-07T10:31:00Z',
    };
  }

  test('maps Supabase fields, normalizes values, and caches by alert id',
      () async {
    remoteRows = [validRow()];

    final succeeded = await createService().syncAlerts();
    final alert = alertBox.get('alert-1');
    final state = syncStateBox.get(AlertSyncService.syncStateKey);

    expect(succeeded, isTrue);
    expect(alert, isNotNull);
    expect(alert!.advisoryType, 'rainfall');
    expect(alert.riskTags, ['flood_prone']);
    expect(alert.affectedAreas, ['Baybay City', 'Ormoc City']);
    expect(alert.latitude, 10.678);
    expect(alert.longitude, 124.8);
    expect(alert.publishedAt, DateTime.utc(2026, 6, 7, 10));
    expect(state?.lastAttemptedSyncAt, now);
    expect(state?.lastSuccessfulSyncAt, now);
    expect(state?.lastError, isNull);
    expect(state?.lastSyncedCount, 1);
  });

  test('normalizes comma-separated risk tags from a Supabase row', () {
    expect(
      AlertSyncService.normalizeRiskTags(
        ' Flood Prone, flood-prone, Coastal Warning ',
      ),
      ['flood_prone', 'coastal_warning'],
    );
  });

  test('normalizes JSON and Postgres-style affected areas values', () {
    expect(
      AlertSyncService.normalizeAffectedAreas(
        '[" Baybay City ", "Leyte", "Baybay City"]',
      ),
      ['Baybay City', 'Leyte'],
    );
    expect(
      AlertSyncService.normalizeAffectedAreas('{ Baybay City, Leyte }'),
      ['Baybay City', 'Leyte'],
    );
  });

  test('skips corrupt rows while caching valid rows', () async {
    remoteRows = [
      validRow(),
      {
        'id': 'broken-alert',
        'source': 'PAGASA',
        'title': 'Broken',
      },
    ];

    final succeeded = await createService().syncAlerts();
    final state = syncStateBox.get(AlertSyncService.syncStateKey);

    expect(succeeded, isTrue);
    expect(alertBox.keys, ['alert-1']);
    expect(state?.lastSyncedCount, 1);
    expect(state?.lastError, isNull);
  });

  test('upserts a repeated alert id without creating duplicates', () async {
    remoteRows = [validRow()];
    final service = createService();
    expect(await service.syncAlerts(), isTrue);

    remoteRows = [validRow(title: 'Updated Rainfall Warning')];
    expect(await service.syncAlerts(), isTrue);

    expect(alertBox.length, 1);
    expect(alertBox.get('alert-1')?.title, 'Updated Rainfall Warning');
  });

  test('network failure preserves cache and records sync error', () async {
    remoteRows = [validRow()];
    expect(await createService().syncAlerts(), isTrue);

    final failingService = createService(
      rowsFetcher: () async => throw Exception('Supabase unavailable'),
    );
    final succeeded = await failingService.syncAlerts();
    final state = syncStateBox.get(AlertSyncService.syncStateKey);

    expect(succeeded, isFalse);
    expect(alertBox.get('alert-1'), isNotNull);
    expect(state?.lastSuccessfulSyncAt, now);
    expect(state?.lastAttemptedSyncAt, now);
    expect(state?.lastError, contains('Supabase unavailable'));
    expect(state?.lastSyncedCount, 1);
  });

  test('removes cached alerts older than the 30 day retention window',
      () async {
    await alertBox.put(
      'old-alert',
      CachedAlert(
        id: 'old-alert',
        title: 'Old Alert',
        severity: 'Low',
        source: 'PAGASA',
        advisoryType: 'rainfall',
        content: 'Old content',
        publishedAt: now.subtract(const Duration(days: 31)),
        updatedAt: now.subtract(const Duration(days: 31)),
        isActive: true,
      ),
    );

    expect(await createService().syncAlerts(), isTrue);

    expect(alertBox.containsKey('old-alert'), isFalse);
  });
}
