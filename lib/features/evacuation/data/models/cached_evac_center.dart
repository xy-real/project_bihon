import 'package:hive/hive.dart';

part 'cached_evac_center.g.dart';

@HiveType(typeId: 4)
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
}
