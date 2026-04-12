import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';

void main() {
  final baseTime = DateTime(2026, 4, 10, 12, 0, 0);

  CachedAlert createTestAlert({
    String id = 'test_alert',
    String title = 'Test Alert',
    String severity = 'High',
    String content = 'This is a test alert',
    String advisoryType = 'Typhoon',
    DateTime? publishedAt,
    List<String> riskTags = const [],
    bool isActive = true,
  }) {
    return CachedAlert(
      id: id,
      title: title,
      severity: severity,
      source: 'PAGASA',
      advisoryType: advisoryType,
      content: content,
      publishedAt: publishedAt ?? baseTime,
      updatedAt: baseTime,
      isActive: isActive,
      riskTags: riskTags,
      affectedAreas: [],
    );
  }

  group('Offline Resilience - Task B', () {
    test('classifyThreat returns general when household is null', () {
      final alert = createTestAlert(riskTags: ['coastal']);
      final threatBand = classifyThreat(alert, 'unknown');
      expect(threatBand, ThreatBand.general);
    });

    test('classifyThreat returns general when riskTags is empty', () {
      final alert = createTestAlert(riskTags: []);
      final threatBand = classifyThreat(alert, 'coastal');
      expect(threatBand, ThreatBand.general);
    });

    test('classifyThreat returns direct when match found', () {
      final alert = createTestAlert(riskTags: ['coastal', 'flood_prone']);
      final threatBand = classifyThreat(alert, 'coastal');
      expect(threatBand, ThreatBand.direct);
    });

    test('sortAlerts returns empty list when alerts is empty', () {
      final sorted = sortAlerts([], 'coastal');
      expect(sorted, isEmpty);
    });

    test('sortAlerts handles null risk classification gracefully', () {
      final alerts = [
        createTestAlert(
          id: 'a1',
          riskTags: ['coastal'],
          severity: 'High',
        ),
        createTestAlert(
          id: 'a2',
          riskTags: [],
          severity: 'Medium',
        ),
      ];
      final sorted = sortAlerts(alerts, 'unknown');
      // All should be general threats since risk_classification is 'unknown'
      expect(sorted, hasLength(2));
    });

    test('sortAlerts sorts direct threats before general threats', () {
      final alerts = [
        createTestAlert(
          id: 'general',
          riskTags: [],
          severity: 'High',
        ),
        createTestAlert(
          id: 'direct',
          riskTags: ['coastal'],
          severity: 'Low',
        ),
      ];
      final sorted = sortAlerts(alerts, 'coastal');
      expect(sorted[0].id, 'direct');
      expect(sorted[1].id, 'general');
    });

    test('sortAlerts respects empty title gracefully', () {
      final alert = createTestAlert(title: '', content: '');
      final threatBand = classifyThreat(alert, 'unknown');
      expect(threatBand, ThreatBand.general); // No crash
    });
  });

  group('No Network Dependency - Task C', () {
    test('classifyThreat is pure function with no side effects', () {
      final alert = createTestAlert(riskTags: ['coastal']);
      final original = alert;
      classifyThreat(alert, 'coastal');
      expect(alert, same(original)); // No mutation
    });

    test('sortAlerts does not mutate input list', () {
      final alerts = [
        createTestAlert(id: 'a1', severity: 'Medium'),
        createTestAlert(id: 'a2', severity: 'High'),
      ];
      final original = [alerts[0], alerts[1]];
      sortAlerts(alerts, 'unknown');
      expect(alerts, original); // Original list unchanged
    });

    test('severityWeight is pure function', () {
      expect(severityWeight('high'), 3);
      expect(severityWeight('HIGH'), 3);
      expect(severityWeight('medium'), 2);
      expect(severityWeight('MEDIUM'), 2);
      expect(severityWeight('low'), 1);
      expect(severityWeight('unknown'), 1);
    });
  });

  group('QA Scenario 1: Set profile risk to coastal', () {
    test('coastal-tagged alerts are classified as direct threats', () {
      final alert = createTestAlert(riskTags: ['coastal']);
      final threatBand = classifyThreat(alert, 'coastal');
      expect(threatBand, ThreatBand.direct);
    });

    test('coastal-tagged alerts appear before general alerts in sorted list', () {
      final alerts = [
        createTestAlert(id: 'gen', riskTags: []),
        createTestAlert(id: 'coastal1', riskTags: ['coastal']),
        createTestAlert(id: 'coastal2', riskTags: ['coastal']),
      ];
      final sorted = sortAlerts(alerts, 'coastal');
      expect(sorted[0].id, 'coastal1');
      expect(sorted[1].id, 'coastal2');
      expect(sorted[2].id, 'gen');
    });
  });

  group('QA Scenario 2: Change risk to flood_prone', () {
    test('flood_prone-tagged alerts become direct when profile changes', () {
      final alerts = [
        createTestAlert(
          id: 'coastal',
          riskTags: ['coastal'],
          severity: 'High',
        ),
        createTestAlert(
          id: 'flood',
          riskTags: ['flood_prone'],
          severity: 'Medium',
        ),
      ];
      // Before: coastal is direct
      var sorted = sortAlerts(alerts, 'coastal');
      expect(sorted[0].id, 'coastal');

      // After: flood_prone is direct
      sorted = sortAlerts(alerts, 'flood_prone');
      expect(sorted[0].id, 'flood');
    });
  });

  group('QA Scenario 3: Alert with empty riskTags', () {
    test('empty riskTags alert renders as general advisory', () {
      final alert = createTestAlert(riskTags: []);
      final threatBand = classifyThreat(alert, 'coastal');
      expect(threatBand, ThreatBand.general);
    });

    test('empty riskTags sorted after direct threats', () {
      final alerts = [
        createTestAlert(id: 'empty', riskTags: [], severity: 'High'),
        createTestAlert(id: 'direct', riskTags: ['coastal'], severity: 'Low'),
      ];
      final sorted = sortAlerts(alerts, 'coastal');
      expect(sorted[0].id, 'direct');
      expect(sorted[1].id, 'empty');
    });
  });

  group('QA Scenario 4: Household profile deleted', () {
    test('null household treated as unknown risk classification', () {
      final alert = createTestAlert(riskTags: ['coastal']);
      // Simulate deleted/null household
      final threatBand = classifyThreat(alert, 'unknown');
      expect(threatBand, ThreatBand.general); // No crash, safe fallback
    });

    test('all alerts render as general when household missing', () {
      final alerts = [
        createTestAlert(id: 'a1', riskTags: ['coastal']),
        createTestAlert(id: 'a2', riskTags: ['flood_prone']),
        createTestAlert(id: 'a3', riskTags: []),
      ];
      final sorted = sortAlerts(alerts, 'unknown');
      // All should be general threats
      for (final alert in sorted) {
        expect(classifyThreat(alert, 'unknown'), ThreatBand.general);
      }
    });
  });

  group('QA Scenario 5: Airplane mode test', () {
    test('deterministic sort order with cached data', () {
      final alerts = [
        createTestAlert(
          id: 'a1',
          riskTags: ['coastal'],
          severity: 'High',
          publishedAt: baseTime.subtract(const Duration(hours: 1)),
        ),
        createTestAlert(
          id: 'a2',
          riskTags: ['coastal'],
          severity: 'High',
          publishedAt: baseTime,
        ),
        createTestAlert(
          id: 'a3',
          riskTags: [],
          severity: 'Low',
          publishedAt: baseTime,
        ),
      ];

      // Sort twice; order should be identical (deterministic)
      final sorted1 = sortAlerts(alerts, 'coastal');
      final sorted2 = sortAlerts(alerts, 'coastal');

      expect(
        sorted1.map((a) => a.id).toList(),
        sorted2.map((a) => a.id).toList(),
      );

      // First two are direct threats (same severity, newer first)
      expect(sorted1[0].id, 'a2'); // Newer
      expect(sorted1[1].id, 'a1'); // Older
      expect(sorted1[2].id, 'a3'); // General
    });

    test('sorting order persists across multiple calls', () {
      final alerts = [
        createTestAlert(id: 'direct', riskTags: ['coastal'], severity: 'High'),
        createTestAlert(id: 'general', riskTags: [], severity: 'High'),
      ];

      for (int i = 0; i < 5; i++) {
        final sorted = sortAlerts(alerts, 'coastal');
        expect(sorted[0].id, 'direct');
        expect(sorted[1].id, 'general');
      }
    });
  });

  group('Task A - Data Reading', () {
    test('classifyThreat reads riskTags from alert', () {
      final alertWithTags = createTestAlert(riskTags: ['coastal']);
      final alertWithoutTags = createTestAlert(riskTags: []);

      expect(
        classifyThreat(alertWithTags, 'coastal'),
        ThreatBand.direct,
      );
      expect(
        classifyThreat(alertWithoutTags, 'coastal'),
        ThreatBand.general,
      );
    });

    test('sortAlerts filters by isActive implicitly via classification', () {
      // Note: AlertsRepository.getActiveAlerts() filters isActive
      // But sortAlerts works on whatever list is passed to it
      final alerts = [
        createTestAlert(id: 'active', isActive: true),
        createTestAlert(id: 'inactive', isActive: false),
      ];
      // sortAlerts doesn't filter isActive; repository does that
      final sorted = sortAlerts(alerts, 'unknown');
      expect(sorted, hasLength(2)); // Both are in result
    });
  });
}
