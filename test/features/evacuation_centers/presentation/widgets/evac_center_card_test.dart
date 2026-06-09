import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evac_center_card.dart';

void main() {
  testWidgets('shows center details and actions without status or capacity', (
    tester,
  ) async {
    var directionsPressed = false;
    var callPressed = false;
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
                distanceMeters: 2400,
                onViewDirections: () => directionsPressed = true,
                onCall: () => callPressed = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(center.name), findsOneWidget);
    expect(find.text('2.4 km away'), findsOneWidget);
    expect(find.text('VIEW DIRECTIONS'), findsOneWidget);
    expect(find.text('CALL'), findsOneWidget);
    expect(find.text('NEAR CAPACITY'), findsNothing);
    expect(find.text('Capacity'), findsNothing);
    expect(find.text('80%'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    final directions = find.text('VIEW DIRECTIONS');
    final call = find.text('CALL');
    expect(
      tester.getTopLeft(call).dy,
      greaterThan(tester.getTopLeft(directions).dy),
    );

    await tester.tap(directions);
    await tester.tap(call);
    expect(directionsPressed, isTrue);
    expect(callPressed, isTrue);
  });
}
