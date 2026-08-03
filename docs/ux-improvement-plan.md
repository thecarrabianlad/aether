# AETHER — UX Animation & Error Handling Implementation Plan

> Planning document (AEEP Phase 0–3 output). No production code in this doc.
> Stack facts verified against the codebase on 2026-08-01:
> - Flutter (Material 3, dark-only theme), Riverpod 2.5, go_router 17 (`ShellRoute` + `MainScaffold`)
> - Supabase auth (`AuthService` throws `AuthException`; screens catch → snackbar)
> - Drift/SQLite offline-first, `sync_queue` table, `SyncService` (currently a simple parallel re-pull, no retry/backoff)
> - `connectivity_plus` available but no offline UI exists
> - `main.dart` has **no** `runZonedGuarded` / `FlutterError.onError`; router has **no** `errorBuilder`
> - All routes use `builder:` (default Material transitions); no animation packages installed
> - Theme tokens live in `lib/core/theme/app_theme.dart` as the `AetherTheme` `ThemeExtension`, read via `context.aether`

---

## Part A — Motion System (build this FIRST; everything else consumes it)

### A1. Motion tokens (`lib/core/theme/app_theme.dart`)

Add an `AetherMotion` `ThemeExtension` next to `AetherTheme`, registered in `buildAetherTheme()`'s `extensions:` list, with a `context.motion` accessor added to the existing `AetherThemeX` extension. Durations and curves are theme-independent constants, but living in the ThemeExtension keeps the "never hardcode, always `context.*`" rule uniform.

| Token | Value | Use |
|---|---|---|
| `instant` | 100 ms | pressed-state feedback, icon swaps |
| `fast` | 150 ms | hover/focus, checkbox/toggle, chip selection |
| `base` | 250 ms | most transitions: fades, tab indicator, snackbars |
| `slow` | 400 ms | route transitions, sheets, skeleton→content swap |
| `hero` | 600 ms | one-off celebrations: login success, streak milestone, card flip |
| `stagger` | 40 ms | per-item delay in staggered lists (cap total at 8 items × 40 ms) |
| `easeOut` | `Curves.easeOutCubic` | entrances (things arriving) |
| `easeIn` | `Curves.easeInCubic` | exits (things leaving) |
| `easeInOut` | `Curves.easeInOutCubic` | moves/morphs (position/size change) |
| `spring` | `Curves.easeOutBack` | playful emphasis: habit checkoff, FAB, celebration |
| `emphasized` | `Curves.easeInOutCubicEmphasized` | route/sheet transitions (M3 standard) |

### A2. Reduced motion

`reduceMotion(BuildContext c)` returns true when **either** `MediaQuery.of(c).disableAnimations` (OS accessibility) **or** a manual "Reduce motion" toggle in Settings (`SettingsService` flag) is on. `Duration AetherMotion.of(context, token)` returns `Duration.zero` when reduced motion is active. **Rule for every animation below:** with reduced motion, decorative animation collapses to an instant state change (opacity 0→1 with no slide/scale); progress indicators (pomodoro ring, sync spinner, linear progress) remain because they convey state, not decoration. No flashing anywhere (>3 Hz forbidden). Animations never intercept or delay input.

### A3. Performance rules (apply to all items)

- Animate **only** `transform` + `opacity` (via `FadeTransition`/`ScaleTransition`/`SlideTransition`/`AnimatedOpacity`/`AnimatedScale`/`AnimatedSlide`). Never animate padding, width/height, or constraints on list items.
- Wrap continuously-animating widgets (shimmer, pomodoro ring) in `RepaintBoundary`.
- Staggered lists: animate only on **first** build after data arrives (guard with a `_didAnimate` flag or animate only when list transitions empty→populated); never on every Drift stream emission — this respects the existing "reduce rebuilds" work (commit `a7eaa8f`).
- No new dependency needed for the error-handling workstream. `flutter_animate` is approved (Part F) — add it in Stage 1 alongside motion tokens and prefer it for staggers, shakes, and one-shot celebration effects; use framework primitives (`AnimatedSwitcher`, `Hero`, `CustomTransitionPage`) where they're already the natural fit.

---

## Part B — Animation Inventory

