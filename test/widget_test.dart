import 'package:flutter_test/flutter_test.dart';

import 'package:project_bihon/main.dart';

void main() {
  testWidgets('Clean slate page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Project Bihon'), findsOneWidget);
    expect(find.text('Clean slate ready. Start building!'), findsOneWidget);
  });
}
