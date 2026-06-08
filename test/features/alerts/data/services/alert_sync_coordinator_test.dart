import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_coordinator.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_service.dart';

void main() {
  late Directory hiveDirectory;
  late Box<AlertSyncState> syncStateBox;
  late DateTime now;
  late int syncCount;
  late _FakeAlertSyncConnectivity connectivity;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'alert_sync_coordinator_',
    );
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AlertSyncStateAdapter());
    }
    syncStateBox = await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);
    now = DateTime.utc(2026, 6, 8, 12);
    syncCount = 0;
    connectivity = _FakeAlertSyncConnectivity(isOnline: true);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  AlertSyncCoordinator createCoordinator() {
    return AlertSyncCoordinator(
      syncRunner: () async {
        syncCount += 1;
        return true;
      },
      connectivity: connectivity,
      syncStateBox: syncStateBox,
      now: () => now,
    );
  }

  Future<void> saveState({
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastAttemptedSyncAt,
    String? lastError,
    int lastSyncedCount = 2,
  }) {
    return syncStateBox.put(
      AlertSyncService.syncStateKey,
      AlertSyncState(
        lastSuccessfulSyncAt: lastSuccessfulSyncAt,
        lastAttemptedSyncAt: lastAttemptedSyncAt,
        lastError: lastError,
        lastSyncedCount: lastSyncedCount,
      ),
    );
  }

  test('automatic sync runs when no previous state exists', () async {
    final result = await createCoordinator().syncIfDue(trigger: 'app_launch');

    expect(result, isTrue);
    expect(syncCount, 1);
    expect(connectivity.checkCount, 1);
  });

  test('automatic sync is limited by the latest attempted timestamp', () async {
    await saveState(
      lastSuccessfulSyncAt: now.subtract(const Duration(hours: 1)),
      lastAttemptedSyncAt: now.subtract(const Duration(minutes: 5)),
    );

    final result = await createCoordinator().syncIfDue(trigger: 'app_resumed');

    expect(result, isTrue);
    expect(syncCount, 0);
    expect(connectivity.checkCount, 0);
  });

  test('automatic sync runs after the fifteen minute interval', () async {
    await saveState(
      lastSuccessfulSyncAt: now.subtract(const Duration(minutes: 15)),
      lastAttemptedSyncAt: now.subtract(const Duration(minutes: 15)),
    );

    await createCoordinator().syncIfDue(trigger: 'foreground_interval');

    expect(syncCount, 1);
  });

  test('manual refresh bypasses the fifteen minute limit', () async {
    await saveState(
      lastSuccessfulSyncAt: now.subtract(const Duration(minutes: 1)),
      lastAttemptedSyncAt: now.subtract(const Duration(minutes: 1)),
    );

    final result = await createCoordinator().syncManually();

    expect(result, isTrue);
    expect(syncCount, 1);
  });

  test(
    'offline sync preserves success metadata and records the attempt',
    () async {
      connectivity.isOnline = false;
      final previousSuccess = now.subtract(const Duration(hours: 2));
      await saveState(
        lastSuccessfulSyncAt: previousSuccess,
        lastAttemptedSyncAt: now.subtract(const Duration(hours: 1)),
        lastSyncedCount: 4,
      );

      final result = await createCoordinator().syncIfDue(
        trigger: 'app_resumed',
      );
      final state = syncStateBox.get(AlertSyncService.syncStateKey);

      expect(result, isFalse);
      expect(syncCount, 0);
      expect(state?.lastSuccessfulSyncAt, previousSuccess);
      expect(state?.lastAttemptedSyncAt, now);
      expect(state?.lastError, AlertSyncCoordinator.offlineError);
      expect(state?.lastSyncedCount, 4);
    },
  );

  test('concurrent triggers share one sync operation', () async {
    final completer = Completer<bool>();
    final coordinator = AlertSyncCoordinator(
      syncRunner: () {
        syncCount += 1;
        return completer.future;
      },
      connectivity: connectivity,
      syncStateBox: syncStateBox,
      now: () => now,
    );

    final first = coordinator.syncIfDue(trigger: 'app_launch');
    final second = coordinator.syncManually();
    await Future<void>.delayed(Duration.zero);
    completer.complete(true);

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(syncCount, 1);
  });
}

class _FakeAlertSyncConnectivity implements AlertSyncConnectivity {
  _FakeAlertSyncConnectivity({required this.isOnline});

  bool isOnline;
  int checkCount = 0;

  @override
  Future<bool> hasInternetAccess() async {
    checkCount += 1;
    return isOnline;
  }
}
