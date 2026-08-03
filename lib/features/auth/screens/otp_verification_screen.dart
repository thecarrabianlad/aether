import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, OtpType;

import 'package:aether/core/services/auth_service.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/auth/widgets/otp_input.dart';
import 'package:aether/widgets/common/glass_card.dart';

/// Which auth flow the OTP screen is verifying.
enum OtpFlow { signup, recovery }

/// 6-digit email OTP entry, used for signup confirmation and password
/// recovery. Auto-verifies once all digits are entered.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpFlow flow;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.flow,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpKey = GlobalKey<OtpInputState>();

  bool _isVerifying = false;
  int _cooldown = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify(String code) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      await AuthService.instance.verifyOtp(
        email: widget.email,
        token: code,
        type: widget.flow == OtpFlow.signup ? OtpType.signup : OtpType.recovery,
      );
      _otpKey.currentState?.showSuccess();
      // Let the success animation play before navigating. The router's
      // redirect deliberately leaves this screen alone after the session
      // appears, so this delay is safe.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.go(widget.flow == OtpFlow.signup ? '/' : '/reset-password');
    } on AuthException catch (e) {
      _otpKey.currentState?.shakeError();
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    try {
      if (widget.flow == OtpFlow.signup) {
        await AuthService.instance
            .resendOtp(email: widget.email, type: OtpType.signup);
      } else {
        // GoTrue's resend() doesn't support recovery — re-request instead.
        await AuthService.instance.resetPassword(widget.email);
      }
      if (mounted) _startCooldown();
    } on AuthException catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.aether.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final canResend = _cooldown == 0;

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
                widget.flow == OtpFlow.signup
                    ? 'Verify your email'
                    : 'Reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(color: aether.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: aether.textMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
                child: Column(
                    children: [
                      OtpInput(
                        key: _otpKey,
                        onCompleted: _verify,
                        enabled: !_isVerifying,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 20,
                        child: _isVerifying
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: aether.accent,
                                ),
                              )
                            : Text(
                                'The code expires shortly — enter it soon.',
                                style: TextStyle(
                                  color: aether.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend ? 'RESEND CODE' : 'RESEND IN ${_cooldown}s',
                  style: TextStyle(
                    color: canResend ? aether.accent : aether.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Wrong email? ',
                      style: TextStyle(color: aether.textMuted)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Back to Sign In',
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
}
