import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_bihon/features/evacuation/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation/data/repositories/evacuation_center_repository.dart';

/// Syncs evacuation center data from Supabase to local Hive cache.
/// 
/// Only syncs when network connection is available.
/// Gracefully handles sync failures without crashing the app.
class EvacuationCenterSyncService {
  final EvacuationCenterRepository _repository;
  final Connectivity _connectivity;

  EvacuationCenterSyncService({
    required EvacuationCenterRepository repository,
    Connectivity? connectivity,
  })  : _repository = repository,
        _connectivity = connectivity ?? Connectivity();

  /// Syncs evacuation centers from Supabase to Hive cache.
  /// 
  /// Returns true if sync was successful, false otherwise.
  /// 
  /// - Checks for network connection first
  /// - Queries all columns from `evacuation_centers` table in Supabase
  /// - Maps each row to a CachedEvacCenter instance
  /// - Upserts into `evac_center_box` using `center_id` as the key
  /// - Handles timeouts and empty responses gracefully
  /// - Never crashes the app on sync failure
  Future<bool> syncEvacCenters() async {
    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty ||
          connectivityResult.contains(ConnectivityResult.none)) {
        // No network connection available
        return false;
      }

      // Get Supabase client
      final supabaseClient = Supabase.instance.client;

      // Query evacuation_centers table with a timeout
      final response = await supabaseClient
          .from('evacuation_centers')
          .select()
          .timeout(const Duration(seconds: 30));

      // Handle empty response
      if (response.isEmpty) {
        return true; // Success, but no data to sync
      }

      // Get the Hive box for upsert operations
      final box = _repository.getBox();

      // Map and upsert each row
      for (final row in response as List<dynamic>) {
        try {
          final center = CachedEvacCenter(
            id: row['center_id'] as String? ?? '',
            name: row['name'] as String? ?? '',
            latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
            capacity: row['capacity'] as int? ?? 0,
            status: row['status'] as String? ?? 'active',
          );

          // Upsert using center_id as the key
          await box.put(center.id, center);
        } catch (e) {
          // Log individual row errors but continue syncing other rows
          // In production, consider a logging service here
          continue;
        }
      }

      return true;
    } on TimeoutException {
      // Timeout occurred while syncing; return failure but don't crash
      return false;
    } on SocketException {
      // Network error occurred; return failure but don't crash
      return false;
    } catch (e) {
      // Catch all other exceptions to prevent app crash
      // In production, consider logging this error
      return false;
    }
  }
}
