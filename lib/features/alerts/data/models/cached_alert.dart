import 'package:hive/hive.dart';

part 'cached_alert.g.dart';

@HiveType(typeId: 2)
class CachedAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String severity;

  @HiveField(3)
  final String source;

  @HiveField(4)
  final String advisoryType;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final DateTime publishedAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final DateTime? expiresAt;

  @HiveField(9)
  final bool isActive;

  /// List of normalized risk tags (e.g., 'coastal', 'flood_prone', 'landslide_prone').
  /// Defaults to empty list if null.
  @HiveField(10)
  final List<String> riskTags;

  @HiveField(11)
  final String? region;

  @HiveField(12)
  final List<String> affectedAreas;

  @HiveField(13)
  final double? latitude;

  @HiveField(14)
  final double? longitude;

  CachedAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.source,
    required this.advisoryType,
    required this.content,
    required this.publishedAt,
    required this.updatedAt,
    this.expiresAt,
    required this.isActive,
    List<String>? riskTags,
    this.region,
    List<String>? affectedAreas,
    this.latitude,
    this.longitude,
  })  : riskTags = riskTags ?? const [],
        affectedAreas = affectedAreas ?? const [];
}
