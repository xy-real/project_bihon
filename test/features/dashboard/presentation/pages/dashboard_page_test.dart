import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_service.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/category_grid.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';

void main() {
  const pumpSlice = Duration(milliseconds: 500);

  DashboardSnapshot sampleSnapshot() {
    return DashboardSnapshot(
      supplies: [
        SupplyItem(
          id: 'supply-1',
          name: 'Bottled Water',
          category: 'Water',
          quantity: 12,
          expirationDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ],
      contacts: [
        Contact(
          id: 'contact-1',
          name: 'John Doe',
          phoneNumber: '09171234567',
          type: 'Family',
        ),
        Contact(
          id: 'contact-2',
          name: 'Barangay Captain',
          phoneNumber: '09181234567',
          type: 'Barangay Official',
        ),
      ],
      alerts: [
        CachedAlert(
          id: 'alert-1',
          title: 'High Wind Warning',
          severity: 'high',
          source: 'PAGASA',
          advisoryType: 'Wind',
          content: 'Secure loose outdoor items.',
          publishedAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          isActive: true,
          riskTags: const ['coastal'],
        ),
      ],
      centers: [
        CachedEvacCenter(
          id: 'center-1',
          name: 'Baybay City Gym',
          latitude: 10,
          longitude: 124,
          capacity: 120,
          status: 'Open',
        ),
      ],
      aiScore: AIScoreCache(
        overallScore: 82,
        status: 'Prepared',
        missingEssentialItems: const ['Battery-powered radio'],
        customAdvice: 'Add communication supplies.',
        calculatedAt: DateTime(2026, 6, 7),
      ),
    );
  }

  Map<String, WidgetBuilder> featureRoutes() {
    return {
      '/alerts': (_) => const Scaffold(body: Text('Alerts Route')),
      '/evacuation-centers': (_) =>
          const Scaffold(body: Text('Evacuation Route')),
      '/supplies': (_) => const Scaffold(body: Text('Supplies Route')),
      '/contacts': (_) => const Scaffold(body: Text('Contacts Route')),
      '/safety-status': (_) => const Scaffold(body: Text('Safety Route')),
      PreparednessCategoryGridPage.routeName: (_) =>
          const Scaffold(body: Text('Guides Route')),
    };
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    DashboardSnapshot? snapshot,
    Future<AIScoreCalculationResult> Function()? onRecalculateScore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage.fromSnapshot(
          snapshot: snapshot ?? sampleSnapshot(),
          onRecalculateScore: onRecalculateScore,
        ),
        routes: featureRoutes(),
      ),
    );
    await tester.pump(pumpSlice);
  }

  testWidgets('renders Stitch dashboard sections with local summaries',
      (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(pumpSlice);
    });

    await pumpDashboard(tester);

    expect(find.text('Your Preparedness Score'), findsOneWidget);
    expect(find.text('Prepared'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('Last updated 2026-06-07'), findsOneWidget);
    expect(find.text('1 of 12 essential supplies'), findsOneWidget);
    expect(find.text('2 family contacts added'), findsOneWidget);
    expect(find.text('1 active alert'), findsOneWidget);
    expect(find.text('High Wind Warning'), findsOneWidget);
    expect(find.text('1 evac centers'), findsOneWidget);
    expect(find.text('1 open center available'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Barangay Captain'), findsOneWidget);
  });

  testWidgets('dashboard cards and actions preserve feature navigation',
      (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(pumpSlice);
    });

    await pumpDashboard(tester);

    for (final entry in <String, String>{
      '1 active alert': 'Alerts Route',
      '1 evac centers': 'Evacuation Route',
      '1 supplies expiring': 'Supplies Route',
      'Improve Now ->': 'Guides Route',
      'View All': 'Contacts Route',
      'Send Safety Status': 'Safety Route',
      'Call Emergency': 'Contacts Route',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pump(pumpSlice);
      await tester.pump(pumpSlice);
      expect(find.text(entry.value), findsOneWidget);
      Navigator.of(tester.element(find.text(entry.value))).pop();
      await tester.pump(pumpSlice);
      await tester.pump(pumpSlice);
    }
  });

  testWidgets('report incident uses safe unavailable fallback', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(pumpSlice);
    });

    await pumpDashboard(tester, snapshot: const DashboardSnapshot());

    await tester.ensureVisible(find.text('Report Incident'));
    await tester.tap(find.text('Report Incident'));
    await tester.pump(pumpSlice);

    expect(
      find.text('Report incident is not available yet.'),
      findsOneWidget,
    );
  });

  testWidgets('shows score fallback without recalculating on build',
      (tester) async {
    var recalculationCount = 0;

    await pumpDashboard(
      tester,
      snapshot: const DashboardSnapshot(),
      onRecalculateScore: () async {
        recalculationCount++;
        return AIScoreCalculationResult.failed(cachedScore: null);
      },
    );

    expect(find.text('--'), findsOneWidget);
    expect(find.text('Calculate your preparedness score'), findsOneWidget);
    expect(find.text('Recalculate'), findsOneWidget);
    expect(recalculationCount, 0);
  });

  testWidgets('offline recalculation shows the controlled cached-score message',
      (tester) async {
    final cachedScore = sampleSnapshot().aiScore!;
    var recalculationCount = 0;

    await pumpDashboard(
      tester,
      onRecalculateScore: () async {
        recalculationCount++;
        return AIScoreCalculationResult.offline(cachedScore: cachedScore);
      },
    );

    await tester.tap(find.text('Recalculate'));
    await tester.pump();

    expect(recalculationCount, 1);
    expect(
      find.text(
        'No internet connection. Showing your cached score from 2026-06-07.',
      ),
      findsOneWidget,
    );
  });
}
