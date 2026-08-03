import 'dart:async';
import 'dart:io';

import 'package:aether/core/errors/app_exception.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('classify — pass-through', () {
    test('returns AppException unchanged', () {
      const ex = AuthError(message: 'x', action: AppErrorAction.retry);
      expect(classify(ex), same(ex));
    });
  });

  group('classify — auth', () {
    test('invalid credentials (400)', () {
      final e = classify(AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH01');
      expect(e.action, AppErrorAction.reauthenticate);
      expect(e.retryable, isFalse);
    });

    test('email not confirmed', () {
      final e = classify(AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH02');
    });

    test('session expired / refresh token not found', () {
      final e = classify(AuthException(
        'Refresh Token Not Found',
        statusCode: '401',
        code: 'refresh_token_not_found',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH03');
      expect(e.action, AppErrorAction.reauthenticate);
    });

    test('rate limited (429)', () {
      final e = classify(AuthException(
        'Rate limit exceeded',
        statusCode: '429',
        code: 'over_request_rate_limit',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH04');
      expect(e.action, AppErrorAction.retry);
    });

    test('weak password → AE-AUTH05', () {
      final e = classify(AuthException(
        'Password should be at least 6 characters.',
        statusCode: '422',
        code: 'weak_password',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH05');
    });

    test('user already registered → AE-AUTH06', () {
      final e = classify(AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH06');
    });

    test('unmapped auth → auth-flavored unknown, never throws', () {
      final e = classify(AuthException('mystery auth error', statusCode: '418'));
      expect(e, isA<UnknownError>());
      expect(e.code, 'AE-AUTH99');
      expect(e.action, AppErrorAction.retry);
    });
  });

  group('classify — Postgrest', () {
    test('401 jwt → session expired', () {
      final e = classify(const PostgrestException(
        message: 'JWT expired',
        code: 'JWT expired',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTH03');
      expect(e.action, AppErrorAction.reauthenticate);
    });

    test('403 → forbidden', () {
      final e = classify(const PostgrestException(
        message: 'permission denied for table',
        code: '42501',
      ));
      expect(e, isA<AuthError>());
      expect(e.code, 'AE-AUTHZ1');
    });

    test('404 → not found', () {
      final e = classify(const PostgrestException(
        message: 'JSON object requested, multiple rows returned',
        code: 'PGRST116',
      ));
      expect(e, isA<NotFoundError>());
      expect(e.code, 'AE-NF01');
    });

    test('5xx → server error', () {
      final e = classify(const PostgrestException(
        message: 'internal server error',
        code: 'PGRST301',
      ));
      expect(e, isA<ServerError>());
      expect(e.code, 'AE-SRV01');
      expect(e.retryable, isTrue);
    });
  });

  group('classify — network & timeouts', () {
    test('SocketException → NetworkError, retryable', () {
      final e = classify(const SocketException('connection refused'));
      expect(e, isA<NetworkError>());
      expect(e.code, 'AE-NET01');
      expect(e.action, AppErrorAction.checkConnection);
      expect(e.retryable, isTrue);
    });

    test('TimeoutException → TimeoutError', () {
      final e = classify(TimeoutException('timed out'));
      expect(e, isA<TimeoutError>());
      expect(e.code, 'AE-NET02');
      expect(e.action, AppErrorAction.retry);
    });

    test('http ClientException → NetworkError', () {
      final e = classify(ClientException('connection closed', Uri.parse('https://x')));
      expect(e, isA<NetworkError>());
      expect(e.code, 'AE-NET01');
    });
  });

  group('classify — storage & unknown', () {
    test('SqliteException → StorageError with ref + support action', () {
      final e = classify(
        SqliteException(extendedResultCode: 13, message: 'disk I/O error'),
        fallbackRef: 'ABCDEF',
      );
      expect(e, isA<StorageError>());
      expect(e.code, 'AE-DB01');
      expect(e.action, AppErrorAction.support);
      expect(e.ref, 'ABCDEF');
      expect(e.message, contains('AE-DB01-ABCDEF'));
    });

    test('FlutterError → UnknownError with ref', () {
      final e = classify(FlutterError('Layout failed'), fallbackRef: 'ZYXWVU');
      expect(e, isA<UnknownError>());
      expect(e.code, 'AE-UNK01');
      expect(e.action, AppErrorAction.support);
      expect(e.message, contains('ZYXWVU'));
    });

    test('unrecognized → UnknownError, message + action by construction', () {
      final e = classify(StateError('boom'));
      expect(e, isA<UnknownError>());
      expect(e.code, 'AE-UNK01');
      expect(e.message, isNotEmpty);
      expect(e.action, AppErrorAction.support);
    });

    test('fallbackRef absent → no ref, no crash', () {
      final e = classify(ArgumentError('bad'));
      expect(e, isA<UnknownError>());
      expect(e.ref, isNull);
      expect(e.message, contains('AE-UNK01'));
    });
  });
}
