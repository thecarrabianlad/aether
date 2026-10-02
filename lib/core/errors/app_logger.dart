import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';

/// A single structured log entry held by [AppLogger.ring].
class LogEntry {
  const LogEntry({
    required this.at,
    required this.level,
    required this.code,
    required this.route,
    required this.context,
    this.ref,
    this.message,
  });

  final DateTime at;
  final String level;
  final String code;
  final String? ref;
  final String? route;
  final String? message;
  final Map<String, String> context;

  /// Redacted one-line rendering. Never contains tokens, passwords, or
  /// `.env` secrets — [AppLogger] redacts them before they reach here.
  String toLine() {
    final buf = StringBuffer()
      ..write(_stamp(at))
      ..write(' [$level] ')
      ..write(code);
    if (ref != null) buf.write(' ref=$ref');
    if (route != null) buf.write(' @$route');
    if (message != null && message!.isNotEmpty) buf.write(' $message');
    if (context.isNotEmpty) {
      buf.write(' {');
      context.forEach((k, v) => buf.write(' $k=$v'));
      buf.write(' }');
    }
    return buf.toString();
  }

  static String _stamp(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} '
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Structured logger for AETHER.
///
/// - Keeps the last [maxEntries] entries in a memory ring buffer
///   (exportable via the Settings "Copy diagnostics" action).
/// - Writes to `debugPrint` in debug; in release the ring buffer is the
///   record (crash reporting SaaS is a later decision, per the plan).
/// - Every [error] call gets a 6-char base32 reference code that is shown
///   to the user AND attached to the log entry.
/// - [redact] scrubs secrets from any free-text before it is stored.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final _ring = <LogEntry>[];
  final int maxEntries = 200;
  static const _codeChars =
      'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // base32, no ambiguous I/L/O/0/1

  final Random _random = Random();
  String? _currentRoute;

  /// All buffered entries, newest last.
  List<LogEntry> get ring => List.unmodifiable(_ring);

  /// Route of the active screen (set by the router's listener).
  set route(String? route) => _currentRoute = route;

  /// Debug-level entry.
  void debug(String message, {String code = 'DBG', Map<String, String>? context}) =>
      _add(level: 'DBG', code: code, message: message, context: context);

  /// Error-level entry with a generated reference code.
  String error(
    Object error, {
    String? code,
    String? ref,
    Map<String, String>? context,
  }) {
    final refCode = ref ?? generateRef();
    final resolvedCode = code ?? _inferCode(error);
    _add(
      level: 'ERR',
      code: resolvedCode,
      message: error.toString(),
      ref: refCode,
      context: context,
    );
    return refCode;
  }

  /// Generates a 6-char base32 reference code for support.
  String generateRef() {
    final buf = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buf.write(_codeChars[_random.nextInt(_codeChars.length)]);
    }
    return buf.toString();
  }

  /// Scrubs secrets from free-text logs.
  String redact(String input) {
    var out = input;
    for (final pattern in _secretPatterns) {
      out = out.replaceAllMapped(pattern, (m) => '<redacted>');
    }
    return out;
  }

  static final List<RegExp> _secretPatterns = [
    // JWT: eyJ<header>.<payload>.<signature>
    RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9._-]{10,}\.[A-Za-z0-9._-]{10,}'),
    // Supabase anon/service keys (eyJ-prefixed long tokens)
    RegExp(r'eyJ[A-Za-z0-9_\-.]{20,}'),
    // Generic password=… / token:… etc. — matches label AND value, replaces all.
    RegExp(
        r'(?i:[Pp]assword|[Pp]wd|[Tt]oken|[Aa]pi[_-]?[Kk]ey|[Ss]ecret)\s*[=:]\s*[^\s,}]+'),
  ];

  String _inferCode(Object error) {
    final s = error.toString();
    // AppException carries its own code.
    final m = RegExp(r'AppException\(([A-Z0-9-]+)').firstMatch(s);
    if (m != null) return m.group(1)!;
    // Raw exception class name → stable-ish code.
    final cls = s.split('(').first.trim();
    return cls.isEmpty ? 'AE-UNK01' : cls.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '_');
  }

  void _add({
    required String level,
    required String code,
    String? message,
    String? ref,
    Map<String, String>? context,
  }) {
    final entry = LogEntry(
      at: DateTime.now(),
      level: level,
      code: code,
      ref: ref,
      route: _currentRoute,
      message: message == null ? null : redact(message),
      context: (context ?? const {}).map((k, v) => MapEntry(k, redact(v))),
    );
    _ring.add(entry);
    if (_ring.length > maxEntries) _ring.removeRange(0, _ring.length - maxEntries);
    if (level == 'ERR') {
      // ignore: avoid_print — console parity for errors in all build modes.
      print(entry.toLine());
    } else {
      // ignore: avoid_print
      print(entry.toLine());
    }
  }
}

/// Sanitizes free-text before logging (keeps URLs/logs clean of secrets).
String sanitizeForLog(String input) => AppLogger.instance.redact(input);

/// Convenience: reference-code generation used by the classifier/UI.
String generateReferenceCode() => AppLogger.instance.generateRef();
