/// Utility functions for normalizing risk tags used in the Location-Specific Warning System.
///
/// Risk tags must be normalized to a canonical format:
/// - Lowercase
/// - Whitespace trimmed
/// - Spaces and hyphens replaced with underscores
/// - Deduplicated when processing lists

/// Normalizes a single risk tag string to canonical format.
///
/// The normalization process:
/// 1. Trims leading and trailing whitespace
/// 2. Converts to lowercase
/// 3. Replaces spaces and hyphens with underscores
///
/// Example:
/// ```dart
/// normalizeRiskTag('  Flood-Prone  ') // Returns: 'flood_prone'
/// normalizeRiskTag('LANDSLIDE PRONE') // Returns: 'landslide_prone'
/// ```
String normalizeRiskTag(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('-', '_');
}

/// Normalizes a list of risk tags and removes duplicates.
///
/// This function:
/// 1. Applies [normalizeRiskTag] to each item
/// 2. Removes duplicate entries
/// 3. Filters out empty strings
/// 4. Returns a new List&lt;String&gt;
///
/// Example:
/// ```dart
/// normalizeRiskTags(['Flood-Prone', 'flood_prone', 'COASTAL'])
/// // Returns: ['flood_prone', 'coastal']
/// ```
List<String> normalizeRiskTags(List<String> raw) {
  final normalized = raw
      .map(normalizeRiskTag)
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
  return normalized;
}
