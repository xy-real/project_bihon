import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/shared/models/household.dart';

/// Repository for managing Household data in Hive.
///
/// Handles all read/write operations for the household profile, including
/// loading, saving, and updating the risk_classification field.
class HouseholdRepository {
  static const String boxName = 'household_box';
  static const String settingsBoxName = 'household_settings_box';
  static const String defaultHouseholdId = 'default_household';
  static const String riskClassificationKey = 'risk_classification';
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding';

  late Box<Household> _box;
  late Box<bool> _settingsBox;

  /// Initialize the household Hive box.
  ///
  /// Must be called once during app startup after Hive.initFlutter().
  /// If the box contains corrupt or incompatible data, it will be cleared.
  Future<void> initBox() async {
    try {
      _box = await Hive.openBox<Household>(boxName);
    } catch (e) {
      debugPrint('[HouseholdRepository] Error opening household_box: $e');
      debugPrint('[HouseholdRepository] Clearing corrupted Hive box and retrying');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        _box = await Hive.openBox<Household>(boxName);
        debugPrint('[HouseholdRepository] Household box successfully recovered');
      } catch (e2) {
        debugPrint('[HouseholdRepository] Fatal error recovering household_box: $e2');
        rethrow;
      }
    }

    try {
      _settingsBox = await Hive.openBox<bool>(settingsBoxName);
    } catch (e) {
      debugPrint(
        '[HouseholdRepository] Error opening household_settings_box: $e',
      );
      debugPrint(
        '[HouseholdRepository] Clearing corrupted settings box and retrying',
      );
      try {
        await Hive.deleteBoxFromDisk(settingsBoxName);
        _settingsBox = await Hive.openBox<bool>(settingsBoxName);
        debugPrint(
          '[HouseholdRepository] Household settings box successfully recovered',
        );
      } catch (e2) {
        debugPrint(
          '[HouseholdRepository] Fatal error recovering settings box: $e2',
        );
        rethrow;
      }
    }
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

  /// Whether the first-install household location onboarding has completed.
  bool hasCompletedOnboarding() {
    return _settingsBox.get(hasCompletedOnboardingKey) ?? false;
  }

  /// Persist first-install onboarding completion state.
  Future<void> setOnboardingCompleted({bool completed = true}) async {
    await _settingsBox.put(hasCompletedOnboardingKey, completed);
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
    await _settingsBox.clear();
  }

  /// Check if a household exists in Hive.
  bool exists() {
    return _box.containsKey(defaultHouseholdId);
  }
}
