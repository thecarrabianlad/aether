/// Retry policies for sync and network operations.
library;

/// Exponential backoff schedule for background sync retries.
/// After each consecutive failure, wait the next duration before retrying.
/// Caps at the last entry (10 minutes).
const syncBackoffSchedule = [
  Duration(seconds: 5),
  Duration(seconds: 30),
  Duration(minutes: 2),
  Duration(minutes: 10),
];

/// Returns the backoff delay for the given consecutive-failure count.
/// failures=0 → no delay, 1 → 5s, 2 → 30s, 3 → 2m, 4+ → 10m.
Duration backoffFor(int consecutiveFailures) {
  if (consecutiveFailures <= 0) return Duration.zero;
  final idx = consecutiveFailures - 1;
  return syncBackoffSchedule[
      idx >= syncBackoffSchedule.length ? syncBackoffSchedule.length - 1 : idx];
}

/// A queued sync row is dead-lettered (skipped by the processor, surfaced
/// in Settings for a Keep-mine / Discard decision) once it has failed this
/// many attempts.
const poisonedRowThreshold = 5;

/// Runs [fn] up to [attempts] times with the given [delays] between tries.
/// Rethrows the last error if all attempts fail.
Future<T> retry<T>(
  Future<T> Function() fn, {
  int attempts = 2,
  List<Duration> delays = const [Duration(seconds: 1), Duration(seconds: 4)],
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e, st) {
      lastError = e;
      lastStack = st;
      if (i < attempts - 1) {
        final delay = i < delays.length ? delays[i] : delays.last;
        await Future<void>.delayed(delay);
      }
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack!);
}