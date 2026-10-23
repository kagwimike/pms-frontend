import 'package:flutter_test/flutter_test.dart';
import 'package:pms_pro_frontend/main.dart';

void main() {
  testWidgets('PMS Pro app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PmsProApp());
    expect(find.byType(PmsProApp), findsOneWidget);
  });
}
