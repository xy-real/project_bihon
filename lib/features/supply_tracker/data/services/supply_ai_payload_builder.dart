import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';

class SupplyAiPayloadBuilder {
  static Map<String, dynamic> buildPayload({
    required String householdId,
    required List<SupplyItem> items,
  }) {
    final categoryTotals = <String, int>{};
    var totalQuantity = 0;
    var expiredCount = 0;
    var expiringSoonCount = 0;

    for (final item in items) {
      totalQuantity += item.quantity;
      categoryTotals.update(item.category, (value) => value + item.quantity,
          ifAbsent: () => item.quantity);

      if (item.isExpired) {
        expiredCount += 1;
      } else if (item.expiresSoon) {
        expiringSoonCount += 1;
      }
    }

    return {
      'household_id': householdId,
      'inventory': {
        'total_items': items.length,
        'total_quantity': totalQuantity,
        'expired_count': expiredCount,
        'expiring_soon_count': expiringSoonCount,
        'category_totals': categoryTotals,
      },
    };
  }
}
