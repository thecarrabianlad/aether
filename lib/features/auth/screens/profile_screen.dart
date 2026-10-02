import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/habits/models/habit.dart';
import 'package:aether/features/habits/providers/habits_providers.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aether/core/models/profile.dart';

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
  final Profile? profile;
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

    final name = profile!.name;
    final role = profile!.role;
    final isPremium = profile!.isPremium;

    // Grab stats from the overview provider.
    final overview = overviewMetricsAsync.valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Header ────────────────────────────────────────
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickProfileImage(context, ref),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: aether.surfaceAlt,
                      backgroundImage: profile!.avatarUrl != null && profile!.avatarUrl!.startsWith('/')
                          ? FileImage(File(profile!.avatarUrl!)) as ImageProvider
                          : (profile!.avatarUrl != null && profile!.avatarUrl!.startsWith('http')
                              ? NetworkImage(profile!.avatarUrl!)
                              : null),
                      child: profile!.avatarUrl == null || profile!.avatarUrl!.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: aether.accent,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: aether.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: aether.background, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 16, color: aether.onAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: aether.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _editProfileDetails(context, ref, name, role),
                    child: Icon(Icons.edit, size: 16, color: aether.textMuted),
                  ),
                ],
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

  Future<void> _pickProfileImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final service = ref.read(profileServiceProvider);
        await service.upsertProfile(
          name: profile!.name,
          avatarUrl: pickedFile.path,
        );
        ref.read(profileProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _editProfileDetails(BuildContext context, WidgetRef ref, String currentName, String currentRole) async {
    final aether = context.aether;
    final nameController = TextEditingController(text: currentName);
    final roleController = TextEditingController(text: currentRole);
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Edit Profile', style: TextStyle(color: aether.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Enter new username',
                hintStyle: TextStyle(color: aether.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: aether.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: aether.accent),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roleController,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Profession (e.g. Student)',
                hintStyle: TextStyle(color: aether.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: aether.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: aether.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Cancel', style: TextStyle(color: aether.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop({
              'name': nameController.text.trim(),
              'role': roleController.text.trim(),
            }),
            child: Text('Save', style: TextStyle(color: aether.accent)),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final newName = result['name']!;
      final newRole = result['role']!;
      
      if (newName != currentName || newRole != currentRole) {
        final service = ref.read(profileServiceProvider);
        await service.upsertProfile(
          name: newName.isNotEmpty ? newName : currentName,
          role: newRole.isNotEmpty ? newRole : currentRole,
          avatarUrl: profile!.avatarUrl,
        );
        ref.read(profileProvider.notifier).refresh();
      }
    }
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
