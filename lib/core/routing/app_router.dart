import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/routing/aether_page.dart';
import 'package:aether/widgets/common/error_state.dart';
import 'package:aether/features/auth/screens/login_screen.dart';
import 'package:aether/features/auth/screens/otp_verification_screen.dart';
import 'package:aether/features/auth/screens/profile_screen.dart';
import 'package:aether/features/auth/screens/reset_password_screen.dart';
import 'package:aether/features/auth/screens/signup_screen.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/screens/home_screen.dart';
import 'package:aether/features/academics/screens/academics_screen.dart';
import 'package:aether/features/notes/screens/notes_screen.dart';
import 'package:aether/features/past_papers/screens/past_papers_screen.dart';
import 'package:aether/features/pomodoro/screens/pomodoro_screen.dart';
import 'package:aether/features/flashcards/screens/flashcards_screen.dart';
import 'package:aether/features/habits/screens/habit_detail_screen.dart';
import 'package:aether/features/habits/screens/habits_calendar_screen.dart';
import 'package:aether/features/habits/screens/habits_screen.dart';
import 'package:aether/screens/health/health_screen.dart';
import 'package:aether/features/settings/screens/settings_screen.dart';
import 'package:aether/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = AuthService.instance;
  final isLoggedIn = authService.isLoggedIn;

  return GoRouter(
    initialLocation: isLoggedIn ? '/' : '/login',
    refreshListenable: _GoRouterRefreshStream(authService),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authService.isLoggedIn;
      final loc = state.matchedLocation;

      // Routes reachable without a session.
      const unauthenticatedRoutes = {'/login', '/signup', '/verify-otp'};

      // /verify-otp is useless without an email to verify.
      if (loc == '/verify-otp' &&
          (state.uri.queryParameters['email'] ?? '').isEmpty) {
        return '/login';
      }

      // /reset-password is intentionally NOT unauthenticated — it needs the
      // session created by the recovery OTP verify, so a cold visit without
      // a session correctly falls through to /login here.
      if (!loggedIn && !unauthenticatedRoutes.contains(loc)) return '/login';

      // Only bounce login/signup when authenticated. /verify-otp stays put
      // after verifyOTP creates a session so its success animation can play
      // and the recovery flow can reach /reset-password uninterrupted.
      if (loggedIn && (loc == '/login' || loc == '/signup')) return '/';

      return null;
    },
    // Unknown routes get a graceful "Page not found" instead of a blank
    // screen. The user always has an answer (Go home).
    errorBuilder: (context, state) => const ErrorStateView(
      exception: NotFoundError(
        message: 'Page not found.',
        action: AppErrorAction.retry,
      ),
    ),
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: OtpVerificationScreen(
            email: state.uri.queryParameters['email'] ?? '',
            flow: state.uri.queryParameters['flow'] == 'recovery'
                ? OtpFlow.recovery
                : OtpFlow.signup,
          ),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const ResetPasswordScreen(),
        ),
      ),
      // Full-screen routes outside the bottom navbar shell.
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notes',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const NotesScreen(),
        ),
      ),
      GoRoute(
        path: '/past-papers',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const PastPapersScreen(),
        ),
      ),
      GoRoute(
        path: '/pomodoro',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const PomodoroScreen(),
        ),
      ),
      GoRoute(
        path: '/flashcards',
        pageBuilder: (context, state) => AetherPage(
          key: state.pageKey,
          name: state.name,
          child: const FlashcardsScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/academics',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const AcademicsScreen(),
            ),
          ),
          GoRoute(
            path: '/habits',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const HabitsScreen(),
            ),
          ),
          GoRoute(
            path: '/habit-detail/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return AetherPage(
                key: state.pageKey,
                name: state.name,
                child: HabitDetailScreen(habitId: id),
              );
            },
          ),
          GoRoute(
            path: '/habits/calendar',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const HabitsCalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/health',
            pageBuilder: (context, state) => AetherPage(
              key: state.pageKey,
              name: state.name,
              child: const HealthScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Refreshes the router only when the logged-in state actually flips.
/// Supabase emits auth events on startup and token refresh too — reacting
/// to those re-ran every redirect and rebuilt the shell for no reason.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(AuthService authService)
      : _wasLoggedIn = authService.isLoggedIn {
    _subscription = authService.onAuthStateChange.listen((AuthState _) {
      final loggedIn = authService.isLoggedIn;
      if (loggedIn != _wasLoggedIn) {
        _wasLoggedIn = loggedIn;
        notifyListeners();
      }
    });
  }

  bool _wasLoggedIn;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
