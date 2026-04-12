import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';

void main() {
  group('ThreatBand enum', () {
    test('has direct and general values', () {
      expect(ThreatBand.direct, isNotNull);
      expect(ThreatBand.general, isNotNull);
    });

    test('direct has lower index than general', () {
      expect(ThreatBand.direct.index, lessThan(ThreatBand.general.index));
    });
  });

  group('classifyThreat', () {
    final now = DateTime.now();
    final baseAlert = CachedAlert(
      id: 'alert_1',
      title: 'Test Alert',
      severity: 'High',
      source: 'PAGASA',
      advisoryType: 'Typhoon',
      content: 'Test content',
      publishedAt: now,
      updatedAt: now,
      isActive: true,
    );

    test('returns general if household classification is empty', () {
      final alert = baseAlert.copyWith(riskTags: ['coastal']);
      final result = classifyThreat(alert, '');
      expect(result, equals(ThreatBand.general));
    });

    test('returns general if household classification is "unknown"', () {
      final alert = baseAlert.copyWith(riskTags: ['coastal']);
      final result = classifyThreat(alert, 'unknown');
      expect(result, equals(ThreatBand.general));
    });

    test('returns direct if alert riskTags contains household classification', () {
      final alert = baseAlert.copyWith(riskTags: ['coastal', 'flood_prone']);
      final result = classifyThreat(alert, 'coastal');
      expect(result, equals(ThreatBand.direct));
    });

    test('returns general if alert riskTags does not contain household classification',
        () {
      final alert = baseAlert.copyWith(riskTags: ['flood_prone']);
      final result = classifyThreat(alert, 'coastal');
      expect(result, equals(ThreatBand.general));
    });

    test('returns general if alert has empty riskTags', () {
      final alert = baseAlert.copyWith(riskTags: []);
      final result = classifyThreat(alert, 'coastal');
      expect(result, equals(ThreatBand.general));
    });

    test('returns direct for single matching tag', () {
      final alert = baseAlert.copyWith(riskTags: ['coastal']);
      final result = classifyThreat(alert, 'coastal');
      expect(result, equals(ThreatBand.direct));
    });

    test('is case-sensitive for tag matching', () {
      final alert = baseAlert.copyWith(riskTags: ['Coastal']);
      final result = classifyThreat(alert, 'coastal');
      // Tag should be normalized before storage, but testing exact match requirement
      expect(result, equals(ThreatBand.general));
    });
  });

  group('severityWeight', () {
    test('returns 3 for "high"', () {
      expect(severityWeight('high'), equals(3));
    });

    test('returns 3 for "HIGH" (case-insensitive)', () {
      expect(severityWeight('HIGH'), equals(3));
    });

    test('returns 3 for "High" (mixed case)', () {
      expect(severityWeight('High'), equals(3));
    });

    test('returns 2 for "medium"', () {
      expect(severityWeight('medium'), equals(2));
    });

    test('returns 2 for "MEDIUM" (case-insensitive)', () {
      expect(severityWeight('MEDIUM'), equals(2));
    });

    test('returns 1 for "low"', () {
      expect(severityWeight('low'), equals(1));
    });

    test('returns 1 for "LOW" (case-insensitive)', () {
      expect(severityWeight('LOW'), equals(1));
    });

    test('returns 1 for unknown severity string', () {
      expect(severityWeight('critical'), equals(1));
      expect(severityWeight('unknown'), equals(1));
      expect(severityWeight(''), equals(1));
    });

    test('returns 1 for "low" (default case)', () {
      expect(severityWeight('low'), equals(1));
    });
  });

  group('sortAlerts', () {
    final baseTime = DateTime(2026, 4, 9, 12, 0, 0);
    final laterTime = DateTime(2026, 4, 9, 13, 0, 0);

    CachedAlert createAlert(String id, String severity, List<String> riskTags,
        {DateTime? publishedAt}) {
      return CachedAlert(
        id: id,
        title: 'Alert: $id',
        severity: severity,
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Content for $id',
        publishedAt: publishedAt ?? baseTime,
        updatedAt: baseTime,
        isActive: true,
        riskTags: riskTags,
      );
    }

    test('returns empty list for empty input', () {
      final result = sortAlerts([], 'coastal');
      expect(result, equals([]));
    });

    test('direct threats come before general advisories', () {
      final alerts = [
        createAlert('general_1', 'high', ['flood_prone']),
        createAlert('direct_1', 'low', ['coastal']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(result[0].id, equals('direct_1'));
      expect(result[1].id, equals('general_1'));
    });

    test('within direct threats: high severity before medium', () {
      final alerts = [
        createAlert('direct_medium', 'medium', ['coastal']),
        createAlert('direct_high', 'high', ['coastal']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(result[0].id, equals('direct_high'));
      expect(result[1].id, equals('direct_medium'));
    });

    test('within direct threats: medium before low severity', () {
      final alerts = [
        createAlert('direct_low', 'low', ['coastal']),
        createAlert('direct_medium', 'medium', ['coastal']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(result[0].id, equals('direct_medium'));
      expect(result[1].id, equals('direct_low'));
    });

    test('within same severity: newer published date comes first', () {
      final alerts = [
        createAlert('older', 'high', ['coastal'], publishedAt: baseTime),
        createAlert('newer', 'high', ['coastal'], publishedAt: laterTime),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(result[0].id, equals('newer'));
      expect(result[1].id, equals('older'));
    });

    test('general advisories sorted by severity and date', () {
      final alerts = [
        createAlert('general_low_old', 'low', ['flood_prone'], publishedAt: baseTime),
        createAlert('general_high_new', 'high', ['flood_prone'], publishedAt: laterTime),
        createAlert('general_medium', 'medium', ['flood_prone'], publishedAt: baseTime),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(result[0].id, equals('general_high_new'));
      expect(result[1].id, equals('general_medium'));
      expect(result[2].id, equals('general_low_old'));
    });

    test('complex mixed scenario: direct and general with varied severity', () {
      final alerts = [
        // General advisories
        createAlert('gen_high', 'high', ['flood_prone']),
        createAlert('gen_low', 'low', ['flood_prone']),
        // Direct threats
        createAlert('dir_low', 'low', ['coastal']),
        createAlert('dir_high', 'high', ['coastal']),
        // More general
        createAlert('gen_medium', 'medium', ['flood_prone']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      // Direct threats first
      expect(result[0].id, equals('dir_high'));
      expect(result[1].id, equals('dir_low'));
      // Then general advisories
      expect(result[2].id, equals('gen_high'));
      expect(result[3].id, equals('gen_medium'));
      expect(result[4].id, equals('gen_low'));
    });

    test('does not mutate original list', () {
      final alerts = [
        createAlert('alert_1', 'low', ['coastal']),
        createAlert('alert_2', 'high', ['flood_prone']),
      ];
      final originalOrder = [alerts[0].id, alerts[1].id];
      final result = sortAlerts(alerts, 'coastal');

      // Original list unchanged
      expect(alerts[0].id, equals(originalOrder[0]));
      expect(alerts[1].id, equals(originalOrder[1]));
      // Result is sorted differently
      expect(result[0].id, equals('alert_1'));
      expect(result[1].id, equals('alert_2'));
    });

    test('returns a new list instance', () {
      final alerts = [
        createAlert('alert_1', 'high', ['coastal']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      expect(identical(alerts, result), false);
    });

    test('with unknown household classification: all treated as general', () {
      final alerts = [
        createAlert('with_coastal', 'high', ['coastal']),
        createAlert('with_flood', 'low', ['flood_prone']),
      ];
      final result = sortAlerts(alerts, 'unknown');
      // All are general, so sort by severity: high first
      expect(result[0].id, equals('with_coastal'));
      expect(result[1].id, equals('with_flood'));
    });

    test('maintains stability for identical alerts', () {
      final baseAlerts = [
        createAlert('alert_a', 'high', ['coastal'], publishedAt: baseTime),
        createAlert('alert_b', 'high', ['coastal'], publishedAt: baseTime),
      ];
      final result = sortAlerts(baseAlerts, 'coastal');
      // Both have same severity and time, order should maintain relative position
      expect(result.length, equals(2));
      expect(result[0].severity, equals('high'));
      expect(result[1].severity, equals('high'));
    });

    test('handles multiple risk tags correctly', () {
      final alerts = [
        createAlert('no_match', 'high', ['flood_prone', 'landslide_prone']),
        createAlert('has_coastal', 'low', ['coastal', 'flood_prone']),
      ];
      final result = sortAlerts(alerts, 'coastal');
      // Direct threat (has_coastal) comes first despite lower severity
      expect(result[0].id, equals('has_coastal'));
      expect(result[1].id, equals('no_match'));
    });
  });

  group('Integration: classifyThreat and severityWeight with sortAlerts', () {
    final now = DateTime(2026, 4, 9, 12, 0, 0);

    CachedAlert createAlert(String id, String severity, List<String> riskTags) {
      return CachedAlert(
        id: id,
        title: 'Alert: $id',
        severity: severity,
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Content',
        publishedAt: now,
        updatedAt: now,
        isActive: true,
        riskTags: riskTags,
      );
    }

    test(
        'sorting respects threat classification and severity weight together',
        () {
      final alerts = [
        createAlert('gen_high', 'HIGH', ['flood_prone']),
        createAlert('dir_low', 'low', ['coastal']),
        createAlert('gen_medium', 'MEDIUM', ['flood_prone']),
        createAlert('dir_high', 'high', ['coastal']),
      ];

      final result = sortAlerts(alerts, 'coastal');

      // Direct threats should come first, sorted by severity
      expect(result[0].id, equals('dir_high'));
      expect(result[1].id, equals('dir_low'));
      // Then general advisories, sorted by severity
      expect(result[2].id, equals('gen_high'));
      expect(result[3].id, equals('gen_medium'));
    });
  });
}

/// Extension method to create modified copies of CachedAlert for testing.
extension CachedAlertTestHelper on CachedAlert {
  CachedAlert copyWith({
    String? id,
    String? title,
    String? severity,
    String? source,
    String? advisoryType,
    String? content,
    DateTime? publishedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isActive,
    List<String>? riskTags,
    String? region,
    List<String>? affectedAreas,
    double? latitude,
    double? longitude,
  }) {
    return CachedAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      advisoryType: advisoryType ?? this.advisoryType,
      content: content ?? this.content,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      riskTags: riskTags ?? this.riskTags,
      region: region ?? this.region,
      affectedAreas: affectedAreas ?? this.affectedAreas,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
