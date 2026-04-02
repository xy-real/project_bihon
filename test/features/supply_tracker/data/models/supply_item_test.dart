import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';

void main() {
  test('SupplyItem defaults householdId when not provided', () {
    final item = SupplyItem(
      id: '1',
      name: 'Water',
      category: 'Water',
      quantity: 2,
      expirationDate: DateTime.now().add(const Duration(days: 30)),
    );

    expect(item.householdId, SupplyItem.defaultHouseholdId);
  });
}
