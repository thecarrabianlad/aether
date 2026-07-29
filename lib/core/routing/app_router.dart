import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import 'package:aether/features/auth/screens/login_screen.dart';
import 'package:aether/features/auth/screens/profile_screen.dart';
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
      final authenticating = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn && !authenticating) return '/login';
      if (loggedIn && authenticating) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      // Full-screen page without the bottom navbar shell.
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesScreen(),
      ),
      GoRoute(
        path: '/past-papers',
        builder: (context, state) => const PastPapersScreen(),
      ),
      GoRoute(
        path: '/pomodoro',
        builder: (context, state) => const PomodoroScreen(),
      ),
      GoRoute(
        path: '/flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: '/academics',
            builder: (context, state) => const AcademicsScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/habit-detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HabitDetailScreen(habitId: id);
            },
          ),
          GoRoute(
            path: '/habits/calendar',
            builder: (context, state) => const HabitsCalendarScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => const HealthScreen(),
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
