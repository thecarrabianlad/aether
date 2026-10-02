import 'package:aether/core/errors/app_exception.dart';
import 'package:aether/widgets/common/error_state.dart';
import 'package:aether/widgets/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ONE way screens render [AsyncValue] — loading shows a [SkeletonList]
/// (or a custom [loading] widget), error shows [ErrorStateView] with a
/// retry that calls [onRetry], and data renders [data].
///
/// Usage from any screen:
/// ```dart
/// final habits = ref.watch(filteredHabitsProvider);
/// return AsyncValueWidget(
///   value: habits,
///   onRetry: () => ref.invalidate(habitsProvider), // re-fires the stream
///   data: (habits) => ListView(children: [
///     for (final h in habits) HabitCard(habit: h),
///   ]),
/// );
/// ```
///
/// [loadingSkeleton] defaults to [SkeletonList] (6 shimmer cards). Pass
/// your own for custom loading shapes (e.g. a single [SkeletonCard] for a
/// single-item screen).
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingSkeleton,
    this.loadingSkeletonCount = 6,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loadingSkeleton;
  final int loadingSkeletonCount;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loadingSkeleton ?? SkeletonList(count: loadingSkeletonCount),
      error: (error, stack) {
        final classified = error is AppException ? error : classify(error);
        return ErrorStateView(
          exception: classified,
          onRetry: onRetry,
        );
      },
      data: data,
    );
  }
}