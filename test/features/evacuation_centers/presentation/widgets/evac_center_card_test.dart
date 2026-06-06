import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evac_center_card.dart';

void main() {
  testWidgets('lays out center content and actions without exceptions', (
    tester,
  ) async {
    final center = CachedEvacCenter(
      id: 'center-1',
      name: 'VSU Convention Center Evacuation Center',
      latitude: 10.7435,
      longitude: 124.7935,
      capacity: 80,
      status: 'Near Capacity',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: EvacCenterCard(
                center: center,
                onViewDirections: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(center.name), findsOneWidget);
    expect(find.text('NEAR CAPACITY'), findsOneWidget);
    expect(find.text('VIEW DIRECTIONS'), findsOneWidget);
    expect(find.text('CALL'), findsOneWidget);
  });
}
