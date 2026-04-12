import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/shared/models/household.dart';

/// Repository for managing Household data in Hive.
///
/// Handles all read/write operations for the household profile, including
/// loading, saving, and updating the risk_classification field.
class HouseholdRepository {
  static const String boxName = 'household_box';
  static const String defaultHouseholdId = 'default_household';
  static const String riskClassificationKey = 'risk_classification';

  late Box<Household> _box;

  /// Initialize the household Hive box.
  ///
  /// Must be called once during app startup after Hive.initFlutter().
  Future<void> initBox() async {
    _box = await Hive.openBox<Household>(boxName);
  }

  /// Get the default household, creating it if it doesn't exist.
  ///
  /// If the household box is empty, a new default household is created
  /// with risk_classification = 'unknown'.
  Future<Household> getOrCreateHousehold() async {
    if (_box.isEmpty) {
      final defaultHousehold = Household(
        id: defaultHouseholdId,
        risk_classification: 'unknown',
      );
      await _box.put(defaultHouseholdId, defaultHousehold);
      return defaultHousehold;
    }

    return _box.get(defaultHouseholdId) ??
        Household(
          id: defaultHouseholdId,
          risk_classification: 'unknown',
        );
  }

  /// Get the current household from Hive.
  ///
  /// Returns null if the household doesn't exist.
  Household? getHousehold() {
    return _box.get(defaultHouseholdId);
  }

  /// Get the current risk_classification, or 'unknown' if not set.
  String getRiskClassification() {
    final household = getHousehold();
    return household?.risk_classification ?? 'unknown';
  }

  /// Update only the risk_classification field of the household.
  ///
  /// Creates the household if it doesn't exist, preserving other fields.
  /// Returns the updated household.
  Future<Household> updateRiskClassification(String riskClassification) async {
    final household = await getOrCreateHousehold();
    final updated = Household(
      id: household.id,
      risk_classification: riskClassification,
    );
    await _box.put(defaultHouseholdId, updated);
    return updated;
  }

  /// Clear all household data from Hive.
  ///
  /// Used for testing or when user resets their profile.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Check if a household exists in Hive.
  bool exists() {
    return _box.containsKey(defaultHouseholdId);
  }
}
