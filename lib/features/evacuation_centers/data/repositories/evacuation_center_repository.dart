import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/shared/services/supabase_service.dart';

typedef EvacuationCenterRowsFetcher
    = Future<List<Map<String, dynamic>>> Function();

/// Syncs evacuation centers from Supabase and caches them locally in Hive.
class EvacuationCenterRepository {
  EvacuationCenterRepository({
    EvacuationCenterRowsFetcher? rowsFetcher,
  }) : _rowsFetcher = rowsFetcher;

  static const String boxName = 'evac_center_box';

  final EvacuationCenterRowsFetcher? _rowsFetcher;
  late Box<CachedEvacCenter> _box;

  Future<void> initBox() async {
    try {
      _box = await Hive.openBox<CachedEvacCenter>(boxName);
    } catch (error) {
      debugPrint('[EvacuationCenters] Failed to open local cache: $error');
      rethrow;
    }
  }

  /// Returns true when the remote query completed and produced a usable result.
  ///
  /// Any existing cache is preserved when the query fails or all returned rows
  /// are invalid.
  Future<bool> syncFromSupabase() async {
    debugPrint('[EvacuationCenters] Starting Supabase sync.');
    try {
      final response = await _fetchRows();
      debugPrint(
        '[EvacuationCenters] Supabase returned ${response.length} rows.',
      );

      if (response.isEmpty) {
        debugPrint(
          '[EvacuationCenters] Supabase returned no rows. '
          'Check table data and SELECT/RLS policies if records are expected.',
        );
        return false;
      }

      final centers = <String, CachedEvacCenter>{};
      for (final row in response) {
        try {
          final center = parseRow(row);
          if (center != null) {
            centers[center.id] = center;
          }
        } catch (error) {
          debugPrint('[EvacuationCenters] Skipped invalid row: $error');
        }
      }
      debugPrint(
        '[EvacuationCenters] Parsed ${centers.length} valid centers.',
      );

      if (centers.isEmpty) {
        debugPrint(
          '[EvacuationCenters] Received ${response.length} rows but none '
          'could be parsed; preserving ${_box.length} cached centers.',
        );
        return false;
      }

      // Write fresh rows before deleting stale ones so Hive listeners never
      // observe an avoidable empty cache between clear and repopulate calls.
      await _box.putAll(centers);
      final staleKeys =
          _box.keys.where((key) => !centers.containsKey(key)).toList();
      if (staleKeys.isNotEmpty) {
        await _box.deleteAll(staleKeys);
      }

      debugPrint(
        '[EvacuationCenters] Wrote ${centers.length} centers to '
        '$boxName.',
      );
      return true;
    } catch (error) {
      debugPrint('[EvacuationCenters] Supabase sync failed: $error');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRows() async {
    final fetcher = _rowsFetcher;
    if (fetcher != null) {
      return fetcher();
    }

    final response = await SupabaseService.client
        .from('evacuation_centers')
        .select(
          'center_id, name, latitude, longitude, '
          'capacity, status, updated_at',
        )
        .order('updated_at', ascending: false);
    return response.cast<Map<String, dynamic>>();
  }

  @visibleForTesting
  static CachedEvacCenter? parseRow(Map<String, dynamic> row) {
    final id = _stringValue(row, const [
      'center_id',
      'id',
      'evac_center_id',
    ]);
    if (id == null || id.isEmpty) {
      return null;
    }

    final coordinates = _coordinates(row);
    return CachedEvacCenter(
      id: id,
      name: _stringValue(row, const [
            'name',
            'center_name',
            'facility_name',
          ]) ??
          'Unnamed evacuation center',
      latitude: coordinates.$1 ?? double.nan,
      longitude: coordinates.$2 ?? double.nan,
      capacity: _intValue(
            _firstValue(row, const [
              'capacity',
              'occupancy',
              'capacity_percent',
            ]),
          ) ??
          0,
      status: _normalizeStatus(
        _stringValue(row, const [
              'status',
              'availability_status',
              'center_status',
            ]) ??
            'Unknown',
      ),
    );
  }

  static (double?, double?) _coordinates(Map<String, dynamic> row) {
    var latitude = _doubleValue(
      _firstValue(row, const [
        'latitude',
        'lat',
        'location_lat',
        'location_latitude',
      ]),
    );
    var longitude = _doubleValue(
      _firstValue(row, const [
        'longitude',
        'lng',
        'lon',
        'long',
        'location_lng',
        'location_longitude',
      ]),
    );

    final coordinates = row['coordinates'] ?? row['location'];
    if (coordinates is Map) {
      final coordinateMap = Map<String, dynamic>.from(coordinates);
      latitude ??= _doubleValue(
        _firstValue(coordinateMap, const ['latitude', 'lat', 'y']),
      );
      longitude ??= _doubleValue(
        _firstValue(coordinateMap, const ['longitude', 'lng', 'lon', 'x']),
      );
    } else if (coordinates is List && coordinates.length >= 2) {
      // GeoJSON coordinates use longitude first, latitude second.
      longitude ??= _doubleValue(coordinates[0]);
      latitude ??= _doubleValue(coordinates[1]);
    } else if (coordinates is String) {
      final pointMatch = RegExp(
        r'POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)',
        caseSensitive: false,
      ).firstMatch(coordinates);
      if (pointMatch != null) {
        longitude ??= double.tryParse(pointMatch.group(1)!);
        latitude ??= double.tryParse(pointMatch.group(2)!);
      }
    }

    return (latitude, longitude);
  }

  static dynamic _firstValue(
    Map<String, dynamic> row,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static String? _stringValue(
    Map<String, dynamic> row,
    List<String> keys,
  ) {
    final value = _firstValue(row, keys);
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static int? _intValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return num.tryParse(value.trim())?.toInt();
    }
    return null;
  }

  static String _normalizeStatus(String status) {
    final normalized = status
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    return switch (normalized) {
      'open' => 'Open',
      'near capacity' => 'Near Capacity',
      'full' => 'Full',
      'closed' => 'Closed',
      _ => normalized.isEmpty ? 'Unknown' : status.trim(),
    };
  }

  List<CachedEvacCenter> getAll() {
    try {
      return _box.values.toList();
    } catch (error) {
      debugPrint('[EvacuationCenters] Failed to read local cache: $error');
      return [];
    }
  }

  ValueListenable<Box<CachedEvacCenter>> getListenable() {
    return _box.listenable();
  }

  int getCount() {
    try {
      return _box.length;
    } catch (error) {
      debugPrint('[EvacuationCenters] Failed to read cache count: $error');
      return 0;
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
