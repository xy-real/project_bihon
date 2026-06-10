import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_service.dart';
import 'package:project_bihon/features/ai_preparedness_score/ui/ai_score_detail_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required ValueNotifier<AIScoreCache?> scoreNotifier,
    Future<AIScoreCalculationResult> Function()? onRecalculate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AIScoreDetailScreen(
          scoreListenable: scoreNotifier,
          onRecalculate: onRecalculate,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders cached score, advice, and missing items', (tester) async {
    final scoreNotifier = ValueNotifier<AIScoreCache?>(_score());
    addTearDown(scoreNotifier.dispose);

    await pumpScreen(tester, scoreNotifier: scoreNotifier);

    expect(find.text('Preparedness Advice'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('Prepared'), findsOneWidget);
    expect(find.text('Calculated 2026-06-07'), findsOneWidget);
    expect(
      find.text('Add communication and medical supplies.'),
      findsOneWidget,
    );
    expect(find.text('Battery-powered radio'), findsOneWidget);
    expect(find.text('First aid kit'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });

  testWidgets('does not recalculate automatically and shows empty state',
      (tester) async {
    var recalculationCount = 0;
    final scoreNotifier = ValueNotifier<AIScoreCache?>(null);
    addTearDown(scoreNotifier.dispose);

    await pumpScreen(
      tester,
      scoreNotifier: scoreNotifier,
      onRecalculate: () async {
        recalculationCount++;
        return AIScoreCalculationResult.failed(cachedScore: null);
      },
    );

    expect(find.text('No preparedness score yet'), findsOneWidget);
    expect(find.text('Calculate Score'), findsOneWidget);
    expect(recalculationCount, 0);
  });

  testWidgets('offline recalculation keeps cached content and shows message',
      (tester) async {
    final cachedScore = _score();
    final scoreNotifier = ValueNotifier<AIScoreCache?>(cachedScore);
    addTearDown(scoreNotifier.dispose);

    await pumpScreen(
      tester,
      scoreNotifier: scoreNotifier,
      onRecalculate: () async {
        return AIScoreCalculationResult.offline(cachedScore: cachedScore);
      },
    );

    await tester.ensureVisible(find.text('Recalculate'));
    await tester.pump();
    await tester.tap(find.text('Recalculate'));
    await tester.pump();

    expect(find.text('78%'), findsOneWidget);
    expect(
      find.textContaining(
        'No internet connection. Showing your cached score from 2026-06-07.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('successful recalculation rebuilds from the Hive cache',
      (tester) async {
    final scoreNotifier = ValueNotifier<AIScoreCache?>(_score());
    addTearDown(scoreNotifier.dispose);
    final updatedScore = AIScoreCache(
      overallScore: 91,
      status: 'Highly Prepared',
      missingEssentialItems: const [],
      customAdvice: 'Maintain and rotate your supplies.',
      calculatedAt: DateTime.utc(2026, 6, 8),
    );

    await pumpScreen(
      tester,
      scoreNotifier: scoreNotifier,
      onRecalculate: () async {
        scoreNotifier.value = updatedScore;
        return AIScoreCalculationResult.success(updatedScore);
      },
    );

    await tester.ensureVisible(find.text('Recalculate'));
    await tester.pump();
    await tester.tap(find.text('Recalculate'));
    await tester.pump();
    await tester.pump();

    expect(find.text('91%'), findsOneWidget);
    expect(find.text('Highly Prepared'), findsOneWidget);
    expect(find.text('Maintain and rotate your supplies.'), findsOneWidget);
    expect(find.text('No missing essentials were identified.'), findsOneWidget);
  });
}

AIScoreCache _score() {
  return AIScoreCache(
    overallScore: 78,
    status: 'Prepared',
    missingEssentialItems: const [
      'Battery-powered radio',
      'First aid kit',
    ],
    customAdvice: 'Add communication and medical supplies.',
    calculatedAt: DateTime.utc(2026, 6, 7),
  );
}
