import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/features/auth/screens/login_screen.dart';
import 'package:aether/features/auth/screens/signup_screen.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/screens/home_screen.dart';
import 'package:aether/features/academics/screens/academics_screen.dart';
import 'package:aether/screens/habits/habits_screen.dart';
import 'package:aether/screens/health/health_screen.dart';
import 'package:aether/widgets/bottom_navbar.dart';
import 'package:aether/main.dart'; // To get MainScaffold

final routerProvider = Provider<GoRouter>((ref) {
  final authService = AuthService.instance;

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(authService.onAuthStateChange),
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authService.isLoggedIn;
      final isAuthenticating =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthenticating) return '/login';
      if (isLoggedIn && isAuthenticating) return '/';

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
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
