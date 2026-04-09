import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';

void main() {
  group('CachedAlert Model', () {
    test('riskTags defaults to empty list when null', () {
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        riskTags: null,
      );
      expect(alert.riskTags, equals([]));
    });

    test('riskTags uses provided list when not null', () {
      final tags = ['coastal', 'flood_prone'];
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        riskTags: tags,
      );
      expect(alert.riskTags, equals(tags));
    });

    test('riskTags is empty list by default when not specified', () {
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      expect(alert.riskTags, equals([]));
    });

    test('affectedAreas defaults to empty list when null', () {
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        affectedAreas: null,
      );
      expect(alert.affectedAreas, equals([]));
    });

    test('affectedAreas uses provided list when not null', () {
      final areas = ['Baybay City', 'Nearby Town'];
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        affectedAreas: areas,
      );
      expect(alert.affectedAreas, equals(areas));
    });

    test('can store multiple risk tags', () {
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Test content',
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        riskTags: ['coastal', 'flood_prone', 'landslide_prone'],
      );
      expect(alert.riskTags.length, equals(3));
      expect(alert.riskTags, containsAll(['coastal', 'flood_prone', 'landslide_prone']));
    });

    test('preserves all required fields', () {
      final now = DateTime.now();
      final alert = CachedAlert(
        id: 'alert_123',
        title: 'Typhoon Alert',
        severity: 'High',
        source: 'PAGASA',
        advisoryType: 'Typhoon',
        content: 'Strong winds expected',
        publishedAt: now,
        updatedAt: now,
        isActive: true,
        riskTags: ['coastal'],
      );
      expect(alert.id, equals('alert_123'));
      expect(alert.title, equals('Typhoon Alert'));
      expect(alert.severity, equals('High'));
      expect(alert.source, equals('PAGASA'));
      expect(alert.advisoryType, equals('Typhoon'));
      expect(alert.content, equals('Strong winds expected'));
      expect(alert.publishedAt, equals(now));
      expect(alert.updatedAt, equals(now));
      expect(alert.isActive, equals(true));
    });

    test('can be created with minimal required fields', () {
      final now = DateTime.now();
      final alert = CachedAlert(
        id: 'alert_1',
        title: 'Test',
        severity: 'Low',
        source: 'TEST',
        advisoryType: 'Test',
        content: 'Test content',
        publishedAt: now,
        updatedAt: now,
        isActive: true,
      );
      expect(alert.id, isNotEmpty);
      expect(alert.riskTags, equals([]));
    });
  });
}
