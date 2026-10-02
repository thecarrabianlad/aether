import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// AETHER — Theme system
/// ---------------------------------------------------------------------
/// Centralizes the app's dark aesthetic into a configurable theme:
///  • [AccentPreset]  — curated accent colors the user can pick from
///  • [BackgroundVariant] — graphite (default) or pure-black AMOLED
///  • [AetherTheme]   — a [ThemeExtension] carrying all app colors so
///    widgets read them via `Theme.of(context).extension<AetherTheme>()`
///    (or the [AetherThemeX.aether] shorthand) instead of hardcoding.
/// ---------------------------------------------------------------------

/// Curated accent colors. Each carries a display name and the accent
/// color used for highlights, active states, and glows app-wide.
enum AccentPreset {
  ember('Ember', Color(0xFFE8443F)),
  rose('Rose', Color(0xFFE88D8A)),
  violet('Violet', Color(0xFF8B5CF6)),
  ocean('Ocean', Color(0xFF4A9DE8)),
  mint('Mint', Color(0xFF34C759)),
  amber('Amber', Color(0xFFE8A33F));

  final String label;
  final Color color;

  const AccentPreset(this.label, this.color);

  /// Lookup by stored name; falls back to [ember] (the app's original red).
  static AccentPreset fromName(String? name) {
    return AccentPreset.values.firstWhere(
      (p) => p.name == name,
      orElse: () => AccentPreset.ember,
    );
  }
}

/// Background darkness variants.
enum BackgroundVariant {
  graphite('Graphite'),
  amoled('AMOLED');

  final String label;

  const BackgroundVariant(this.label);

  static BackgroundVariant fromName(String? name) {
    return BackgroundVariant.values.firstWhere(
      (v) => v.name == name,
      orElse: () => BackgroundVariant.graphite,
    );
  }
}

/// User's theme selection. Immutable value object held by the theme
/// controller and persisted via SettingsService.
@immutable
class AppThemeState {
  final AccentPreset accent;
  final BackgroundVariant background;

  const AppThemeState({
    this.accent = AccentPreset.ember,
    this.background = BackgroundVariant.graphite,
  });

