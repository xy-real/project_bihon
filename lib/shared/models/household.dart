import 'package:hive/hive.dart';

part 'household.g.dart';

/// Canonical risk classification values for a household location.
const List<String> validRiskClassifications = [
  'coastal',
  'flood_prone',
  'landslide_prone',
  'unknown',
];

@HiveType(typeId: 4)
class Household extends HiveObject {
  /// Unique identifier for the household.
  @HiveField(0)
  final String id;

  /// Risk classification based on household location.
  /// Allowed values: 'coastal', 'flood_prone', 'landslide_prone', 'unknown'.
  /// Defaults to 'unknown' if not set.
  @HiveField(1)
  // ignore: non_constant_identifier_names
  final String risk_classification;

  Household({
    required this.id,
    // ignore: non_constant_identifier_names
    String risk_classification = 'unknown',
  }) : risk_classification = validRiskClassifications.contains(risk_classification)
            ? risk_classification
            : 'unknown';
}
