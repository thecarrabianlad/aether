import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-page or inline error view. Every error gets a message AND a
/// concrete next step (the "user always has an answer" guarantee).
///
/// When the [AppException.action] is [AppErrorAction.support] and a ref
/// code is attached, a support line with the reference code is shown.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.exception,
    this.onRetry,
    this.compact = false,
  });

  /// The classified error to display.
  final AppException exception;

  /// Called when the user taps the primary action (Retry / Go back /
  /// Open settings). For [AppErrorAction.retry]-style actions this is the
  /// re-run callback; for others it should navigate or re-invoke.
  final VoidCallback? onRetry;

  /// When true, renders a slimmer inline variant (padding, smaller icon,
  /// single-line action) suitable for embedding in a list or card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final isSupport = exception.action == AppErrorAction.support;

    final icon = Icon(
      _iconFor(exception),
      color: aether.danger,
      size: compact ? 28 : 44,
    );

    final message = Text(
      exception.message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: aether.textMuted,
          ),
    );

    final action = _buildAction(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  message,
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    action,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 16),
            Text(
              _titleFor(exception),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: aether.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            message,
            if (isSupport && exception.ref != null) ...[
              const SizedBox(height: 12),
              _SupportCode(code: exception.ref!, aether: aether),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildAction(BuildContext context) {
    final aether = context.aether;
    final action = exception.action;

    // "None" means recovery is automatic — nothing to do, no button.
    if (action == AppErrorAction.none) return null;

    return FilledButton(
      onPressed: onRetry,
      style: FilledButton.styleFrom(
        backgroundColor: aether.accent,
        foregroundColor: Colors.black,
      ),
      child: Text(_actionLabel(action)),
    );
  }

  static String _titleFor(AppException e) {
    return switch (e) {
      AuthError() => 'Sign in required',
      NetworkError() => 'You are offline',
      TimeoutError() => 'Taking too long',
      NotFoundError() => 'Not found',
      ServerError() => 'Server trouble',
      StorageError() => 'Something went wrong',
      PermissionError() => 'Permission needed',
      SyncError() => 'Sync issue',
      ValidationError() => 'Check your input',
      UnknownError() => 'Something went wrong',
    };
  }

  static IconData _iconFor(AppException e) {
    return switch (e) {
      NetworkError() => Icons.wifi_off_rounded,
      TimeoutError() => Icons.timer_off_rounded,
      AuthError() => Icons.lock_clock_rounded,
      NotFoundError() => Icons.search_off_rounded,
      ServerError() => Icons.cloud_off_rounded,
      StorageError() => Icons.storage_rounded,
      PermissionError() => Icons.notifications_off_rounded,
      SyncError() => Icons.sync_problem_rounded,
      ValidationError() => Icons.error_outline_rounded,
      UnknownError() => Icons.error_outline_rounded,
    };
  }

  static String _actionLabel(AppErrorAction action) {
    return switch (action) {
      AppErrorAction.none => '',
      AppErrorAction.retry => 'Try again',
      AppErrorAction.checkConnection => 'Check connection',
      AppErrorAction.reauthenticate => 'Sign in',
      AppErrorAction.support => 'Contact support',
      AppErrorAction.openSettings => 'Open settings',
    };
  }
}

/// Compact, copyable reference-code chip shown on the support fallback.
class _SupportCode extends StatelessWidget {
  const _SupportCode({required this.code, required this.aether});

  final String code;
  final AetherTheme aether;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: aether.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: aether.border),
      ),
      child: SelectableText(
        'Reference: $code',
        style: TextStyle(color: aether.textMuted, fontSize: 12),
      ),
    );
  }
}
