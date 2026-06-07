import 'package:hive/hive.dart';

part 'supply_item.g.dart';

@HiveType(typeId: 0)
class SupplyItem extends HiveObject {
  static const String defaultHouseholdId = 'default_household';

  @HiveField(0)
  final String id;

  @HiveField(1)
  String name; // e.g., "Canned Tuna", "Bottled Water"

  @HiveField(2)
  String category; // e.g., "Food", "Water", "Medical", "Tools"

  @HiveField(3)
  int quantity;

  @HiveField(4)
  DateTime expirationDate;

  @HiveField(5)
  String? imageUrl;

  @HiveField(6)
  String householdId;

  SupplyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expirationDate,
    this.imageUrl,
    this.householdId = defaultHouseholdId,
  });

  // Expiration dates are calendar dates, so an item remains valid all day.
  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return expirationDay.isBefore(today);
  }

  bool get expiresSoon {
    if (isExpired) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return expirationDay.difference(today).inDays <= 7;
  }
}
