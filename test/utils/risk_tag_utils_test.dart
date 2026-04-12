import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/utils/risk_tag_utils.dart';

void main() {
  group('normalizeRiskTag', () {
    test('trims leading and trailing whitespace', () {
      expect(normalizeRiskTag('  coastal  '), equals('coastal'));
      expect(normalizeRiskTag('\tflood_prone\n'), equals('flood_prone'));
    });

    test('converts to lowercase', () {
      expect(normalizeRiskTag('COASTAL'), equals('coastal'));
      expect(normalizeRiskTag('Flood_Prone'), equals('flood_prone'));
      expect(normalizeRiskTag('LANDSLIDE_PRONE'), equals('landslide_prone'));
    });

    test('replaces spaces with underscores', () {
      expect(normalizeRiskTag('flood prone'), equals('flood_prone'));
      expect(normalizeRiskTag('landslide prone'), equals('landslide_prone'));
    });

    test('replaces hyphens with underscores', () {
      expect(normalizeRiskTag('flood-prone'), equals('flood_prone'));
      expect(normalizeRiskTag('landslide-prone'), equals('landslide_prone'));
    });

    test('handles mixed case with spaces and hyphens', () {
      expect(normalizeRiskTag('  Flood-Prone  '), equals('flood_prone'));
      expect(normalizeRiskTag('LANDSLIDE PRONE'), equals('landslide_prone'));
      expect(normalizeRiskTag('CoAstal'), equals('coastal'));
    });

    test('handles strings with multiple spaces', () {
      expect(normalizeRiskTag('flood  prone'), equals('flood__prone'));
    });

    test('handles strings with mixed spaces and hyphens', () {
      expect(normalizeRiskTag('flood-prone area'), equals('flood_prone_area'));
    });

    test('returns empty string for empty input', () {
      expect(normalizeRiskTag(''), equals(''));
    });

    test('returns empty string for whitespace-only input', () {
      expect(normalizeRiskTag('   '), equals(''));
    });
  });

  group('normalizeRiskTags', () {
    test('normalizes all tags in a list', () {
      final result = normalizeRiskTags(['Coastal', 'FLOOD_PRONE', 'landslide-prone']);
      expect(result, containsAll(['coastal', 'flood_prone', 'landslide_prone']));
    });

    test('removes duplicate tags after normalization', () {
      final result = normalizeRiskTags(['coastal', 'COASTAL', 'Coastal']);
      expect(result, equals(['coastal']));
    });

    test('removes duplicates with different formatting', () {
      final result = normalizeRiskTags(['flood-prone', 'flood_prone', 'FLOOD PRONE']);
      expect(result, equals(['flood_prone']));
    });

    test('handles empty list', () {
      expect(normalizeRiskTags([]), equals([]));
    });

    test('handles list with empty strings', () {
      final result = normalizeRiskTags(['coastal', '', 'flood_prone', '   ']);
      expect(result.length, equals(2));
      expect(result, containsAll(['coastal', 'flood_prone']));
    });

    test('returns new list instance (not same reference)', () {
      final input = ['coastal', 'flood_prone'];
      final result = normalizeRiskTags(input);
      expect(identical(input, result), false);
    });

    test('handles mixed case duplicates', () {
      final result = normalizeRiskTags(['Coastal', 'COASTAL', 'CoAstal', 'coastal']);
      expect(result, equals(['coastal']));
    });

    test('complex deduplication scenario', () {
      final input = [
        'coastal',
        'Coastal',
        'flood-prone',
        'FLOOD_PRONE',
        'landslide prone',
        'LANDSLIDE_PRONE',
      ];
      final result = normalizeRiskTags(input);
      expect(result.length, equals(3));
      expect(result, containsAll(['coastal', 'flood_prone', 'landslide_prone']));
    });
  });
}
