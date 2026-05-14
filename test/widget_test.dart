import 'package:flutter_test/flutter_test.dart';

import 'package:wealthpath/main.dart';

void main() {
  testWidgets('home page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('WealthPath'), findsOneWidget);
    expect(find.text('My Spending'), findsOneWidget);
    expect(find.text('Budget Overview'), findsOneWidget);
  });
}
