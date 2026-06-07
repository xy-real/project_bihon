import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';

void main() {
  SupplyItem buildItem(DateTime expirationDate) {
    return SupplyItem(
      id: 'supply-id',
      name: 'Bottled Water',
      category: 'Water',
      quantity: 1,
      expirationDate: expirationDate,
    );
  }

  test('an item expiring today remains valid for the full calendar day', () {
    final now = DateTime.now();
    final item = buildItem(DateTime(now.year, now.month, now.day));

    expect(item.isExpired, isFalse);
    expect(item.expiresSoon, isTrue);
  });

  test('an item with a date before today is expired', () {
    final item = buildItem(DateTime.now().subtract(const Duration(days: 1)));

    expect(item.isExpired, isTrue);
    expect(item.expiresSoon, isFalse);
  });
}
