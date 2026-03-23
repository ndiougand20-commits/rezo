import 'package:flutter_test/flutter_test.dart';

import 'package:rezo/main.dart';

void main() {
  testWidgets('Ping screen renders expected elements', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ticket 3.4 - API /ping'), findsOneWidget);
    expect(find.text('Tester GET /ping'), findsOneWidget);
    expect(find.text('Resultat'), findsOneWidget);
  });
}
