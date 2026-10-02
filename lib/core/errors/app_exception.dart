import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:http/http.dart' show ClientException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single next-step a user can take for an error.
///
/// [AppException.userMessage] and [AppException.action] are always non-null —
/// the "user always has an answer" guarantee is structural: an unclassified
/// error can only become [UnknownError], which supplies both by construction.
enum AppErrorAction {
  /// No user action needed — recovery is automatic (e.g. queued retry).
  none,

  /// Offer a retry button that re-runs the operation.
  retry,

  /// Tell the user to check their connection; offer a retry button.
  checkConnection,

  /// Re-enter credentials (auth flow).
  reauthenticate,

  /// Guide the user to a support/restart path with a reference code.
  support,

  /// Open system settings (notifications, permissions).
  openSettings,
}

/// Every failure the app surfaces, classified. [message] is plain language
/// with a concrete next step — never a raw exception string or stack trace.
sealed class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.action,
    required this.retryable,
    this.cause,
    this.ref,
  });

  /// Stable app-level code, e.g. `AE-AUTH01`. Never shown to the user
  /// except as part of a reference code on the support fallback.
  final String code;

  /// Human-readable, no jargon. Always includes a next step.
  final String message;

  /// What the user can do next (never `null`).
  final AppErrorAction action;

  /// Whether retrying the same operation has a chance of succeeding.
  final bool retryable;

  /// The raw exception that produced this one, for logging.
  final Object? cause;

  /// 6-char base32 reference code for support; shown to the user when
  /// [action] is [AppErrorAction.support], always logged.
  final String? ref;

  AppException copyWith({String? ref}) {
    return switch (this) {
      ValidationError e => e.copyWith(ref: ref),
      AuthError e => e.copyWith(ref: ref),
      NetworkError e => e.copyWith(ref: ref),
      TimeoutError e => e.copyWith(ref: ref),
      SyncError e => e.copyWith(ref: ref),
      PermissionError e => e.copyWith(ref: ref),
      NotFoundError e => e.copyWith(ref: ref),
      ServerError e => e.copyWith(ref: ref),
      StorageError e => e.copyWith(ref: ref),
      UnknownError e => e.copyWith(ref: ref),
    };
  }

  @override
  String toString() =>
      'AppException($code${ref == null ? '' : ' ref=$ref'}) — $message';
}

