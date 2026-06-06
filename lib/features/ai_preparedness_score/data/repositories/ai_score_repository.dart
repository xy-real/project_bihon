import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';

class AIScoreRepository {
  late Box<AIScoreCache> _box;

  Future<void> initBox() async {
    _box = Hive.isBoxOpen(AIScoreCache.boxName)
        ? Hive.box<AIScoreCache>(AIScoreCache.boxName)
        : await Hive.openBox<AIScoreCache>(AIScoreCache.boxName);
  }

  AIScoreCache? getLatestScore() {
    return _box.get(AIScoreCache.latestScoreKey);
  }

  Future<void> saveScore(AIScoreCache score) async {
    await _box.put(AIScoreCache.latestScoreKey, score);
  }

  ValueListenable<Box<AIScoreCache>> getListenable() {
    return _box.listenable(keys: const [AIScoreCache.latestScoreKey]);
  }

  @visibleForTesting
  Future<void> clear() async {
    await _box.clear();
  }
}
