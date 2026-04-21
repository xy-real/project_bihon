import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/evacuation/data/models/cached_evac_center.dart';

/// Handles all read operations for cached evacuation centers synced from Supabase.
/// This is a read-only repository in the render path; write operations
/// (syncing centers from cloud) happen in the sync service.
class EvacuationCenterRepository {
  static const String boxName = 'evac_center_box';

  late Box<CachedEvacCenter> _box;

  /// Must be called once during app startup after Hive.initFlutter().
  Future<void> initBox() async {
    _box = await Hive.openBox<CachedEvacCenter>(boxName);
  }

  /// Get all evacuation centers from Hive.
  ///
  /// Returns all cached centers.
  /// Returns an empty list if no centers exist or box is not initialized.
  ///
  /// This method is local-only (no network calls).
  List<CachedEvacCenter> getAllCenters() {
    try {
      return _box.values.toList();
    } catch (e) {
      // Box not yet initialized or corrupted; return empty list
      return [];
    }
  }

  /// Get a ValueListenable for reactive updates from Hive.
  ///
  /// Useful for ValueListenableBuilder to rebuild UI when centers change.
  ValueListenable<Box<CachedEvacCenter>> getCentersListenable() {
    return _box.listenable();
  }

  /// Get evacuation center count.
  int getCenterCount() {
    return _box.length;
  }

  /// Clear all cached evacuation centers from Hive.
  ///
  /// Used for testing or when resetting cache.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get the underlying Hive box for direct upsert operations (used by sync service).
  Box<CachedEvacCenter> getBox() {
    return _box;
  }
}
