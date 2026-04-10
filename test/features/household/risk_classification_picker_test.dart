import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/household/presentation/widgets/risk_classification_picker.dart';

void main() {
  group('RiskClassificationPicker Widget', () {
    test('riskClassificationOptions has all required canonical values', () {
      expect(
        riskClassificationOptions.keys.toList(),
        containsAll(['coastal', 'flood_prone', 'landslide_prone']),
      );
    });

    test('each option has label and description', () {
      for (final entry in riskClassificationOptions.entries) {
        expect(entry.value.containsKey('label'), isTrue);
        expect(entry.value.containsKey('description'), isTrue);
        expect(entry.value['label'], isNotEmpty);
        expect(entry.value['description'], isNotEmpty);
      }
    });

    test('coastal option has correct label', () {
      final coastal = riskClassificationOptions['coastal'];
      expect(coastal?['label'], equals('Near the ocean'));
    });

    test('flood_prone option has correct label', () {
      final floodProne = riskClassificationOptions['flood_prone'];
      expect(floodProne?['label'], equals('Near river or low-lying area'));
    });

    test('landslide_prone option has correct label', () {
      final landslideProne = riskClassificationOptions['landslide_prone'];
      expect(landslideProne?['label'], equals('Near steep slope or mountain'));
    });

    test('all options have descriptions', () {
      for (final option in riskClassificationOptions.values) {
        expect(option['description'], isNotEmpty);
        expect(option['description'], isNotNull);
      }
    });
  });
}
