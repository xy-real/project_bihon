import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_coordinator.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_service.dart';
import 'package:project_bihon/features/alerts/presentation/pages/alerts_list_page.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Box<CachedAlert> alertBox;
  late Box<AlertSyncState> syncStateBox;
  late AlertsRepository alertsRepository;
  late HouseholdRepository householdRepository;

  final baseTime = DateTime.utc(2026, 6, 8, 8);

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('alerts_page_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CachedAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HouseholdAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AlertSyncStateAdapter());
    }

    alertsRepository = AlertsRepository();
    await alertsRepository.initBox();
    householdRepository = HouseholdRepository();
    await householdRepository.initBox();
    alertBox = Hive.box<CachedAlert>(CachedAlert.boxName);
    syncStateBox = await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  AlertSyncCoordinator createCoordinator({bool succeeds = true}) {
    return AlertSyncCoordinator(
      syncRunner: () async {
        if (succeeds) {
          await syncStateBox.put(
            AlertSyncService.syncStateKey,
            AlertSyncState(
              lastSuccessfulSyncAt: baseTime,
              lastAttemptedSyncAt: baseTime,
              lastSyncedCount: alertBox.length,
            ),
          );
        }
        return succeeds;
      },
      connectivity: _AlwaysOnlineAlertSyncConnectivity(),
      syncStateBox: syncStateBox,
      now: () => baseTime,
    );
  }

  Future<void> pumpAlertsPage(
    WidgetTester tester, {
    AlertSyncCoordinator? coordinator,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlertsListPage(
          showBottomNavigation: false,
          alertsRepository: alertsRepository,
          alertSyncCoordinator: coordinator ?? createCoordinator(),
          householdRepository: householdRepository,
          syncStateBox: syncStateBox,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows no cached alerts fallback when cache is empty', (
    tester,
  ) async {
    await pumpAlertsPage(tester);

    expect(find.text('No cached alerts yet'), findsWidgets);
    expect(
      find.text('Pull down to fetch alerts when connected.'),
      findsWidgets,
    );
  });
}

class _AlwaysOnlineAlertSyncConnectivity implements AlertSyncConnectivity {
  @override
  Future<bool> hasInternetAccess() async => true;
}
