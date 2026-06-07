import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/shared/services/supabase_service.dart';

typedef AlertRowsFetcher = Future<List<Map<String, dynamic>>> Function();

class AlertSyncService {
  AlertSyncService({
    AlertRowsFetcher? rowsFetcher,
    Box<CachedAlert>? alertBox,
    Box<AlertSyncState>? syncStateBox,
    DateTime Function()? now,
  })  : _rowsFetcher = rowsFetcher,
        _alertBox = alertBox ?? Hive.box<CachedAlert>(CachedAlert.boxName),
        _syncStateBox =
            syncStateBox ?? Hive.box<AlertSyncState>(AlertSyncState.boxName),
        _now = now ?? DateTime.now;

  static const String tableName = 'global_alerts';
  static const String syncStateKey = 'latest';
  static const Duration retentionPeriod = Duration(days: 30);
  static const String selectedColumns =
      'id, source, source_alert_id, title, severity, advisory_type, '
      'content, region, affected_areas, risk_tags, latitude, longitude, '
      'published_at, updated_at, expires_at, is_active, ingested_at';

  final AlertRowsFetcher? _rowsFetcher;
  final Box<CachedAlert> _alertBox;
  final Box<AlertSyncState> _syncStateBox;
  final DateTime Function() _now;

  Future<bool>? _activeSync;

  Future<bool> syncAlerts() {
    final activeSync = _activeSync;
    if (activeSync != null) {
      return activeSync;
    }

    final sync = _performSync();
    _activeSync = sync;
    return sync.whenComplete(() {
      if (identical(_activeSync, sync)) {
        _activeSync = null;
      }
    });
  }

