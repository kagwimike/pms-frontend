// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pms_pro/main.dart';
import 'package:pms_pro/providers/auth_provider.dart';

void main() {
  testWidgets('PMS Pro boots into the public home screen', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('RentPro KE'), findsWidgets);
  });
}