Legend: **Type** H = hero (high-visibility, one place), S = subtle (ambient/micro). Every row: reduced-motion fallback = instant/fade-only per A2; performance = transform/opacity only per A3.

### B1. Boot & shell

| # | Animation | Location | Trigger | Type | Tokens | Technique | Pri |
|---|---|---|---|---|---|---|---|
| 1 | Boot fade-in: logo/wordmark fades+scales in over `aether.background` while `main()` awaits Supabase/notifications/settings init, then cross-fades into first route | New `lib/widgets/boot_splash.dart`; restructure `main.dart` to `runApp` immediately with a splash and init in `FutureBuilder`-style gate (also fixes blank-screen-during-init) | app launch | H | `slow`, `easeOut` | `AnimatedOpacity` + `AnimatedScale` | P0 |
| 2 | Route transition: fade-through (outgoing fades, incoming fades+slides up 8 px) for all routes | `lib/core/routing/app_router.dart` — convert every `builder:` to `pageBuilder:` returning a shared `AetherPage` (`CustomTransitionPage` subclass in new `lib/core/routing/aether_page.dart`) | navigation | S | `slow`, `emphasized` | `CustomTransitionPage` with `FadeTransition`+`SlideTransition` | P0 |
| 3 | Bottom navbar: active icon scale-pop + accent glow fade; tab indicator | `lib/widgets/bottom_navbar.dart` | tab change | S | `fast`, `spring` | `AnimatedScale` + `AnimatedContainer` (decoration only) | P1 |
| 4 | Side drawer: content stagger (items slide in 12 px, 40 ms apart) when drawer opens | `lib/widgets/side_drawer.dart` | drawer open | S | `base`, `easeOut`, `stagger` | `AnimationController` + `Interval` tweens | P2 |
| 5 | Theme switch: animated cross-fade of all colors when accent/background changes | Already works — `AetherTheme.lerp` exists; verify `MaterialApp` `themeAnimationDuration`/`Curve` set to `base`/`easeInOut` in `main.dart` | theme change in settings | S | `base`, `easeInOut` | built-in `ThemeData` lerp | P2 |

### B2. Auth flow

| # | Animation | Location | Trigger | Type | Tokens | Technique | Pri |
|---|---|---|---|---|---|---|---|
| 6 | Form entrance: logo, fields, button stagger in (fade + 16 px slide-up) | `login_screen.dart`, `signup_screen.dart` | mount | H | `slow`, `easeOut`, `stagger` | one `AnimationController`, `Interval` per child | P0 |
| 7 | Input focus: border color + subtle accent glow transition on `AuthTextField` | `lib/features/auth/widgets/auth_textfield.dart` | focus change | S | `fast`, `easeOut` | `AnimatedContainer` decoration (or `FocusNode` listener + `AnimatedOpacity` glow layer) | P0 |
| 8 | Error shake: form translates ±8 px horizontally 3× on auth failure, paired with inline error text (see E-taxonomy) | shared `ShakeWidget` in new `lib/widgets/common/shake.dart`; used by both auth screens | `AuthException` caught | S | `base` (300 ms total), sine curve | explicit `AnimationController` + `Transform.translate` | P0 |
| 9 | Submit button morph: label → spinner (pending) → checkmark (success) → route transition; button disabled while pending | new `lib/widgets/common/progress_button.dart`; used in login/signup/profile save | submit tap → async result | H | `fast` per stage, `spring` on check | `AnimatedSwitcher` between child states | P0 |
| 10 | Post-login transition: brief success state (check pops on button) then navigate; shell fades in via #2 | login screen + router | successful sign-in | H | `hero`, `spring` | sequence: #9 success state → `context.go('/')` | P1 |

### B3. Data screens (dashboard, tasks, habits, academics, schedule)

