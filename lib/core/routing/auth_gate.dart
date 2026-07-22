import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:aether/features/auth/screens/login_screen.dart';
import 'package:aether/main.dart'; // We'll get AetherApp from here

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            // User is logged in, show the main app
            return const AetherApp();
          }
        }
        // User is not logged in, show the login screen
        return const LoginScreen();
      },
    );
  }
}
