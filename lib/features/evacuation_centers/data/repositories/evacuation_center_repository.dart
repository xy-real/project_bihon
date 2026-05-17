import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/shared/services/supabase_service.dart';

/// Handles evacuation center data synced from Supabase.
/// 
/// This repository caches evacuation centers locally in Hive and provides
/// methods to sync fresh data from Supabase. All Supabase operations are
/// wrapped in try/catch for offline resilience — errors are logged but
/// never thrown to ensure graceful degradation.
class EvacuationCenterRepository {
  static const String boxName = 'evac_center_box';
  
  late Box<CachedEvacCenter> _box;

  /// Initialize the evacuation centers Hive box.
  ///
  /// Must be called once during app startup after Hive.initFlutter().
  Future<void> initBox() async {
    _box = await Hive.openBox<CachedEvacCenter>(boxName);
  }

  /// Sync evacuation centers from Supabase and cache locally.
  ///
  /// Queries `evacuation_centers` table for all records, maps each row to
  /// [CachedEvacCenter], and stores in the local Hive box.
  /// 
  /// On error (network, parsing, etc.):
  /// - Logs the error to the console for debugging
  /// - Does NOT throw; returns silently to maintain offline resilience
  /// - Local cached data remains untouched
  ///
  /// Useful for:
  /// - Periodic background syncs
  /// - Initial app startup to populate cache
  /// - Manual refresh actions in UI
  Future<void> syncFromSupabase() async {
    try {
      final response = await SupabaseService.client
          .from('evacuation_centers')
          .select('center_id, name, latitude, longitude, capacity, status, updated_at');

      if (response.isEmpty) {
        developer.log('No evacuation centers returned from Supabase');
        return;
      }

      // Map Supabase rows to CachedEvacCenter objects
      final centers = <String, CachedEvacCenter>{};
      for (final row in response) {
        try {
          final center = CachedEvacCenter(
            id: row['center_id'] as String? ?? '',
            name: row['name'] as String? ?? '',
            latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
            capacity: row['capacity'] as int? ?? 0,
            status: row['status'] as String? ?? 'Unknown',
          );
          if (center.id.isNotEmpty) {
            centers[center.id] = center;
          }
        } catch (e) {
          developer.log('Error mapping evacuation center row: $e');
          continue;
        }
      }

      // Clear and repopulate box
      await _box.clear();
      await _box.putAll(centers);
      developer.log('Synced ${centers.length} evacuation centers');
    } catch (e) {
      developer.log('Error syncing evacuation centers from Supabase: $e');
      // Offline resilience: do not throw, leave local cache as-is
    }
  }

  /// Get all cached evacuation centers from Hive.
  ///
  /// Returns an empty list if no centers exist or box is not initialized.
  /// This method is local-only (no network calls).
  List<CachedEvacCenter> getAll() {
    try {
      return _box.values.toList();
    } catch (e) {
      // Box not yet initialized or corrupted; return empty list
      developer.log('Error reading evacuation centers: $e');
      return [];
    }
  }

  /// Get a ValueListenable for reactive updates from Hive.
  ///
  /// Useful for ValueListenableBuilder to rebuild UI when evacuation centers change.
  /// Emits whenever the underlying Hive box is modified.
  ValueListenable<Box<CachedEvacCenter>> getListenable() {
    return _box.listenable();
  }

  /// Get evacuation center count.
  int getCount() {
    try {
      return _box.length;
    } catch (e) {
      developer.log('Error getting evacuation center count: $e');
      return 0;
    }
  }

  /// Clear all cached evacuation centers from Hive.
  ///
  /// Used for testing or when resetting evacuation center cache.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
