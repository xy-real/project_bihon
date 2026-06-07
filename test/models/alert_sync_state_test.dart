import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('alert_sync_state_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AlertSyncStateAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('stores and restores alert sync metadata', () async {
    final successfulAt = DateTime.utc(2026, 6, 7, 12);
    final attemptedAt = DateTime.utc(2026, 6, 7, 12, 5);
    final state = AlertSyncState(
      lastSuccessfulSyncAt: successfulAt,
      lastAttemptedSyncAt: attemptedAt,
      lastError: 'Temporary failure',
      lastSyncedCount: 4,
    );

    final box = await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);
    await box.put('latest', state);
    await box.close();

    final reopenedBox =
        await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);
    final stored = reopenedBox.get('latest');

    expect(AlertSyncStateAdapter().typeId, 7);
    expect(stored, isNotNull);
    expect(stored!.lastSuccessfulSyncAt, successfulAt);
    expect(stored.lastAttemptedSyncAt, attemptedAt);
    expect(stored.lastError, 'Temporary failure');
    expect(stored.lastSyncedCount, 4);
  });
}
