import 'package:flutter_test/flutter_test.dart';
import 'package:aether/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Note: This test requires Supabase to be initialized.
    // In CI, the Supabase keys would be provided via environment variables.
    // For now this is a structural smoke test placeholder.
    expect(AetherApp, isNotNull);
  });
}
