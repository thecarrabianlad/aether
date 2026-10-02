import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/core/errors/app_logger.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The app's single snackbar helper. All feedback (success, info, errors)
/// goes through here so entrance/exit animation, styling, and reduced-motion
/// handling stay consistent.
///
/// Error variant:
/// - message comes from the classified [AppException] (never a raw string)
/// - a "Retry" action is auto-added when the exception is retryable
/// - the exception is logged (with a ref code) automatically
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAetherSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  return messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 4),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}

/// Error snackbar from a classified [AppException]. Logs the error with a
/// ref code and attaches a Retry action for retryable failures.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    showAetherErrorSnackbar(
  BuildContext context,
  AppException exception, {
  VoidCallback? onRetry,
}) {
  AppLogger.instance.error(
    exception,
    code: exception.code,
    context: {'action': exception.action.name},
  );

  final showRetry = exception.retryable && onRetry != null;
  final isSupport = exception.action == AppErrorAction.support;

  return showAetherSnackbar(
    context,
    message: isSupport ? exception.message : exception.message,
    actionLabel: showRetry
        ? 'Retry'
        : (exception.action == AppErrorAction.reauthenticate ? 'Sign in' : null),
    onAction: showRetry
        ? onRetry
        : (exception.action == AppErrorAction.reauthenticate ? onRetry : null),
  );
}

/// Quick success feedback (e.g. "Habit saved").
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    showAetherSuccessSnackbar(BuildContext context, String message) {
  return showAetherSnackbar(
    context,
    message: message,
    duration: const Duration(seconds: 2),
  );
}