/// Client-side or server-side input validation failure.
final class ValidationError extends AppException {
  const ValidationError({
    super.code = 'AE-VAL01',
    required super.message,
    super.action = AppErrorAction.none,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  ValidationError copyWith({String? ref}) => ValidationError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Authentication failure: bad credentials, unconfirmed email, session
/// expiry, or auth rate limiting.
final class AuthError extends AppException {
  const AuthError({
    super.code = 'AE-AUTH01',
    required super.message,
    super.action = AppErrorAction.reauthenticate,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  AuthError copyWith({String? ref}) => AuthError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// No connection / request could not be delivered.
final class NetworkError extends AppException {
  const NetworkError({
    super.code = 'AE-NET01',
    required super.message,
    super.action = AppErrorAction.checkConnection,
    super.retryable = true,
    super.cause,
    super.ref,
  });

  NetworkError copyWith({String? ref}) => NetworkError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Request exceeded its time budget.
final class TimeoutError extends AppException {
  const TimeoutError({
    super.code = 'AE-NET02',
    required super.message,
    super.action = AppErrorAction.retry,
    super.retryable = true,
    super.cause,
    super.ref,
  });

  TimeoutError copyWith({String? ref}) => TimeoutError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Sync push/pull failure, or a permanently-failing queued row.
final class SyncError extends AppException {
  const SyncError({
    super.code = 'AE-SYNC01',
    required super.message,
    super.action = AppErrorAction.retry,
    super.retryable = true,
    super.cause,
    super.ref,
  });

  SyncError copyWith({String? ref}) => SyncError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Missing OS permission (notifications, storage).
final class PermissionError extends AppException {
  const PermissionError({
    super.code = 'AE-NTF01',
    required super.message,
    super.action = AppErrorAction.openSettings,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  PermissionError copyWith({String? ref}) => PermissionError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// The requested thing does not exist (route, record, resource).
final class NotFoundError extends AppException {
  const NotFoundError({
    super.code = 'AE-NF01',
    required super.message,
    super.action = AppErrorAction.retry,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  NotFoundError copyWith({String? ref}) => NotFoundError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// The remote server failed (5xx) or the user is forbidden (403).
final class ServerError extends AppException {
  const ServerError({
    super.code = 'AE-SRV01',
    required super.message,
    super.action = AppErrorAction.retry,
    super.retryable = true,
    super.cause,
    super.ref,
  });

  ServerError copyWith({String? ref}) => ServerError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Local database / storage failure.
final class StorageError extends AppException {
  const StorageError({
    super.code = 'AE-DB01',
    required super.message,
    super.action = AppErrorAction.support,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  StorageError copyWith({String? ref}) => StorageError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Anything the classifier could not map. Guarantees a message + action
/// with a reference code (the "always an answer" fallback).
final class UnknownError extends AppException {
  const UnknownError({
    super.code = 'AE-UNK01',
    required super.message,
    super.action = AppErrorAction.support,
    super.retryable = false,
    super.cause,
    super.ref,
  });

  UnknownError copyWith({String? ref}) => UnknownError(
        code: code,
        message: message,
        action: action,
        retryable: retryable,
        cause: cause,
        ref: ref ?? this.ref,
      );
}

/// Classifies raw exceptions into [AppException]s.
///
/// Pure function, no I/O, no async — trivially unit-testable. Never throws;
/// anything unclassified becomes [UnknownError] (with [fallbackRef] attached
/// if supplied, else no ref — callers generate one via [AppLogger]).
AppException classify(Object error, {String? fallbackRef}) {
  if (error is AppException) return error;

  // ── Supabase auth ─────────────────────────────────────────────
  if (error is AuthException) {
    final code = error.code ?? '';
    final status = error.statusCode;
    final lower = (error.message + ' $code').toLowerCase();

    if (status == '429' || lower.contains('rate limit') || lower.contains('too many')) {
      return const AuthError(
        code: 'AE-AUTH04',
        message: 'Too many attempts. Please wait a moment and try again.',
        action: AppErrorAction.retry,
      );
    }
    // Session expiry / refresh-token failures take precedence over
    // generic credential errors (a 401 can carry either meaning).
    if (status == '401' ||
        lower.contains('expired') ||
        lower.contains('refresh_token_not_found') ||
        lower.contains('session')) {
      return const AuthError(
        code: 'AE-AUTH03',
        message: 'Your session expired. Please sign in again.',
        action: AppErrorAction.reauthenticate,
      );
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid_credentials') ||
        lower.contains('invalid credentials')) {
      return const AuthError(
        code: 'AE-AUTH01',
        message: 'Email or password is incorrect.',
        action: AppErrorAction.reauthenticate,
      );
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return const AuthError(
        code: 'AE-AUTH02',
        message: 'Check your inbox and confirm your email before signing in.',
        action: AppErrorAction.retry,
      );
    }
    if (lower.contains('weak password') || lower.contains('password')) {
      return AuthError(
        code: 'AE-AUTH05',
        message: 'Your password is too weak. Try a longer one.',
        action: AppErrorAction.retry,
        cause: error,
      );
    }
    if (lower.contains('user already registered') ||
        lower.contains('email exists')) {
      return const AuthError(
        code: 'AE-AUTH06',
        message: 'An account already exists for that email.',
        action: AppErrorAction.none,
      );
    }
    // Unmapped auth failure → auth-flavored unknown.
    return UnknownError(
      code: 'AE-AUTH99',
      message: 'Sign-in hit a snag. Try again.',
      action: AppErrorAction.retry,
      retryable: true,
      cause: error,
      ref: fallbackRef,
    );
  }

  // ── Supabase PostgREST ────────────────────────────────────────
  if (error is PostgrestException) {
    final code = error.code ?? '';
    final lower = code.toLowerCase();
    if (code == '401' || lower.contains('jwt') && lower != 'pgrst301') {
      return const AuthError(
        code: 'AE-AUTH03',
        message: 'Your session expired. Please sign in again.',
        action: AppErrorAction.reauthenticate,
      );
    }
    if (code == '403' ||
        code == '42501' ||
        lower.contains('permission denied') ||
        lower.contains('row level security')) {
      return const AuthError(
        code: 'AE-AUTHZ1',
        message: "You don't have access to that.",
        action: AppErrorAction.none,
      );
    }
    if (code == '404' || code == 'PGRST116' || lower.contains('not found')) {
      return NotFoundError(
        code: 'AE-NF01',
        message: "That item no longer exists — it may have been deleted on another device.",
        action: AppErrorAction.retry,
        cause: error,
      );
    }
    // 5xx (or any 400+ not matched above) → server error.
    final intCode = int.tryParse(code) ?? 0;
    if (intCode >= 500 || code == 'PGRST301' || code.isEmpty) {
      return ServerError(
        code: 'AE-SRV01',
        message: "Our servers are having trouble. Your data is safe on this device.",
        action: AppErrorAction.retry,
        cause: error,
      );
    }
    return ServerError(
      code: 'AE-SRV01',
      message: "Something went wrong on our end. Try again.",
      action: AppErrorAction.retry,
      cause: error,
    );
  }

  // ── Network / timeouts ────────────────────────────────────────
  if (error is SocketException) {
    return NetworkError(
      code: 'AE-NET01',
      message: 'No connection. Check your internet and try again.',
      action: AppErrorAction.checkConnection,
      cause: error,
    );
  }
  if (error is TimeoutException) {
    return TimeoutError(
      code: 'AE-NET02',
      message: "The server is taking too long. Your data is safe on this device.",
      action: AppErrorAction.retry,
      cause: error,
    );
  }
  if (error is ClientException) {
    return NetworkError(
      code: 'AE-NET01',
      message: 'No connection. Check your internet and try again.',
      action: AppErrorAction.checkConnection,
      cause: error,
    );
  }
  if (error is HandshakeException) {
    return NetworkError(
      code: 'AE-NET01',
      message: 'No connection. Check your internet and try again.',
      action: AppErrorAction.checkConnection,
      cause: error,
    );
  }

  // ── Local database ────────────────────────────────────────────
  if (error is SqliteException || error is DriftWrappedException) {
    return StorageError(
      code: 'AE-DB01',
      message: 'Something went wrong saving on this device. Restart the app; '
          'if it persists, contact support with code AE-DB01${fallbackRef == null ? '' : '-$fallbackRef'}.',
      action: AppErrorAction.support,
      cause: error,
      ref: fallbackRef,
    );
  }

  // ── Flutter framework / anything else ─────────────────────────
  if (error is FlutterError) {
    return UnknownError(
      code: 'AE-UNK01',
      message: 'Something went wrong. Try again — if it keeps happening, '
          'contact support with code AE-UNK01${fallbackRef == null ? '' : '-$fallbackRef'}.',
      action: AppErrorAction.support,
      cause: error,
      ref: fallbackRef,
    );
  }

  return UnknownError(
    code: 'AE-UNK01',
    message: 'Something went wrong. Try again — if it keeps happening, '
        'contact support with code AE-UNK01${fallbackRef == null ? '' : '-$fallbackRef'}.',
    action: AppErrorAction.support,
    cause: error,
    ref: fallbackRef,
  );
}
