import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  group('HouseholdRepository', () {
    test('constants are defined correctly', () {
      expect(HouseholdRepository.boxName, equals('household_box'));
      expect(
        HouseholdRepository.defaultHouseholdId,
        equals('default_household'),
      );
      expect(HouseholdRepository.riskClassificationKey, equals('risk_classification'));
    });

    test('Household model validates risk_classification', () {
      final validHousehold = Household(
        id: 'test',
        risk_classification: 'coastal',
      );
      expect(validHousehold.risk_classification, equals('coastal'));

      final invalidHousehold = Household(
        id: 'test',
        risk_classification: 'invalid_value',
      );
      expect(invalidHousehold.risk_classification, equals('unknown'));
    });

    test('Household sets default risk_classification to unknown', () {
      final household = Household(id: 'test');
      expect(household.risk_classification, equals('unknown'));
    });

    test('Household preserves valid risk_classification values', () {
      final validValues = [
        'coastal',
        'flood_prone',
        'landslide_prone',
        'unknown',
      ];

      for (final value in validValues) {
        final household = Household(
          id: 'test_$value',
          risk_classification: value,
        );
        expect(household.risk_classification, equals(value));
      }
    });
  });
}
