import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_prompt_builder.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  final now = DateTime.now();

  SupplyItem buildSupply({
    String id = 'supply-id',
    String name = 'Bottled Water',
    String category = 'Water',
    int quantity = 6,
    DateTime? expirationDate,
    String? imageUrl,
    String householdId = 'private-household-id',
  }) {
    return SupplyItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      expirationDate: expirationDate ?? now.add(const Duration(days: 30)),
      imageUrl: imageUrl,
      householdId: householdId,
    );
  }

  test('excludes expired supplies and includes unexpired supplies', () {
    final prompt = buildSanitizedPrompt(
      Household(id: 'household-id', risk_classification: 'coastal'),
      [
        buildSupply(
          name: 'Expired Rice',
          expirationDate: now.subtract(const Duration(days: 1)),
        ),
        buildSupply(name: 'Bottled Water', quantity: 8),
      ],
    );

    expect(prompt, contains('8x Bottled Water (Water)'));
    expect(prompt, isNot(contains('Expired Rice')));
  });

  test('uses the empty inventory fallback when no valid supplies exist', () {
    final prompt = buildSanitizedPrompt(
      Household(id: 'household-id'),
      [
        buildSupply(
          expirationDate: now.subtract(const Duration(days: 1)),
        ),
      ],
    );

    expect(prompt, contains('Current Unexpired Inventory:\nNo valid supplies.'));
  });

  test(
    'includes risk classification and a truthful household size fallback',
    () {
      final prompt = buildSanitizedPrompt(
        Household(id: 'household-id', risk_classification: 'flood_prone'),
        const [],
      );

      expect(prompt, contains('- Size: Not provided'));
      expect(prompt, contains('- Location Risk: flood_prone'));
    },
  );

  test(
    'does not include identifiers, image paths, phones, or coordinates',
    () {
      final prompt = buildSanitizedPrompt(
        Household(
          id: 'private-household-id',
          risk_classification: 'landslide_prone',
        ),
        [
          buildSupply(
            id: 'private-supply-id',
            name: 'Emergency Kit 0917 123 4567 at 10.12345, 124.12345',
            imageUrl: r'C:\Users\Private\Maria-Santos-contact-photo.png',
            householdId: 'private-household-id',
          ),
        ],
      );

      expect(prompt, isNot(contains('private-household-id')));
      expect(prompt, isNot(contains('private-supply-id')));
      expect(prompt, isNot(contains(r'C:\Users\Private')));
      expect(prompt, isNot(contains('Maria Santos')));
      expect(prompt, isNot(contains('0917 123 4567')));
      expect(prompt, isNot(contains('10.12345, 124.12345')));
      expect(prompt, contains('Emergency Kit [redacted] at [redacted]'));
    },
  );

  test('requests the required strict JSON response shape', () {
    final prompt = buildSanitizedPrompt(
      Household(id: 'household-id'),
      const [],
    );

    expect(prompt, contains('"score": 0'));
    expect(prompt, contains('"status": "Needs Improvement"'));
    expect(prompt, contains('"missing_items": []'));
    expect(prompt, contains('"advice": ""'));
  });
}
