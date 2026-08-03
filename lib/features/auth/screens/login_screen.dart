import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/auth/widgets/auth_textfield.dart';
import 'package:aether/widgets/common/app_snackbar.dart';
import 'package:aether/widgets/common/progress_button.dart';
import 'package:aether/widgets/common/shake.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthError {
  credentials,
  notConfirmed,
  sessionExpired,
  rateLimited,
  unknown,
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingReset = false;
  _AuthError? _lastAuthError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _lastAuthError = null);
      showAetherSnackbar(context,
          message: 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastAuthError = null;
    });
    try {
      await AuthService.instance.signIn(email: email, password: password);
      // Navigation is automatic via the router's auth redirect.
    } on Exception catch (e) {
      final classified = e is AppException ? e : classify(e);
      setState(() {
        _lastAuthError = switch (classified.code) {
          'AE-AUTH01' => _AuthError.credentials,
          'AE-AUTH02' => _AuthError.notConfirmed,
          'AE-AUTH03' => _AuthError.sessionExpired,
          'AE-AUTH04' => _AuthError.rateLimited,
          _ => _AuthError.unknown,
        };
      });
      showAetherErrorSnackbar(context, classified);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_isSendingReset) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showAetherSnackbar(context, message: 'Enter your email above first.');
      return;
    }
    setState(() => _isSendingReset = true);
    try {
      await AuthService.instance.resetPassword(email);
      if (mounted) {
        context.go('/verify-otp?flow=recovery&email=${Uri.encodeComponent(email)}');
      }
    } on Exception catch (e) {
      final classified = classify(e);
      showAetherErrorSnackbar(context, classified);
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;

    return Scaffold(
      backgroundColor: aether.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                'AETHER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 6,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(color: aether.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 60),
              ShakeWidget(
                trigger: _lastAuthError,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'EMAIL ADDRESS',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _errorForField(_AuthError.notConfirmed),
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      label: 'PASSWORD',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
                      errorText: _errorForField(_AuthError.credentials),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _isSendingReset
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white38),
                      )
                    : GestureDetector(
                        onTap: _forgotPassword,
                        child: Text(
                          'FORGOT PASSWORD?',
                          style: TextStyle(
                            color: aether.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              ProgressButton(
                label: 'CONTINUE',
                isPending: _isLoading,
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: aether.textMuted)),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text('Sign Up',
                        style: TextStyle(
                            color: aether.accent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _errorForField(_AuthError target) {
    if (_lastAuthError == target) {
      return switch (target) {
        _AuthError.credentials => 'Email or password is incorrect',
        _AuthError.notConfirmed => 'Check your inbox to confirm this email',
        _AuthError.sessionExpired => 'Session expired',
        _AuthError.rateLimited => 'Too many attempts — try again soon',
        _AuthError.unknown => 'Something went wrong',
      };
    }
    return null;
  }
}