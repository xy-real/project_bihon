import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';

/// Handles all read operations for cached alerts synced from PAGASA.
/// This is a read-only repository in the render path; write operations
/// (syncing alerts from cloud) happen elsewhere.
class AlertsRepository {
  static const String boxName = 'cached_alerts_box';

  late Box<CachedAlert> _box;

  /// Must be called once during app startup after Hive.initFlutter().
  Future<void> initBox() async {
    _box = await Hive.openBox<CachedAlert>(boxName);
  }

  /// Get all active alerts from Hive.
  ///
  /// Returns only alerts where [isActive] is true.
  /// Returns an empty list if no alerts exist or box is not initialized.
  ///
  /// This method is local-only (no network calls).
  List<CachedAlert> getActiveAlerts() {
    try {
      return _box.values
          .where((alert) => alert.isActive)
          .toList();
    } catch (e) {
      // Box not yet initialized or corrupted; return empty list
      return [];
    }
  }

  /// Get a ValueListenable for reactive updates from Hive.
  ///
  /// Useful for ValueListenableBuilder to rebuild UI when alerts change.
  /// Returns only active alerts.
  ValueListenable<Box<CachedAlert>> getAlertsListenable() {
    return _box.listenable();
  }

  /// Get alert count.
  int getAlertCount() {
    return _box.values.where((alert) => alert.isActive).length;
  }

  /// Clear all cached alerts from Hive.
  ///
  /// Used for testing or when resetting alert cache.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