  Future<bool> _performSync() async {
    final attemptedAt = _now().toUtc();
    AlertSyncState? previousState;

    debugPrint('[AlertSyncService] Sync started.');

    try {
      previousState = _syncStateBox.get(syncStateKey);
      await _syncStateBox.put(
        syncStateKey,
        AlertSyncState(
          lastSuccessfulSyncAt: previousState?.lastSuccessfulSyncAt,
          lastAttemptedSyncAt: attemptedAt,
          lastError: null,
          lastSyncedCount: previousState?.lastSyncedCount ?? 0,
        ),
      );

      final rows = await _fetchRows();
      debugPrint('[AlertSyncService] Rows fetched: ${rows.length}.');

      final alerts = <String, CachedAlert>{};
      for (final row in rows) {
        try {
          final alert = parseRow(row);
          alerts[alert.id] = alert;
        } on Object catch (error) {
          final id = _optionalString(row['id']) ?? 'unknown';
          final source = _optionalString(row['source']) ?? 'unknown';
          debugPrint(
            '[AlertSyncService] Skipped corrupt row '
            'id=$id source=$source: $error',
          );
        }
      }
      debugPrint('[AlertSyncService] Rows parsed: ${alerts.length}.');

      if (alerts.isNotEmpty) {
        await _alertBox.putAll(alerts);
      }

      final removedCount = await _purgeOldAlerts(attemptedAt);
      debugPrint(
        '[AlertSyncService] Rows cached: ${alerts.length}; '
        'expired cache rows removed: $removedCount.',
      );

      await _syncStateBox.put(
        syncStateKey,
        AlertSyncState(
          lastSuccessfulSyncAt: _now().toUtc(),
          lastAttemptedSyncAt: attemptedAt,
          lastError: null,
          lastSyncedCount: alerts.length,
        ),
      );
      return true;
    } on Object catch (error) {
      await _recordFailure(
        previousState: previousState,
        attemptedAt: attemptedAt,
        error: error,
      );
      debugPrint('[AlertSyncService] Sync failed: $error');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRows() async {
    final rowsFetcher = _rowsFetcher;
    if (rowsFetcher != null) {
      return rowsFetcher();
    }

    final rows = await SupabaseService.client
        .from(tableName)
        .select(selectedColumns)
        .eq('is_active', true)
        .order('published_at', ascending: false);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> _recordFailure({
    required AlertSyncState? previousState,
    required DateTime attemptedAt,
    required Object error,
  }) async {
    try {
      await _syncStateBox.put(
        syncStateKey,
        AlertSyncState(
          lastSuccessfulSyncAt: previousState?.lastSuccessfulSyncAt,
          lastAttemptedSyncAt: attemptedAt,
          lastError: error.toString(),
          lastSyncedCount: previousState?.lastSyncedCount ?? 0,
        ),
      );
    } on Object catch (stateError) {
      debugPrint(
        '[AlertSyncService] Failed to store sync error state: $stateError',
      );
    }
  }

  Future<int> _purgeOldAlerts(DateTime referenceTime) async {
    final cutoff = referenceTime.subtract(retentionPeriod);
    final expiredKeys = <dynamic>[];

    for (final key in _alertBox.keys) {
      final alert = _alertBox.get(key);
      if (alert != null && alert.publishedAt.toUtc().isBefore(cutoff)) {
        expiredKeys.add(key);
      }
    }

    if (expiredKeys.isNotEmpty) {
      await _alertBox.deleteAll(expiredKeys);
    }
    return expiredKeys.length;
  }

  @visibleForTesting
  static CachedAlert parseRow(Map<String, dynamic> row) {
    return CachedAlert(
      id: _requiredString(row, 'id'),
      title: _requiredString(row, 'title'),
      severity: _requiredString(row, 'severity'),
      source: _requiredString(row, 'source'),
      advisoryType: _requiredString(row, 'advisory_type'),
      content: _requiredString(row, 'content'),
      publishedAt: _requiredDateTime(row, 'published_at'),
      updatedAt: _requiredDateTime(row, 'updated_at'),
      expiresAt: _optionalDateTime(row['expires_at']),
      isActive: _optionalBool(row['is_active']) ?? true,
      riskTags: normalizeRiskTags(row['risk_tags']),
      region: _optionalString(row['region']),
      affectedAreas: normalizeAffectedAreas(row['affected_areas']),
      latitude: _optionalDouble(row['latitude']),
      longitude: _optionalDouble(row['longitude']),
    );
  }

  @visibleForTesting
  static List<String> normalizeRiskTags(dynamic value) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final item in _listValues(value, splitPlainText: true)) {
      final tag = item
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\s-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      if (tag.isNotEmpty && seen.add(tag)) {
        normalized.add(tag);
      }
    }
    return normalized;
  }

  @visibleForTesting
  static List<String> normalizeAffectedAreas(dynamic value) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final item in _listValues(value)) {
      final area = item.trim();
      if (area.isNotEmpty && seen.add(area)) {
        normalized.add(area);
      }
    }
    return normalized;
  }

  static List<String> _listValues(
    dynamic value, {
    bool splitPlainText = false,
  }) {
    if (value == null) {
      return const [];
    }
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    if (value is! String) {
      return [value.toString()];
    }

    final text = value.trim();
    if (text.isEmpty) {
      return const [];
    }

    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded
              .map((item) => item.toString())
              .toList(growable: false);
        }
      } on FormatException {
        // Fall through to the plain-text representation.
      }
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      return text
          .substring(1, text.length - 1)
          .split(',')
          .map((item) => item.trim())
          .toList(growable: false);
    }

    return splitPlainText ? text.split(',') : [text];
  }

  static String _requiredString(Map<String, dynamic> row, String key) {
    final value = _optionalString(row[key]);
    if (value == null) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime _requiredDateTime(
    Map<String, dynamic> row,
    String key,
  ) {
    final value = _optionalDateTime(row[key]);
    if (value == null) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }

  static DateTime? _optionalDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value.trim())?.toUtc();
    }
    return null;
  }

  static double? _optionalDouble(dynamic value) {
    final number = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text.trim()),
      _ => null,
    };
    return number != null && number.isFinite ? number : null;
  }

  static bool? _optionalBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return switch (value.trim().toLowerCase()) {
        'true' || '1' => true,
        'false' || '0' => false,
        _ => null,
      };
    }
    return null;
  }
}
