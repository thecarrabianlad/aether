import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/features/auth/screens/login_screen.dart';
import 'package:aether/features/auth/screens/signup_screen.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/screens/home_screen.dart';
import 'package:aether/features/academics/screens/academics_screen.dart';
import 'package:aether/features/habits/screens/habits_screen.dart';
import 'package:aether/features/health/screens/health_screen.dart';
import 'package:aether/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = AuthService.instance;
  final isLoggedIn = authService.isLoggedIn;

  return GoRouter(
    initialLocation: isLoggedIn ? '/' : '/login',
    refreshListenable: _GoRouterRefreshStream(authService.onAuthStateChange),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authService.isLoggedIn;
      final authenticating =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

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
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
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
            path: '/health',
            builder: (context, state) => const HealthScreen(),
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
