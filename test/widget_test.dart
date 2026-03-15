import 'package:flutter_test/flutter_test.dart';

import 'package:project_bihon/main.dart';

void main() {
  testWidgets('Starter page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Project Bihon Starter'), findsOneWidget);
    expect(find.text('Start Coding Here'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
  });
}
