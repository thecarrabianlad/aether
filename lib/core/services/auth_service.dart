import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase email/password authentication.
///
/// All methods throw [AuthException] with a user-readable `message`
/// on failure — screens catch it and surface it in a snackbar.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> signUp({required String email, required String password}) async {
    await _auth.signUp(email: email, password: password);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Verifies a 6-digit email OTP. [type] is [OtpType.signup] or
  /// [OtpType.recovery]. On success Supabase creates a session.
  Future<void> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    await _auth.verifyOTP(email: email, token: token, type: type);
  }

  /// Re-sends a signup confirmation OTP. Note: GoTrue's resend() does not
  /// support [OtpType.recovery] — recovery codes are re-sent by calling
  /// [resetPassword] again.
  Future<void> resendOtp({required String email, required OtpType type}) async {
    await _auth.resend(type: type, email: email);
  }

  /// Sets a new password for the currently-authenticated user
  /// (used by the password-recovery flow after the OTP verify).
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
