import 'dart:async';

import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/errors/app_logger.dart';
import 'package:aether/core/errors/retry.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:flutter/foundation.dart';

/// High-level sync state exposed to the UI (top-bar indicator, settings).
enum SyncPhase { idle, syncing, error, offline }

@immutable
class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.lastSyncedAt,
    this.lastError,
    this.consecutiveFailures = 0,
  });

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final AppException? lastError;
  final int consecutiveFailures;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncedAt,
    AppException? lastError,
    int? consecutiveFailures,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}

/// Orchestrates data synchronization between the local Drift database and
/// Supabase.
///
/// Resilience rules:
/// - Each sync target runs in isolation — one failure never cancels the rest.
/// - After a failed run, the next automatic run is delayed by an exponential
///   backoff (5s → 30s → 2m → 10m), reset on success or reconnect.
/// - Status is published through [status] (a [ValueNotifier]) so the UI can
///   show a spinner / warning without polling.
class SyncService {
  final AcademicsService _academicsService;
  final HabitsService _habitsService;
  final SyncQueueService _syncQueueService;

  SyncService(this._academicsService, this._habitsService, this._syncQueueService);

  /// Live sync status for the UI.
  final ValueNotifier<SyncStatus> status =
      ValueNotifier(const SyncStatus(phase: SyncPhase.idle));

  bool _syncing = false;
  DateTime? _nextAllowedRun;

  /// Whether an automatic run is currently allowed (not already syncing,
  /// not inside a backoff window).
  bool get canAutoSync =>
      !_syncing &&
      (_nextAllowedRun == null || DateTime.now().isAfter(_nextAllowedRun!));

  /// Marks the device offline in the status (called by the connectivity
  /// listener). Clears when a sync succeeds.
  void markOffline() {
    status.value = status.value.copyWith(phase: SyncPhase.offline);
  }

  /// Resets the backoff (called on reconnect so the user isn't stuck
  /// waiting out a 10-minute window that no longer applies).
  void resetBackoff() {
    _nextAllowedRun = null;
    status.value = status.value.copyWith(consecutiveFailures: 0);
  }

  /// Performs an initial sync of all data on app startup/login.
  Future<void> performInitialSync() => syncAllData();

  /// Syncs all data. Each target is isolated: a failure in one is recorded
  /// but the others still run. Also drains the offline queue first so
  /// local changes reach the server before we re-pull.
  ///
  /// Returns true when every target succeeded.
  Future<bool> syncAllData() async {
    if (_syncing) return false;
    _syncing = true;
    status.value = status.value.copyWith(phase: SyncPhase.syncing);

    final failures = <String, Object>{};

    // Push queued local changes first.
    try {
      await _syncQueueService.processQueue();
    } catch (e) {
      failures['queue'] = e;
    }

    // Pull each domain in isolation.
    final targets = <String, Future<void> Function()>{
      'courses': _academicsService.syncCourses,
      'lectures': _academicsService.syncLectures,
      'assignments': _academicsService.syncAssignments,
      'habits': _habitsService.syncHabits,
      'habitLogs': _habitsService.syncHabitLogs,
    };

    for (final entry in targets.entries) {
      try {
        await entry.value();
      } catch (e) {
        failures[entry.key] = e;
      }
    }

    _syncing = false;

    if (failures.isEmpty) {
      _nextAllowedRun = null;
      status.value = SyncStatus(
        phase: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
        consecutiveFailures: 0,
      );
      return true;
    }

    // At least one target failed: log each, classify the first for the UI,
    // and schedule the backoff window.
    for (final entry in failures.entries) {
      AppLogger.instance.error(
        entry.value,
        code: 'AE-SYNC01',
        context: {'target': entry.key},
      );
    }
    final consecutive = status.value.consecutiveFailures + 1;
    _nextAllowedRun = DateTime.now().add(backoffFor(consecutive));
    status.value = status.value.copyWith(
      phase: SyncPhase.error,
      lastError: classify(failures.values.first),
      consecutiveFailures: consecutive,
    );
    return false;
  }
}