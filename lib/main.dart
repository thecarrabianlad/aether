import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/errors/app_logger.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/core/routing/app_router.dart';
import 'package:aether/core/services/notification_service.dart';
import 'package:aether/core/services/settings_service.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/widgets/common/error_state.dart';
import 'package:aether/widgets/boot_splash.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the boot splash BEFORE any async work — the user never sees a
  // blank screen.
  runApp(const BootSplash());

  // Global safety net: no uncaught error may crash the app or white-screen.
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      AppLogger.instance.error(
        details.exception,
        code: 'FLUTTER',
        context: {
          'library': details.library ?? 'unknown',
          'stack': details.stack.toString().split('\n').take(8).join(' | '),
        },
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.instance.error(error, code: 'PLATFORM', context: {
        'stack': stack.toString().split('\n').take(8).join(' | '),
      });
      return true; // handled — do not crash the process
    };
    if (kReleaseMode) {
      ErrorWidget.builder = (details) => const ColoredBox(
            color: Color(0xFF0D0D0D),
            child: ErrorStateView(
              exception: UnknownError(
                message: 'Something went wrong rendering this screen. '
                    'Restart the app; if it keeps happening, contact '
                    'support with the code shown below.',
                action: AppErrorAction.support,
                ref: 'RENDER',
              ),
            ),
          );
    }
    _runApp();
  }, (error, stack) {
    AppLogger.instance.error(error, code: 'ZONE', context: {
      'stack': stack.toString().split('\n').take(8).join(' | '),
    });
  });
}

Future<void> _runApp() async {
  try {
    await SupabaseService.initialize();
    await NotificationService.instance.init();
    final settingsService = await SettingsService.load();

    // Swap from BootSplash to the real app.
    runApp(ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const AetherApp(),
    ));
  } catch (error, stack) {
    AppLogger.instance.error(error, code: 'BOOT', context: {
      'stack': stack.toString().split('\n').take(8).join(' | '),
    });
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAetherTheme(const AppThemeState()),
        home: const _BootErrorScreen(),
      ),
    );
  }
}

/// Fallback shown when startup init fails (missing .env, corrupt DB, etc.).
class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ErrorStateView(
          exception: UnknownError(
            message: 'AETHER couldn\'t start. Restart the app; if it '
                'persists, contact support.',
            action: AppErrorAction.support,
            ref: 'BOOT',
          ),
        ),
      ),
    );
  }
}

class AetherApp extends ConsumerWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeControllerProvider);

    // Hook the router so notification taps can navigate.
    NotificationService.router = router;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AETHER',
      theme: buildAetherTheme(themeState),
      routerConfig: router,
    );
  }
}
