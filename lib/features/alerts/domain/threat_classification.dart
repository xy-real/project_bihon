import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/utils/risk_tag_utils.dart';

const Set<String> _directRiskClassifications = {
  'coastal',
  'flood_prone',
  'landslide_prone',
};

/// Categorizes alerts into threat bands based on household risk profile.
enum ThreatBand {
  /// Alert directly matches the household's risk classification.
  /// Should be pinned at the top with high-contrast styling.
  direct,

  /// Alert is relevant but does not match the household's risk classification.
  /// Shown below direct threats with standard styling.
  general,
}

/// Normalizes household risk values before matching them against alert tags.
///
/// The current household model supports coastal, flood_prone,
/// landslide_prone, and unknown. Unsupported values such as urban are mapped
/// to unknown so they stay general advisories instead of creating accidental
/// direct-threat matches.
String normalizeHouseholdRiskClassification(String riskClassification) {
  final normalized = normalizeRiskTag(riskClassification);
  return _directRiskClassifications.contains(normalized)
      ? normalized
      : 'unknown';
}

/// Classifies whether an alert is a direct threat or general advisory.
ThreatBand classifyThreat(
  CachedAlert alert,
  String householdRiskClassification,
) {
  final normalizedHouseholdRisk =
      normalizeHouseholdRiskClassification(householdRiskClassification);
  if (normalizedHouseholdRisk == 'unknown') {
    return ThreatBand.general;
  }

  final hasMatch = alert.riskTags.contains(normalizedHouseholdRisk);
  return hasMatch ? ThreatBand.direct : ThreatBand.general;
}

/// Calculates a numeric weight for alert severity.
///
/// Mapping:
/// - high -> 3
/// - medium -> 2
/// - all others, including low -> 1
int severityWeight(String severity) {
  switch (severity.toLowerCase()) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    default:
      return 1;
  }
}

/// Sorts alerts by threat band and secondary criteria.
///
/// Sort order:
/// 1. Direct threats first, general advisories second.
/// 2. Within each band, severity weight descending.
/// 3. Within equal severity, publishedAt descending.
/// 4. Exact ties preserve input order.
List<CachedAlert> sortAlerts(
  List<CachedAlert> alerts,
  String householdRiskClassification,
) {
  final indexedAlerts = [
    for (var index = 0; index < alerts.length; index++)
      _IndexedAlert(index: index, alert: alerts[index]),
  ];

  indexedAlerts.sort((aEntry, bEntry) {
    final a = aEntry.alert;
    final b = bEntry.alert;

    final aBand = classifyThreat(a, householdRiskClassification);
    final bBand = classifyThreat(b, householdRiskClassification);
    final bandComparison = aBand.index.compareTo(bBand.index);
    if (bandComparison != 0) {
      return bandComparison;
    }

    final aWeight = severityWeight(a.severity);
    final bWeight = severityWeight(b.severity);
    final weightComparison = bWeight.compareTo(aWeight);
    if (weightComparison != 0) {
      return weightComparison;
    }

    final publishedComparison = b.publishedAt.compareTo(a.publishedAt);
    if (publishedComparison != 0) {
      return publishedComparison;
    }

    return aEntry.index.compareTo(bEntry.index);
  });

  return [
    for (final entry in indexedAlerts) entry.alert,
  ];
}

class _IndexedAlert {
  const _IndexedAlert({
    required this.index,
    required this.alert,
  });

  final int index;
  final CachedAlert alert;
}
