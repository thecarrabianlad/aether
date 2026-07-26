import 'package:aether/core/providers.dart';
import 'package:aether/core/routing/app_router.dart';
import 'package:aether/core/services/settings_service.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final settingsService = await SettingsService.load();
  runApp(ProviderScope(
    overrides: [
      settingsServiceProvider.overrideWithValue(settingsService),
    ],
    child: const AetherApp(),
  ));
}

class AetherApp extends ConsumerWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AETHER',
      theme: buildAetherTheme(themeState),
      routerConfig: router,
    );
  }
}
