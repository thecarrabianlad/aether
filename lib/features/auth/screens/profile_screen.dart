import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// User profile screen — avatar, stats, account actions.
///
/// Reads [profileProvider] for user data and [habitsProvider] for habit
/// statistics. Logout follows the same confirm-dialog pattern as
/// [SettingsScreen].
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;
    final profileAsync = ref.watch(profileProvider);
    final overviewMetricsAsync = ref.watch(overviewMetricsProvider);
    final email = ref.watch(authProvider).currentUser?.email ?? '—';

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: aether.text.withValues(alpha: 0.75)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: aether.text,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => _ProfileContent(
          profile: profile,
          overviewMetricsAsync: overviewMetricsAsync,
          email: email,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: aether.danger),
                const SizedBox(height: 12),
                Text(
                  'Could not load profile',
                  style: TextStyle(color: aether.text, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  style: TextStyle(color: aether.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: Text('Retry', style: TextStyle(color: aether.accent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final dynamic profile;
  final AsyncValue<OverviewMetrics> overviewMetricsAsync;
  final String email;

  const _ProfileContent({
    required this.profile,
    required this.overviewMetricsAsync,
    required this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;

    if (profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: 64, color: aether.textMuted),
            const SizedBox(height: 16),
            Text(
              'Set up your profile',
              style: TextStyle(color: aether.text, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Go to Settings to add your name.',
              style: TextStyle(color: aether.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final name = profile.name as String? ?? 'User';
    final role = profile.role as String? ?? 'Student';
    final isPremium = profile.isPremium as bool? ?? false;

    // Grab stats from the overview provider.
    final overview = overviewMetricsAsync.valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Header ────────────────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: aether.surfaceAlt,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: aether.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: aether.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: aether.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (isPremium) _PremiumBadge(aether: aether),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Stats ─────────────────────────────────────────
        Text(
          'Habit Stats',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: aether.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Today\'s\nCompletions',
                value: overview != null
                    ? '${overview.completedToday}/${overview.totalToday}'
                    : '—',
                color: aether.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Current\nStreak',
                value: overview != null ? '${overview.currentStreak}d' : '—',
                color: aether.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Longest\nStreak',
                value: overview != null ? '${overview.longestStreak}d' : '—',
                color: aether.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Weekly\nScore',
                value: overview != null ? '${overview.weeklyScore}%' : '—',
                color: aether.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Account ───────────────────────────────────────
        Text(
          'Account',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: aether.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _AccountTile(
          icon: Icons.alternate_email_rounded,
          title: 'Email',
          subtitle: email,
        ),
        const SizedBox(height: 8),

        // ── Logout ────────────────────────────────────────
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: Icon(Icons.logout_rounded, color: aether.danger, size: 18),
            label: Text(
              'Log Out',
              style: TextStyle(color: aether.danger, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: aether.danger.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final aether = context.aether;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: aether.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out?', style: TextStyle(color: aether.text)),
        content: Text(
          'You can log back in at any time.',
          style: TextStyle(color: aether.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: aether.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Log Out', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider).signOut();
    }
  }
}

class _PremiumBadge extends StatelessWidget {
  final AetherTheme aether;
  const _PremiumBadge({required this.aether});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCC5E5E).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFCC5E5E)),
          const SizedBox(width: 6),
          Text(
            'PREMIUM MEMBER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFCC5E5E).withValues(alpha: 0.9),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aether.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: aether.textMuted,
              fontSize: 10,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: aether.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: aether.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: aether.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: aether.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: aether.text, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