  AppThemeState copyWith({
    AccentPreset? accent,
    BackgroundVariant? background,
  }) {
    return AppThemeState(
      accent: accent ?? this.accent,
      background: background ?? this.background,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppThemeState &&
      other.accent == accent &&
      other.background == background;

  @override
  int get hashCode => Object.hash(accent, background);
}

/// App-wide color tokens, resolved from an [AppThemeState].
///
/// Widgets should read these instead of hardcoding colors:
/// ```dart
/// final aether = context.aether;
/// Container(color: aether.card, child: Icon(color: aether.accent));
/// ```
class AetherTheme extends ThemeExtension<AetherTheme> {
  /// Primary accent — highlights, active nav items, glows, CTAs.
  final Color accent;

  /// Color that contrasts well with the accent color.
  final Color onAccent;

  /// Scaffold / page background.
  final Color background;

  /// Elevated surface (cards, sheets, dialogs).
  final Color surface;

  /// Slightly raised surface (input fills, chips).
  final Color surfaceAlt;

  /// Card fill used by glass cards.
  final Color card;

  /// Hairline borders on cards and dividers.
  final Color border;

  /// Primary text.
  final Color text;

  /// Secondary / muted text.
  final Color textMuted;

  /// Success (streaks, confirmations).
  final Color success;

  /// Destructive actions and errors.
  final Color danger;

  const AetherTheme({
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.onAccent,
  });

  /// Builds the token set for a given user selection.
  factory AetherTheme.fromState(AppThemeState state) {
    final amoled = state.background == BackgroundVariant.amoled;
    return AetherTheme(
      accent: state.accent.color,
      background: amoled ? const Color(0xFF000000) : const Color(0xFF0D0D0D),
      surface: amoled ? const Color(0xFF101012) : const Color(0xFF18181A),
      surfaceAlt: amoled ? const Color(0xFF1A1A1C) : const Color(0xFF2C2C2E),
      card: amoled ? const Color(0xFF0E0E0E) : const Color(0xFF121212),
      border: const Color(0xFF262626),
      text: const Color(0xFFF5F5F5),
      textMuted: const Color(0xFF8E8E93),
      success: const Color(0xFF34C759),
      danger: const Color(0xFFFF3B30),
      onAccent: const Color(0xFFFFFFFF), // White color for text/icons on accent
    );
  }

  @override
  AetherTheme copyWith({
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? danger,
  }) {
    return AetherTheme(
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AetherTheme lerp(ThemeExtension<AetherTheme>? other, double t) {
    if (other is! AetherTheme) return this;
    return AetherTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Convenience accessor: `context.aether.accent`.
extension AetherThemeX on BuildContext {
  AetherTheme get aether =>
      Theme.of(this).extension<AetherTheme>() ??
      AetherTheme.fromState(const AppThemeState());

  /// Motion tokens: `context.motion.base` (or `context.motion.d(200)`).
  AetherMotion get motion => Theme.of(this).extension<AetherMotion>() ??
      const AetherMotion();
}

/// Shared motion tokens for the app's UX animations.
///
/// Widgets should read durations/curves from here instead of hardcoding:
/// ```dart
/// AnimatedContainer(duration: context.motion.fast, curve: context.motion.easeOut)
/// ```
/// The [AetherMotion.of] duration lookup collapses every duration to zero
/// when reduced motion is active.
class AetherMotion extends ThemeExtension<AetherMotion> {
  const AetherMotion({
    this.instant = const Duration(milliseconds: 100),
    this.fast = const Duration(milliseconds: 150),
    this.base = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
    this.hero = const Duration(milliseconds: 600),
    this.stagger = const Duration(milliseconds: 40),
    this.easeOut = Curves.easeOutCubic,
    this.easeIn = Curves.easeInCubic,
    this.easeInOut = Curves.easeInOutCubic,
    this.spring = Curves.easeOutBack,
    this.emphasized = Curves.easeInOutCubicEmphasized,
  });

  /// 100 ms — pressed-state feedback, icon swaps.
  final Duration instant;

  /// 150 ms — hover/focus, checkbox/toggle, chip selection.
  final Duration fast;

  /// 250 ms — most transitions: fades, tab indicator, snackbars.
  final Duration base;

  /// 400 ms — route transitions, sheets, skeleton → content swap.
  final Duration slow;

  /// 600 ms — one-off celebrations: login success, streak milestone.
  final Duration hero;

  /// 40 ms — per-item delay in staggered lists (cap at 8 items).
  final Duration stagger;

  /// Entrances (things arriving).
  final Curve easeOut;

  /// Exits (things leaving).
  final Curve easeIn;

  /// Moves/morphs (position/size change).
  final Curve easeInOut;

  /// Playful emphasis: habit checkoff, FAB, celebration.
  final Curve spring;

  /// Route/sheet transitions (M3 standard).
  final Curve emphasized;

  /// [duration] collapsed to zero when reduced motion is active.
  Duration of(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  @override
  AetherMotion copyWith({
    Duration? instant,
    Duration? fast,
    Duration? base,
    Duration? slow,
    Duration? hero,
    Duration? stagger,
    Curve? easeOut,
    Curve? easeIn,
    Curve? easeInOut,
    Curve? spring,
    Curve? emphasized,
  }) {
    return AetherMotion(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      hero: hero ?? this.hero,
      stagger: stagger ?? this.stagger,
      easeOut: easeOut ?? this.easeOut,
      easeIn: easeIn ?? this.easeIn,
      easeInOut: easeInOut ?? this.easeInOut,
      spring: spring ?? this.spring,
      emphasized: emphasized ?? this.emphasized,
    );
  }

  @override
  AetherMotion lerp(ThemeExtension<AetherMotion>? other, double t) {
    if (other is! AetherMotion) return this;
    return AetherMotion(
      instant: lerpDuration(instant, other.instant, t),
      fast: lerpDuration(fast, other.fast, t),
      base: lerpDuration(base, other.base, t),
      slow: lerpDuration(slow, other.slow, t),
      hero: lerpDuration(hero, other.hero, t),
      stagger: lerpDuration(stagger, other.stagger, t),
      easeOut: other.easeOut,
      easeIn: other.easeIn,
      easeInOut: other.easeInOut,
      spring: other.spring,
      emphasized: other.emphasized,
    );
  }
}

Duration lerpDuration(Duration a, Duration b, double t) =>
    Duration(milliseconds: (a.inMilliseconds * (1 - t) + b.inMilliseconds * t).round());

/// True when motion should be suppressed by the OS accessibility
/// reduced-motion setting. The manual Settings toggle ("Reduce motion")
/// is read via `reduceMotionProvider` at animation call sites (Stage 2).
/// Progress indicators (spinners, rings) keep animating — they convey
/// state, not decoration.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Builds the app's [ThemeData] for the given user selection.
ThemeData buildAetherTheme(AppThemeState state) {
  final aether = AetherTheme.fromState(state);

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: aether.background,
    colorScheme: ColorScheme.dark(
      primary: aether.accent,
      secondary: aether.accent,
      surface: aether.surface,
      error: aether.danger,
    ),
    extensions: [aether, const AetherMotion()],
    snackBarTheme: SnackBarThemeData(
      backgroundColor: aether.surface,
      contentTextStyle: TextStyle(color: aether.text),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? aether.accent : aether.textMuted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? aether.accent.withValues(alpha: 0.35)
              : aether.surfaceAlt),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