| # | Animation | Location | Trigger | Type | Tokens | Technique | Pri |
|---|---|---|---|---|---|---|---|
| 11 | Skeleton shimmer: glass-card-shaped placeholders with a slow opacity pulse while first Drift/sync data loads | new `lib/widgets/common/skeleton.dart` (pulse via `AnimationController` repeat, wrapped in `RepaintBoundary`); used in dashboard, academics, habits | provider `AsyncValue.loading` / stream not yet emitted | S | `slow` (pulse ~1200 ms, opacity 0.4↔0.7 — no flash risk) | `FadeTransition` on `AnimatedBuilder` | P0 |
| 12 | List entrance stagger: habit cards / task tiles / course cards fade+slide-up 12 px, 40 ms apart, first load only | `habit_card.dart` consumers (`habits_screen.dart`), `daily_tasks_screen.dart`, `academics_screen.dart` — via shared `StaggeredEntrance` wrapper in `lib/widgets/common/staggered_entrance.dart` | first data arrival (empty→populated transition) | S | `base`, `easeOut`, `stagger` | `TweenAnimationBuilder` per item with index delay | P1 |
| 13 | Habit checkoff celebration: checkbox pops (`spring` scale 1→1.15→1), card completion state cross-fades, streak counter ticks up | `lib/features/habits/widgets/habit_card.dart` | user marks habit done | H | `base`, `spring` | `AnimatedScale` + `AnimatedSwitcher` on streak number | P0 |
| 14 | Task complete: checkbox spring-pop + strike-through wipe on title | `daily_tasks_screen.dart` task tile | completion toggle | S | `fast`, `spring` | `AnimatedScale`; strike-through via `TweenAnimationBuilder` clipping a decorated overlay (transform-based) | P1 |
| 15 | Date navigator: outgoing day's content slides left/right + fades per swipe direction | `lib/features/habits/widgets/date_navigator.dart` + `dashboard_date_selector.dart` consumers | date change | S | `base`, `easeInOut` | `AnimatedSwitcher` with directional `SlideTransition` (`layoutBuilder` to prevent jump) | P1 |
| 16 | Weekly chart bars: grow from 0 to value on first view | `lib/features/habits/widgets/weekly_chart.dart` | mount / data arrival | S | `slow`, `easeOut`, per-bar `stagger` | `TweenAnimationBuilder` scaling `FractionallySizedBox`-style transform | P2 |
| 17 | Progress bars/cards animate to value instead of jumping | `lib/widgets/common/progress_bar.dart`, `dashboard_progress_card.dart` | value change | S | `slow`, `easeOut` | `TweenAnimationBuilder<double>` | P1 |
| 18 | Pill tab indicator slides between tabs | `lib/widgets/common/pill_tab_view.dart` | tab tap | S | `base`, `emphasized` | `AnimatedAlign` or `AnimatedPositioned` within fixed-size stack | P1 |
| 19 | Glass card press feedback: scale 0.98 on press-down | `lib/widgets/common/glass_card.dart` (opt-in `onTap` variant) | pointer down/up | S | `instant`, `easeOut` | `AnimatedScale` + `GestureDetector` (keep existing `InkWell` ripple) | P1 |
| 20 | Empty states: illustration/icon fades+floats in, CTA follows | `lib/features/habits/widgets/empty_habits.dart` (generalize into `lib/widgets/common/empty_state.dart` — also used by error handling D5) | list becomes empty / first empty load | S | `slow`, `easeOut` | `TweenAnimationBuilder` | P2 |

### B4. Sheets, dialogs, overlays

| # | Animation | Location | Trigger | Type | Tokens | Technique | Pri |
|---|---|---|---|---|---|---|---|
| 21 | Bottom sheets slide up with `emphasized` curve + scrim fade (consistent across add-task, add-habit, block-form, options sheets) | shared `showAetherSheet()` helper in new `lib/widgets/common/aether_sheet.dart`; migrate `add_task_sheet.dart`, `block_form_sheet.dart`, `block_options_sheet.dart`, `task_options_sheet.dart` call sites | sheet open/close | S | `slow`, `emphasized` | `showModalBottomSheet` with custom `AnimationStyle` | P1 |
| 22 | Dialogs: fade + scale 0.95→1 (first-login, add-habit, custom-template) | shared `showAetherDialog()` in same helper file | dialog open | S | `base`, `easeOut` | `showGeneralDialog` `transitionBuilder` | P2 |
| 23 | Snackbar entrance: slide-up + fade; exit fade (used heavily by error handling) | theme-level: extend `snackBarTheme` in `app_theme.dart`; new `showAetherSnackbar()` wrapper in `lib/widgets/common/app_snackbar.dart` (shared with Workstream 2) | show/dismiss | S | `base`, `easeOut`/`easeIn` | `SnackBarBehavior.floating` + `AnimationStyle` | P0 |
| 24 | Offline banner: slides down from top of `MainScaffold`, slides away on reconnect (see D-net) | `lib/widgets/main_scaffold.dart` + new `lib/widgets/common/offline_banner.dart` | connectivity change | S | `base`, `easeOut` | `AnimatedSlide` + `AnimatedOpacity` | P0 |
| 25 | Sync status indicator: small rotating icon in top bar while sync runs; morphs to check (2 s) on success, to warning icon on failure | `lib/widgets/dashboard_top_bar.dart` + new sync-status provider (see D-sync) | sync state change | S | `base`; rotation 1000 ms linear, `RepaintBoundary` | `RotationTransition` + `AnimatedSwitcher` | P1 |

