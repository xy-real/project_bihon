import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  group('Household Model', () {
    test('default risk_classification is "unknown"', () {
      final household = Household(id: 'test_household');
      expect(household.risk_classification, equals('unknown'));
    });

    test('can set risk_classification to "coastal"', () {
      final household = Household(
        id: 'test_household',
        risk_classification: 'coastal',
      );
      expect(household.risk_classification, equals('coastal'));
    });

    test('can set risk_classification to "flood_prone"', () {
      final household = Household(
        id: 'test_household',
        risk_classification: 'flood_prone',
      );
      expect(household.risk_classification, equals('flood_prone'));
    });

    test('can set risk_classification to "landslide_prone"', () {
      final household = Household(
        id: 'test_household',
        risk_classification: 'landslide_prone',
      );
      expect(household.risk_classification, equals('landslide_prone'));
    });

    test('can set risk_classification to "unknown"', () {
      final household = Household(
        id: 'test_household',
        risk_classification: 'unknown',
      );
      expect(household.risk_classification, equals('unknown'));
    });

    test('defaults to "unknown" for invalid risk_classification', () {
      final household = Household(
        id: 'test_household',
        risk_classification: 'invalid_value',
      );
      expect(household.risk_classification, equals('unknown'));
    });

    test('defaults to "unknown" for empty risk_classification', () {
      final household = Household(
        id: 'test_household',
        risk_classification: '',
      );
      expect(household.risk_classification, equals('unknown'));
    });

    test('validates all canonical values', () {
      final validValues = ['coastal', 'flood_prone', 'landslide_prone', 'unknown'];
      for (final value in validValues) {
        final household = Household(
          id: 'test_household',
          risk_classification: value,
        );
        expect(household.risk_classification, equals(value));
      }
    });

    test('household ID is preserved', () {
      final household = Household(
        id: 'my_household_123',
        risk_classification: 'coastal',
      );
      expect(household.id, equals('my_household_123'));
    });
  });
}
