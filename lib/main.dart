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
import 'package:aether/widgets/boot_splash.dart';
import 'package:aether/widgets/common/error_state.dart';

import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // Everything that touches Flutter bindings and runApp must happen
  // inside the same zone.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Show the boot splash immediately before any async work.
      runApp(const BootSplash());

      // Global Flutter error handler.
      FlutterError.onError = (details) {
        AppLogger.instance.error(
          details.exception,
          code: 'FLUTTER',
          context: {
            'library': details.library ?? 'unknown',
            'stack': details.stack
                    ?.toString()
                    .split('\n')
                    .take(8)
                    .join(' | ') ??
                'unknown',
          },
        );

        if (kDebugMode) {
          FlutterError.presentError(details);
        }
      };

      // Global platform-level error handler.
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.instance.error(
          error,
          code: 'PLATFORM',
          context: {
            'stack': stack.toString().split('\n').take(8).join(' | '),
          },
        );

        // Returning true means the error was handled.
        return true;
      };

      // Custom rendering error screen for release builds.
      if (kReleaseMode) {
        ErrorWidget.builder = (details) {
          return const ColoredBox(
            color: Color(0xFF0D0D0D),
            child: ErrorStateView(
              exception: UnknownError(
                message:
                    'Something went wrong rendering this screen. '
                    'Restart the app; if it keeps happening, contact '
                    'support with the code shown below.',
                action: AppErrorAction.support,
                ref: 'RENDER',
              ),
            ),
          );
        };
      }

      // Perform application initialization.
      await _runApp();
    },
    (error, stack) {
      AppLogger.instance.error(
        error,
        code: 'ZONE',
        context: {
          'stack': stack.toString().split('\n').take(8).join(' | '),
        },
      );
    },
  );
}

Future<void> _runApp() async {
  try {
    // Initialize backend services.
    await SupabaseService.initialize();

    // Initialize notifications.
    await NotificationService.instance.init();

    // Load persisted settings.
    final settingsService = await SettingsService.load();

    // Replace BootSplash with the real application.
    runApp(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
        child: const AetherApp(),
      ),
    );
  } catch (error, stack) {
    AppLogger.instance.error(
      error,
      code: 'BOOT',
      context: {
        'stack': stack.toString().split('\n').take(8).join(' | '),
      },
    );

    // If initialization fails, show a proper error screen.
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAetherTheme(const AppThemeState()),
        home: const _BootErrorScreen(),
      ),
    );
  }
}

/// Fallback shown when startup initialization fails
/// (missing .env, corrupt DB, etc.).
class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ErrorStateView(
          exception: UnknownError(
            message:
                'AETHER couldn\'t start. Restart the app; if it persists, '
                'contact support.',
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