### B5. Feature heroes (Phase 3 polish)

| # | Animation | Location | Trigger | Type | Tokens | Technique | Pri |
|---|---|---|---|---|---|---|---|
| 26 | Flashcard 3D flip on tap | `flashcards_screen.dart` | card tap | H | `hero`, `easeInOut` | `AnimationController` + `Transform` matrix rotateY (perspective entry 0.001) | P2 |
| 27 | Pomodoro ring: continuous smooth progress + color shift near end; scale-pulse on session complete | `pomodoro_screen.dart` | timer tick / completion | H | ring = state (kept under reduced motion); pulse `hero`, `spring` | `CustomPaint` in `AnimatedBuilder`, `RepaintBoundary` | P2 |
| 28 | Habit detail: `Hero` transition on the habit's icon/color chip from card → detail screen | `habit_card.dart` ↔ `habit_detail_screen.dart` | navigation | H | framework-driven | `Hero` widget (works with go_router pages from #2) | P2 |
| 29 | Streak milestone celebration (7/30/100 days): one-shot particle/confetti burst over habit card | `habit_card.dart` overlay | streak crosses milestone | H | `hero`, `easeOut` | `CustomPaint` particle system (or `flutter_animate` if adopted); strictly one-shot, no flashing | P2 |

### B6. Animation roadmap

- **Phase 1 (P0 — foundation + highest visibility):** A1/A2 motion tokens → #23 snackbar wrapper → #2 route transitions → #1 boot splash → #11 skeletons → #6–9 auth entrance/focus/shake/button → #13 habit checkoff → #24 offline banner.
- **Phase 2 (P1 — daily-use feel):** #12 stagger, #14 task complete, #15 date navigator, #17 progress, #18 pill tabs, #19 card press, #21 sheets, #25 sync indicator, #3 navbar, #10 post-login.
- **Phase 3 (P2 — polish):** #26 flashcard flip, #27 pomodoro, #28 hero transition, #29 milestones, #4 drawer, #5 theme, #16 chart, #20 empty states, #22 dialogs.

---

## Part C — Error Taxonomy

Principle: **every error states what happened + what to do next, or recovers silently.** The app is offline-first: local writes must never fail due to network; only auth and sync require connectivity.

App-level codes are `AE-<class><nn>` (e.g., `AE-AUTH01`), shown to users only in the unknown/support case; always logged.

