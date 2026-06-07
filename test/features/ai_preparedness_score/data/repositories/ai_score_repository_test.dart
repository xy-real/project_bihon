import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/ai_preparedness_score/data/repositories/ai_score_repository.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';

void main() {
  late Directory hiveDirectory;
  late AIScoreRepository repository;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'ai_score_repository_',
    );
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AIScoreCacheAdapter());
    }

    repository = AIScoreRepository();
    await repository.initBox();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  AIScoreCache buildScore({
    int overallScore = 72,
    String status = 'Prepared',
  }) {
    return AIScoreCache(
      overallScore: overallScore,
      status: status,
      missingEssentialItems: const ['First aid kit'],
      customAdvice: 'Add essential medical supplies.',
      calculatedAt: DateTime.utc(2026, 6, 6),
    );
  }

  test('returns null when no score has been cached', () {
    expect(repository.getLatestScore(), isNull);
  });

  test('saves and replaces the latest cached score', () async {
    await repository.saveScore(buildScore());
    await repository.saveScore(
      buildScore(overallScore: 84, status: 'Highly Prepared'),
    );

    final stored = repository.getLatestScore();

    expect(stored, isNotNull);
    expect(stored!.overallScore, 84);
    expect(stored.status, 'Highly Prepared');
    expect(
      Hive.box<AIScoreCache>(AIScoreCache.boxName)
          .containsKey(AIScoreCache.latestScoreKey),
      isTrue,
    );
  });

  test('listenable notifies when the latest score changes', () async {
    final listenable = repository.getListenable();
    var notificationCount = 0;
    void listener() {
      notificationCount++;
    }

    listenable.addListener(listener);
    await repository.saveScore(buildScore());
    listenable.removeListener(listener);

    expect(notificationCount, greaterThan(0));
    expect(
      listenable.value.get(AIScoreCache.latestScoreKey)?.overallScore,
      72,
    );
  });

  test('clear removes the cached score for tests', () async {
    await repository.saveScore(buildScore());

    await repository.clear();

    expect(repository.getLatestScore(), isNull);
  });
}
