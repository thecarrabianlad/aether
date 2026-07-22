import 'package:flutter_test/flutter_test.dart';
import 'package:aether/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AetherApp());
    // Verify the app renders without errors
    expect(find.byType(AetherApp), findsOneWidget);
  });
}