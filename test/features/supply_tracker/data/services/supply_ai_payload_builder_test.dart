import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/services/supply_ai_payload_builder.dart';

void main() {
  test('buildPayload aggregates supply inventory for AI input', () {
    final now = DateTime.now();
    final items = [
      SupplyItem(
        id: '1',
        name: 'Rice',
        category: 'Food',
        quantity: 5,
        expirationDate: now.add(const Duration(days: 20)),
      ),
      SupplyItem(
        id: '2',
        name: 'Canned Tuna',
        category: 'Food',
        quantity: 3,
        expirationDate: now.add(const Duration(days: 3)),
      ),
      SupplyItem(
        id: '3',
        name: 'Medicines',
        category: 'Medical',
        quantity: 1,
        expirationDate: now.subtract(const Duration(days: 1)),
      ),
    ];

    final payload = SupplyAiPayloadBuilder.buildPayload(
      householdId: 'home-1',
      items: items,
    );

    expect(payload['household_id'], 'home-1');

    final inventory = payload['inventory'] as Map<String, dynamic>;
    expect(inventory['total_items'], 3);
    expect(inventory['total_quantity'], 9);
    expect(inventory['expired_count'], 1);
    expect(inventory['expiring_soon_count'], 1);

    final categoryTotals = inventory['category_totals'] as Map<String, int>;
    expect(categoryTotals['Food'], 8);
    expect(categoryTotals['Medical'], 1);
  });
}
