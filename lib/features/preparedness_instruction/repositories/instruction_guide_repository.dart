import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';
import 'package:project_bihon/features/preparedness_instruction/seed/seed_guides.dart';

class InstructionGuideRepository {
  static const String boxName = 'guide_box';

  late Box<InstructionGuide> _box;

  Future<void> initBox() async {
    try {
      _box = await Hive.openBox<InstructionGuide>(boxName);
    } catch (e) {
      debugPrint('[InstructionGuideRepository] Error opening guide_box: $e');
      debugPrint('[InstructionGuideRepository] Clearing corrupted Hive box and retrying');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        _box = await Hive.openBox<InstructionGuide>(boxName);
        debugPrint('[InstructionGuideRepository] Guide box successfully recovered');
      } catch (e2) {
        debugPrint('[InstructionGuideRepository] Fatal error recovering guide_box: $e2');
        rethrow;
      }
    }
  }

  Future<void> seedIfNeeded() async {
    if (_box.isNotEmpty) {
      return;
    }

    final seed = getSeedGuides();
    await _box.putAll({for (final guide in seed) guide.id: guide});
  }

  List<InstructionGuide> getAllGuides() {
    return _box.values.toList();
  }

  InstructionGuide? getGuideById(String id) {
    return _box.get(id);
  }

  List<String> getCompletedGuideIds() {
    return _box.values
        .where((guide) => guide.isRead)
        .map((guide) => guide.id)
        .toList()
      ..sort();
  }

  ValueListenable<Box<InstructionGuide>> getGuidesListenable() {
    return _box.listenable();
  }

  Future<void> markGuideRead(String id) async {
    final guide = _box.get(id);
    if (guide == null || guide.isRead) {
      return;
    }

    await _box.put(id, guide.copyWith(isRead: true));
  }

  Future<void> saveGuide(InstructionGuide guide) async {
    await _box.put(guide.id, guide);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> closeBox() async {
    await _box.close();
  }
}
