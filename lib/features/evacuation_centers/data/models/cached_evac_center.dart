import 'package:hive/hive.dart';

part 'cached_evac_center.g.dart';

/// Locally cached evacuation center record synced from Supabase.
/// TypeId 3 is confirmed available (0=SupplyItem, 1=Contact, 2=CachedAlert, 4=Household).
@HiveType(typeId: 3)
class CachedEvacCenter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final int capacity;

  /// One of: "Open", "Near Capacity", "Full", "Closed"
  @HiveField(5)
  final String status;

  CachedEvacCenter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.status,
  });

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}
