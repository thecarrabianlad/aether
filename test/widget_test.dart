import 'package:aether/core/providers.dart';
import 'package:aether/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aether/main.dart';

void main() {
  late SettingsService settingsService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    settingsService = await SettingsService.load();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const AetherApp(),
    ));
    // Let animate timers register, then pump one frame so they don't
    // leak past widget-tree disposal.
    await tester.pump();
    // Verify the app renders without errors.
    expect(find.byType(AetherApp), findsOneWidget);
    // Dispose the tree now (pumpWidget doesn't auto-dispose), to clean up
    // timers started by components using flutter_animate / AnimationController.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
