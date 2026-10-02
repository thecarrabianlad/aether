import 'package:aether/core/errors/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger ref codes', () {
    test('generates 6-char base32 codes from valid alphabet', () {
      final log = AppLogger.instance;
      final allowed = RegExp(r'^[A-HJKMNP-Z2-9]{6}$');
      for (var i = 0; i < 50; i++) {
        expect(log.generateRef(), matches(allowed));
      }
    });

    test('no ambiguous chars (I, L, O, 0, 1)', () {
      final log = AppLogger.instance;
      for (var i = 0; i < 100; i++) {
        expect(log.generateRef(), isNot(contains(RegExp('[ILO01]'))));
      }
    });
  });

  group('AppLogger redaction', () {
    test('redacts JWT-like tokens', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0'
          '.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      expect(AppLogger.instance.redact('token=$jwt'), contains('<redacted>'));
      expect(AppLogger.instance.redact('token=$jwt'), isNot(contains(jwt)));
    });

    test('redacts password= occurrences', () {
      final out = AppLogger.instance.redact('password=hunter2 cause: x');
      expect(out, isNot(contains('hunter2')));
      expect(out, contains('<redacted>'));
    });

    test('does not mangle plain prose', () {
      final out = AppLogger.instance.redact(
        'habit sync failed, 3 rows queued',
      );
      expect(out, contains('habit sync failed'));
    });
  });

  group('AppLogger ring buffer', () {
    test('logs errors with ref codes and caps at maxEntries', () {
      final log = AppLogger.instance;
      for (var i = 0; i < 250; i++) {
        log.error(StateError('failure #$i'), code: 'TEST');
      }
      expect(log.ring.length, lessThanOrEqualTo(log.maxEntries));
      expect(log.ring.length, log.maxEntries);
    });

    test('entry renders a structured line with code and ref', () {
      final log = AppLogger.instance;
      final ref = log.generateRef();
      log.route = '/habits';
      final code = log.error(StateError('boom'), code: 'AE-NF01', ref: ref);
      expect(code, ref);
      final line = log.ring.last.toLine();
      expect(line, contains('[ERR]'));
      expect(line, contains('AE-NF01'));
      expect(line, contains('ref=$ref'));
      expect(line, contains('@/habits'));
    });

    test('debug entries do not consume ref codes', () {
      final log = AppLogger.instance;
      log.debug('sync ok', code: 'DBG');
      expect(log.ring.last.level, 'DBG');
      expect(log.ring.last.ref, isNull);
    });
  });
}
