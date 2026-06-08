import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_service.dart';

typedef AlertSyncRunner = Future<bool> Function();

abstract interface class AlertSyncConnectivity {
  Future<bool> hasInternetAccess();
}

class DnsAlertSyncConnectivity implements AlertSyncConnectivity {
  static const Duration _timeout = Duration(seconds: 5);

  @override
  Future<bool> hasInternetAccess() async {
    try {
      final addresses = await InternetAddress.lookup(
        'supabase.co',
      ).timeout(_timeout);
      return addresses.any((address) => address.rawAddress.isNotEmpty);
    } on Object {
      return false;
    }
  }
}

class AlertSyncCoordinator {
  AlertSyncCoordinator({
    AlertSyncService? syncService,
    AlertSyncRunner? syncRunner,
    AlertSyncConnectivity? connectivity,
    Box<AlertSyncState>? syncStateBox,
    DateTime Function()? now,
  }) : assert(syncService != null || syncRunner != null),
       _syncRunner = syncRunner ?? syncService!.syncAlerts,
       _connectivity = connectivity ?? DnsAlertSyncConnectivity(),
       _syncStateBox =
           syncStateBox ?? Hive.box<AlertSyncState>(AlertSyncState.boxName),
       _now = now ?? DateTime.now;

  static const Duration minimumAutomaticInterval = Duration(minutes: 15);
  static const String offlineError = 'No internet connection.';

  final AlertSyncRunner _syncRunner;
  final AlertSyncConnectivity _connectivity;
  final Box<AlertSyncState> _syncStateBox;
  final DateTime Function() _now;

  Future<bool>? _activeSync;

  Future<bool> syncIfDue({String trigger = 'automatic'}) {
    return _coordinateSync(force: false, trigger: trigger);
  }

  Future<bool> syncManually() {
    return _coordinateSync(force: true, trigger: 'manual');
  }

  Future<bool> _coordinateSync({required bool force, required String trigger}) {
    final activeSync = _activeSync;
    if (activeSync != null) {
      debugPrint(
        '[AlertSyncCoordinator] Reusing active sync for trigger=$trigger.',
      );
      return activeSync;
    }

    final sync = _performSync(force: force, trigger: trigger);
    _activeSync = sync;
    return sync.whenComplete(() {
      if (identical(_activeSync, sync)) {
        _activeSync = null;
      }
    });
  }

  Future<bool> _performSync({
    required bool force,
    required String trigger,
  }) async {
    final now = _now().toUtc();
    final currentState = _syncStateBox.get(AlertSyncService.syncStateKey);

    if (!force && !_isDue(currentState, now)) {
      debugPrint(
        '[AlertSyncCoordinator] Sync skipped; rate limited '
        'for trigger=$trigger.',
      );
      return true;
    }

    final isOnline = await _hasInternetAccess();
    if (!isOnline) {
      await _recordOfflineState(currentState, now);
      debugPrint(
        '[AlertSyncCoordinator] Sync skipped; offline '
        'for trigger=$trigger.',
      );
      return false;
    }

    debugPrint(
      '[AlertSyncCoordinator] Starting sync for trigger=$trigger '
      'force=$force.',
    );
    return _syncRunner();
  }

  bool _isDue(AlertSyncState? state, DateTime now) {
    final lastAttempted = state?.lastAttemptedSyncAt?.toUtc();
    final lastSuccessful = state?.lastSuccessfulSyncAt?.toUtc();
    final reference = _latest(lastAttempted, lastSuccessful);

    if (reference == null) {
      return true;
    }

    return now.difference(reference) >= minimumAutomaticInterval;
  }

  Future<bool> _hasInternetAccess() async {
    try {
      return await _connectivity.hasInternetAccess();
    } on Object catch (error) {
      debugPrint('[AlertSyncCoordinator] Connectivity check failed: $error');
      return false;
    }
  }

  Future<void> _recordOfflineState(
    AlertSyncState? previousState,
    DateTime attemptedAt,
  ) async {
    await _syncStateBox.put(
      AlertSyncService.syncStateKey,
      AlertSyncState(
        lastSuccessfulSyncAt: previousState?.lastSuccessfulSyncAt,
        lastAttemptedSyncAt: attemptedAt,
        lastError: offlineError,
        lastSyncedCount: previousState?.lastSyncedCount ?? 0,
      ),
    );
  }

  static DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }
    if (second == null) {
      return first;
    }
    return first.isAfter(second) ? first : second;
  }
}
