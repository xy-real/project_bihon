import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/services/supply_ai_payload_builder.dart';

class SupplyRepository {
  static const String _boxName = 'supply_box';
  late Box<SupplyItem> _box;

  /// Initialize the Hive box. Call this once at app startup.
  Future<void> initBox() async {
    _box = await Hive.openBox<SupplyItem>(_boxName);
  }

  /// Get all items as a list.
  List<SupplyItem> getAllItems() {
    return _box.values.toList();
  }

  /// Get all items associated with one household.
  List<SupplyItem> getItemsForHousehold(String householdId) {
    return _box.values.where((item) => item.householdId == householdId).toList();
  }

  /// Build an anonymized inventory payload intended for AI readiness scoring.
  Map<String, dynamic> buildAiInventoryPayload({
    String householdId = SupplyItem.defaultHouseholdId,
  }) {
    return SupplyAiPayloadBuilder.buildPayload(
      householdId: householdId,
      items: getItemsForHousehold(householdId),
    );
  }

  /// Get a ValueListenable for reactive updates in the UI.
  ValueListenable<Box<SupplyItem>> getItemsListenable() {
    return _box.listenable();
  }

  /// Add a new item to the box.
  Future<void> addItem(SupplyItem item) async {
    await _box.add(item);
  }

  /// Update an existing item in the box.
  Future<void> updateItem(int index, SupplyItem item) async {
    await _box.putAt(index, item);
  }

  /// Delete an item from the box by index.
  Future<void> deleteItem(int index) async {
    await _box.deleteAt(index);
  }

  /// Delete an item by its ID.
  Future<void> deleteItemById(String id) async {
    final index = _box.values.toList().indexWhere((item) => item.id == id);
    if (index != -1) {
      await _box.deleteAt(index);
    }
  }

  /// Clear all items from the box.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Close the box when the app is closing.
  Future<void> closeBox() async {
    await _box.close();
  }
}
