import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('ai_score_cache_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AIScoreCacheAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('stores and restores the latest AI preparedness score', () async {
    final calculatedAt = DateTime.utc(2026, 6, 6, 10, 30);
    final score = AIScoreCache(
      overallScore: 72,
      status: 'Prepared',
      missingEssentialItems: const [
        'Battery-powered radio',
        'First aid kit',
      ],
      customAdvice: 'Add communication and medical supplies.',
      calculatedAt: calculatedAt,
    );

    final box = await Hive.openBox<AIScoreCache>(AIScoreCache.boxName);
    await box.put(AIScoreCache.latestScoreKey, score);
    await box.close();

    final reopenedBox =
        await Hive.openBox<AIScoreCache>(AIScoreCache.boxName);
    final stored = reopenedBox.get(AIScoreCache.latestScoreKey);

    expect(AIScoreCacheAdapter().typeId, 6);
    expect(stored, isNotNull);
    expect(stored!.overallScore, 72);
    expect(stored.status, 'Prepared');
    expect(
      stored.missingEssentialItems,
      ['Battery-powered radio', 'First aid kit'],
    );
    expect(
      stored.customAdvice,
      'Add communication and medical supplies.',
    );
    expect(stored.calculatedAt, calculatedAt);
  });
}
