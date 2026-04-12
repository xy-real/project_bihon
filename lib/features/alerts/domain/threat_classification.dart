import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';

/// Categorizes alerts into threat bands based on household risk profile.
enum ThreatBand {
  /// Alert directly matches the household's risk classification.
  /// Should be pinned at the top with high-contrast styling.
  direct,

  /// Alert is relevant but does not match the household's risk classification.
  /// Shown below direct threats with standard styling.
  general,
}

/// Classifies whether an alert is a direct threat or general advisory for the household.
///
/// Logic:
/// - If the household has no risk classification (empty or 'unknown'), treat all alerts as general.
/// - If the alert's riskTags contains the household's risk_classification, it's a direct threat.
/// - Otherwise, it's a general advisory.
///
/// Parameters:
/// - [alert]: The alert to classify
/// - [householdRiskClassification]: The household's canonical risk classification
///   (e.g., 'coastal', 'flood_prone', 'landslide_prone', 'unknown')
///
/// Returns:
/// - [ThreatBand.direct] if the alert's riskTags matches the household's classification
/// - [ThreatBand.general] otherwise
ThreatBand classifyThreat(
  CachedAlert alert,
  String householdRiskClassification,
) {
  if (householdRiskClassification.isEmpty ||
      householdRiskClassification == 'unknown') {
    return ThreatBand.general;
  }
  final hasMatch = alert.riskTags.contains(householdRiskClassification);
  return hasMatch ? ThreatBand.direct : ThreatBand.general;
}

/// Calculates a numeric weight for alert severity.
///
/// Used for sorting alerts within the same threat band.
/// Higher weight = higher priority.
///
/// Mapping:
/// - 'high' → 3
/// - 'medium' → 2
/// - all others (including 'low') → 1
///
/// Parameters:
/// - [severity]: The severity string (case-insensitive)
///
/// Returns: Integer weight for sorting (higher = more severe)
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
/// Sort order (deterministic):
/// 1. Direct threats first, general advisories second
/// 2. Within each band:
///    a. Severity weight descending (high → medium → low)
///    b. Published date descending (newest first)
///
/// Parameters:
/// - [alerts]: The list of alerts to sort (not mutated)
/// - [householdRiskClassification]: The household's canonical risk classification
///
/// Returns: A new sorted list (original list is not modified)
///
/// Example:
/// ```dart
/// final household = Household(id: 'h1', risk_classification: 'coastal');
/// final sorted = sortAlerts(alerts, household.risk_classification);
/// // sorted[0] is the highest-priority alert
/// ```
List<CachedAlert> sortAlerts(
  List<CachedAlert> alerts,
  String householdRiskClassification,
) {
  // Create a copy to avoid mutating the input list
  final sorted = List<CachedAlert>.from(alerts);

  sorted.sort((a, b) {
    // Primary: threat band (direct first, general second)
    final aBand = classifyThreat(a, householdRiskClassification);
    final bBand = classifyThreat(b, householdRiskClassification);

    final bandComparison = aBand.index.compareTo(bBand.index);
    if (bandComparison != 0) {
      return bandComparison;
    }

    // Secondary: severity weight descending (higher weight first)
    final aWeight = severityWeight(a.severity);
    final bWeight = severityWeight(b.severity);
    final weightComparison = bWeight.compareTo(aWeight);
    if (weightComparison != 0) {
      return weightComparison;
    }

    // Tertiary: published date descending (newer first)
    return b.publishedAt.compareTo(a.publishedAt);
  });

  return sorted;
}
