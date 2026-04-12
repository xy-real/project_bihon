import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/alert_card_factory.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/direct_threat_alert_card.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/general_advisory_alert_card.dart';

void main() {
  final baseTime = DateTime(2026, 4, 10, 12, 0, 0);

  CachedAlert createTestAlert({
    String id = 'test_alert',
    String title = 'Test Alert',
    String severity = 'High',
    String content = 'This is a test alert content',
    String advisoryType = 'Typhoon',
    DateTime? publishedAt,
  }) {
    return CachedAlert(
      id: id,
      title: title,
      severity: severity,
      source: 'PAGASA',
      advisoryType: advisoryType,
      content: content,
      publishedAt: publishedAt ?? baseTime,
      updatedAt: baseTime,
      isActive: true,
    );
  }

  group('DirectThreatAlertCard', () {
    testWidgets('renders with standard alert data', (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('Test Alert'), findsOneWidget);
      expect(find.text('This is a test alert content'), findsOneWidget);
      expect(find.text('HIGH RISK FOR YOUR AREA'), findsOneWidget);
    });

    testWidgets('renders warning icon', (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays severity badge', (WidgetTester tester) async {
      final alert = createTestAlert(severity: 'High');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('handles empty title gracefully', (WidgetTester tester) async {
      final alert = createTestAlert(title: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget); // Default fallback
    });

    testWidgets('handles empty content gracefully', (WidgetTester tester) async {
      final alert = createTestAlert(content: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('No additional details available'), findsOneWidget);
    });

    testWidgets('handles empty severity gracefully',
        (WidgetTester tester) async {
      final alert = createTestAlert(severity: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('UNKNOWN'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(
              alert: alert,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('displays "More Details" button when onMoreDetails provided',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(
              alert: alert,
              onMoreDetails: () {},
            ),
          ),
        ),
      );

      expect(find.text('More Details'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not display "More Details" button when onMoreDetails is null',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.text('More Details'), findsNothing);
    });

    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('Test Alert'), findsOneWidget);
    });

    testWidgets('formats published date correctly',
        (WidgetTester tester) async {
      final alert = createTestAlert(
        publishedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectThreatAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      // Should contain a time ago format
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data?.contains('ago') == true,
        ),
        findsWidgets,
      );
    });
  });

  group('GeneralAdvisoryAlertCard', () {
    testWidgets('renders with standard alert data', (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('Test Alert'), findsOneWidget);
      expect(find.text('This is a test alert content'), findsOneWidget);
      expect(find.text('General Baybay City Advisory'), findsOneWidget);
    });

    testWidgets('displays advisory type', (WidgetTester tester) async {
      final alert = createTestAlert(advisoryType: 'Typhoon');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.text('Typhoon'), findsOneWidget);
    });

    testWidgets('handles empty title gracefully', (WidgetTester tester) async {
      final alert = createTestAlert(title: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget);
    });

    testWidgets('handles empty content gracefully', (WidgetTester tester) async {
      final alert = createTestAlert(content: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('No additional details available'), findsOneWidget);
    });

    testWidgets('handles empty advisory type gracefully',
        (WidgetTester tester) async {
      final alert = createTestAlert(advisoryType: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('Advisory'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(
              alert: alert,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('displays "More Details" button when onMoreDetails provided',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(
              alert: alert,
              onMoreDetails: () {},
            ),
          ),
        ),
      );

      expect(find.text('More Details'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: GeneralAdvisoryAlertCard(alert: alert),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('General Baybay City Advisory'), findsOneWidget);
    });
  });

  group('AlertCardFactory', () {
    testWidgets('buildAlertCard returns DirectThreatAlertCard for direct threat',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      final card =
          buildAlertCard(alert: alert, threatBand: ThreatBand.direct);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.text('HIGH RISK FOR YOUR AREA'), findsOneWidget);
    });

    testWidgets('buildAlertCard returns GeneralAdvisoryAlertCard for general threat',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      final card =
          buildAlertCard(alert: alert, threatBand: ThreatBand.general);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
      expect(find.text('General Baybay City Advisory'), findsOneWidget);
    });

    testWidgets('AlertCardFactory widget renders DirectThreatAlertCard',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertCardFactory(
              alert: alert,
              threatBand: ThreatBand.direct,
            ),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
    });

    testWidgets('AlertCardFactory widget renders GeneralAdvisoryAlertCard',
        (WidgetTester tester) async {
      final alert = createTestAlert();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertCardFactory(
              alert: alert,
              threatBand: ThreatBand.general,
            ),
          ),
        ),
      );

      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
    });

    testWidgets('factory passes onTap callback correctly',
        (WidgetTester tester) async {
      bool tapped = false;
      final alert = createTestAlert();
      final card = buildAlertCard(
        alert: alert,
        threatBand: ThreatBand.direct,
        onTap: () {
          tapped = true;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('factory passes onMoreDetails callback correctly',
        (WidgetTester tester) async {
      bool detailsTapped = false;
      final alert = createTestAlert();
      final card = buildAlertCard(
        alert: alert,
        threatBand: ThreatBand.general,
        onMoreDetails: () {
          detailsTapped = true;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: card,
          ),
        ),
      );

      await tester.tap(find.text('More Details'));
      expect(detailsTapped, isTrue);
    });

    testWidgets('both card types handle long text gracefully',
        (WidgetTester tester) async {
      final longText =
          'A' * 200; // Create a very long string
      final alert = createTestAlert(
        title: longText,
        content: longText,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DirectThreatAlertCard(alert: alert),
                  GeneralAdvisoryAlertCard(alert: alert),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DirectThreatAlertCard), findsOneWidget);
      expect(find.byType(GeneralAdvisoryAlertCard), findsOneWidget);
    });
  });
}