| Class | Produced by | Code(s) | User message | Next action | Treatment | Recovery |
|---|---|---|---|---|---|---|
| Validation | client validators; Supabase 400/422 (weak password, invalid email) | `AE-VAL01` | Field-specific: "Password needs at least 8 characters." | fix field (autofocus first invalid) | inline red text under field (`aether.danger`), field border tint; never a snackbar | none — user corrects |
| Invalid credentials | `AuthException` 400 `invalid_credentials` | `AE-AUTH01` | "Email or password is incorrect." | re-enter; "Forgot password?" link (wires up existing `resetPassword`) | inline banner above submit + shake (#8) | manual |
| Email not confirmed | `AuthException` 400 `email_not_confirmed` | `AE-AUTH02` | "Check your inbox and confirm your email first." | "Resend email" button | inline banner on login | manual, resend action |
| Session expired / refresh failed | `AuthException` 401, refresh-token revoked | `AE-AUTH03` | "Your session expired. Please sign in again." | auto-redirect to `/login` (existing `redirect` handles it once signed out) + snackbar explaining why | snackbar on login screen after redirect | Supabase SDK auto-refreshes silently first; only on hard failure do we `signOut()` → redirect. Local data untouched; user resumes where possible |
| Auth rate limit | `AuthException` 429 | `AE-AUTH04` | "Too many attempts. Try again in {n}s." | countdown on disabled submit button (#9 reuses pending state) | inline banner + button countdown | auto re-enable after cooldown |
| Offline (auth/sync) | `connectivity_plus` none; `SocketException`/`ClientException` from Supabase calls | `AE-NET01` | Banner: "You're offline — changes are saved on this device and will sync when you're back." Auth: "No connection. Check your internet and try again." | for local features: nothing (writes succeed via Drift + `sync_queue`); auth: retry button | persistent top banner (#24) for state; inline for auth attempts | queue-based: `sync_queue` holds writes; auto-sync on reconnect (connectivity listener) |
| Timeout | Supabase call exceeds 15 s (add explicit timeout in service layer) | `AE-NET02` | "The server is taking too long. Your data is safe on this device." | Retry button | snackbar with action | 1 automatic retry, then surface |
| Sync push/pull failure | `PostgrestException` 5xx, network drop mid-sync | `AE-SYNC01` | none immediately (background); indicator (#25) shows warning; tap → "Sync failed — will retry automatically. Last synced {time}." | tap indicator → "Sync now" | subtle indicator, never modal | exponential backoff: 5 s, 30 s, 2 m, 10 m (max), reset on success/reconnect |
| Poisoned sync row | same row fails 5+ consecutive attempts (4xx from server) | `AE-SYNC02` | Settings → sync section: "1 change couldn't sync. Keep my version / Discard." | explicit user choice | list in settings, badge on indicator | dead-letter: mark row `failed` in `sync_queue`, skip in future runs, never block queue |
| Forbidden / RLS | `PostgrestException` 401/403 | `AE-AUTHZ1` | "You don't have access to that." | "Go back" | snackbar or full-page error state if route-level | if token stale → silent refresh + one retry; else surface |
| Not found | `PostgrestException` 404; unknown route; missing habit id in `/habit-detail/:id` | `AE-NF01` | "That item no longer exists — it may have been deleted on another device." Route: "Page not found." | "Go home" / back | full-page error state (`error_state.dart`); router `errorBuilder` for bad routes | none |
| Server 5xx | `PostgrestException` ≥500 | `AE-SRV01` | "Our servers are having trouble. Your data is safe on this device." | "Try again" + auto-retry note | snackbar (background) / inline retry (foreground load) | 2 retries with backoff (1 s, 4 s), then surface; local cache remains the displayed data |
| Local DB failure | Drift/SQLite exception, migration failure | `AE-DB01` | "Something went wrong saving on this device. Restart the app; if it persists, contact support with code AE-DB01-{ref}." | restart guidance + support | full-page error (boot) or dialog (runtime write) | none automatic — log full detail; never auto-delete DB |
| Notification/permission | `flutter_local_notifications` permission denied, timezone init failure | `AE-NTF01` | "Reminders are off — enable notifications in system settings." | "Open settings" deep link | one-time dialog when user enables a reminder, then inline note in settings | degrade gracefully: habits work without reminders |
| Unknown | anything unclassified; Flutter errors | `AE-UNK01` | "Something went wrong. Try again — if it keeps happening, contact support with code {ref}." | Retry + copyable ref code | snackbar (async ops) or error boundary page (build errors) | none; log everything |

`{ref}` = 6-char base32 from a UUID generated per incident (uses existing `uuid` package), shown to user AND attached to the log entry.

---

## Part D — Error-Handling Architecture

### D1. Flow

```
UI event (tap / mount / stream)
   → service call (lib/core/services/*, feature services)
      → throws raw exception (AuthException / PostgrestException / SocketException / DriftError)
   → classifier: AppException.from(raw)           [lib/core/errors/app_exception.dart]
      sealed class AppException { code, userMessage, action, retryable, cause }
      subclasses: ValidationError, AuthError, NetworkError, TimeoutError,
                  SyncError, PermissionError, NotFoundError, ServerError,
                  StorageError, UnknownError
   → surfaces as:
        Riverpod: AsyncValue.error(AppException)  → AsyncValueWidget renders error_state / retry
        imperative (button handlers): try/catch    → showAetherSnackbar(error) or inline banner
   → logged: AppLogger.error(exception, ref, route, context)  [lib/core/errors/app_logger.dart]
```

### D2. New files

| File | Contents |
|---|---|
| `lib/core/errors/app_exception.dart` | sealed `AppException` hierarchy + `AppException.from(Object raw)` classifier mapping every raw type per Part C; user messages live here (single source of truth) |
| `lib/core/errors/app_logger.dart` | structured logger: timestamp, code, ref-id, route (from router), sanitized context. **Never logs** tokens, passwords, email bodies, `.env` values. Debug: `debugPrint`; release: ring buffer (last 200 entries) in memory + optional file via `path_provider` for support export. Crash-reporting SaaS deferred (open question) |
| `lib/core/errors/retry.dart` | `retry(fn, {attempts, backoff})` helper + backoff schedule constants (used by sync + server-5xx policy) |
| `lib/widgets/common/async_value_widget.dart` | `AsyncValueWidget<T>` — the ONE way screens render `AsyncValue`: `data` → child, `loading` → skeleton (B#11), `error` → `ErrorStateView` with retry callback (invalidates the provider) |
| `lib/widgets/common/error_state.dart` | full-page/inline error view: icon, message, action button, optional ref code — matches glass aesthetic |
| `lib/widgets/common/app_snackbar.dart` | `showAetherSnackbar(context, {message, action})` + error variant taking `AppException` (auto message + retry action). Also home of animation B#23 |
| `lib/widgets/common/offline_banner.dart` | connectivity-driven banner (B#24), fed by new `connectivityProvider` (`StreamProvider` over `connectivity_plus`) in `lib/core/providers.dart` |

### D3. Modified files

| File | Change |
|---|---|
| `lib/main.dart` | wrap `runApp` in `runZonedGuarded`; set `FlutterError.onError` + `PlatformDispatcher.onError` → `AppLogger`; set `ErrorWidget.builder` in release to a compact fallback card (no red screen). Move heavy init behind boot splash (B#1) with a full-page `StorageError` state if init itself fails |
| `lib/core/routing/app_router.dart` | add `errorBuilder:` → `ErrorStateView` ("Page not found", Go home). Session-expiry redirect already works via `refreshListenable`; add snackbar-on-login explaining the redirect (pass reason via `state.uri` query param) |
| `lib/core/services/auth_service.dart` | catch raw `AuthException` → rethrow as classified `AppException` (preserves current "screens catch and show" contract but with mapped messages); add 15 s timeout |
| `lib/core/services/sync_service.dart` + `sync_queue_service.dart` | `Future.wait` → sequential-with-isolation (one failed sync target must not cancel the rest; collect failures); wire backoff from `retry.dart`; poisoned-row dead-lettering (attempt counter column on `sync_queue` — needs a Drift migration); expose `syncStatusProvider` (`idle / syncing / error(AppException) / offline`) for indicator B#25; trigger sync on connectivity-restored |
| Feature services (`habits_service`, `academics_service`, `task_service`, etc.) | wrap Supabase calls in classifier; Drift-only paths wrap in `StorageError` mapping. Local reads/writes stay exception-transparent (they should essentially never fail; when they do it's `AE-DB01`) |
| Auth screens | replace bare snackbar-on-catch with: inline banner + shake (B#8) for auth errors, field-level validation display, `ProgressButton` (B#9) with rate-limit countdown |
| All data screens | migrate ad-hoc `when(...)`/null-checks to `AsyncValueWidget` |

### D4. Always-an-answer guarantee

Enforced structurally: `AppException.userMessage` and `AppException.action` are **required, non-nullable** fields — an unclassified error can only become `UnknownError`, which carries the fallback message and ref code by construction. No UI path renders a raw exception string (lint-able: grep for `e.toString()` in widgets during self-review).

---

## Part E — Combined Implementation Order (AEEP: small atomic tasks, validate each with `flutter analyze` + `flutter test`)

Each step is one commit-sized task; no step depends on a later one.

**Stage 1 — Foundations (do first, everything depends on these)**
1. Motion tokens: `AetherMotion` extension + `context.motion` + `reduceMotion` helper in `app_theme.dart`.
2. `AppException` hierarchy + classifier (`lib/core/errors/`), unit tests mapping every raw exception type per Part C.
3. `AppLogger` + ref-code generation, unit-tested redaction.
4. `showAetherSnackbar` (B#23) — used by nearly everything after.
5. Global safety net: `main.dart` (`runZonedGuarded`, `FlutterError.onError`, `ErrorWidget.builder`), router `errorBuilder` (`ErrorStateView` first draft).

**Stage 2 — Boot & auth (highest-visibility win, exercises both workstreams)**
6. Boot splash + init-failure page (B#1, `AE-DB01` path).
7. Route transitions via `AetherPage` (B#2).
8. Auth service classification + timeouts; login/signup inline errors, shake (B#8), `ProgressButton` (B#9), focus glow (B#7), entrance stagger (B#6).
8b. "Forgot password?" flow: link on login → email-entry screen → confirmation state, wired to existing `AuthService.resetPassword`, with its own error mapping (unknown email is NOT disclosed — always show "If that email exists, we sent a link").
9. Post-login success beat (B#10); session-expiry redirect snackbar.

**Stage 3 — Offline & sync resilience**
10. `connectivityProvider` + offline banner (B#24).
11. Sync isolation + retry/backoff + `syncStatusProvider`; Drift migration for attempt counter; sync-on-reconnect + 1-minute periodic timer (skipped while offline, backing off, or already syncing).
12. Sync status indicator in top bar (B#25); poisoned-row surface in settings (Keep mine / Discard per row).
12b. "Copy diagnostics" button in Settings (exports `AppLogger` ring buffer to clipboard); "Reduce motion" toggle in Settings (`SettingsService` flag consumed by `reduceMotion()`).

**Stage 4 — Screen consistency**
13. `AsyncValueWidget` + `ErrorStateView` final + skeletons (B#11); migrate dashboard, habits, academics, tasks screens one per commit.
14. Habit checkoff celebration (B#13), task complete (B#14).
15. Feature-service error classification sweep (remaining services).

**Stage 5 — Phase 2 animations** (B#12, 15, 17, 18, 19, 21, 3) — one per commit.

**Stage 6 — Phase 3 polish** (B#26–29, 4, 5, 16, 20, 22) — optional, order by appetite.

Validation per AEEP at every step: `flutter analyze` (no NEW issues beyond the ~104 pre-existing infos), `flutter pub get`, `flutter test` for compile validation (Windows/web builds unavailable in this environment), manual feature + regression pass on the touched screens.

---

## Part F — Decisions (confirmed 2026-08-01)

1. **Dependencies:** `flutter_animate` is APPROVED — add it and prefer it for staggers, one-shot effects (shake, celebration, entrances) where it's cleaner than raw controllers. No crash-reporting SaaS for now; local `AppLogger` only.
2. **Password reset:** IN SCOPE — build "Forgot password?" flow (login link → email entry → confirmation state) in Stage 2, wiring existing `AuthService.resetPassword`.
3. **Sync conflict policy:** ask-per-row CONFIRMED — dead-letter failed rows, badge sync indicator, Keep mine / Discard choice in Settings. Drift migration for attempt counter proceeds.
4. **Sync cadence:** on reconnect + **periodic every 1 minute while app is open** (timer paused when offline or backoff active; skip if a sync is already running).
5. **Reduced motion:** OS setting (`MediaQuery.disableAnimations`) OR manual "Reduce motion" toggle in Settings (new `SettingsService` flag) — either one on = motion off. `reduceMotion(context)` helper checks both.
6. **Diagnostics:** ADD "Copy diagnostics" button in Settings — copies last ~200 `AppLogger` ring-buffer entries + ref codes to clipboard.
7. **Milestone thresholds:** 7 / 30 / 100-day streaks for celebration B#29.
8. **Work order:** error-handling foundations first (Stages 1–4 error parts), animations layered on top — confirmed.

### Still open
- **Target device floor:** animations tuned for mid-range Android at 60 fps; Windows desktop gets identical transitions. Flag if there's a specific min device.
- **User's custom component wishlist:** user has specific components in mind (auth OTP verification screen, cursor animations, animated backgrounds, etc.) — to be provided and folded into this plan BEFORE implementation starts. OTP screen in particular adds a new auth route + its own error classes (code expired, wrong code, resend rate-limit).
