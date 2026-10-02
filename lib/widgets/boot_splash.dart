import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shown immediately at `runApp()` so the user never stares at a blank
/// screen while init runs. Simple widget with an optional [label] for
/// progress (e.g. "Preparing your data…").
class BootSplash extends StatelessWidget {
  const BootSplash({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAetherTheme(const AppThemeState()),
      title: 'AETHER',
      home: Material(
        color: aether.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo square — solid accent, rounded.
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: aether.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AETHER',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: aether.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.0,
                    ),
              ),
              if (label != null) ...[
                const SizedBox(height: 12),
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: aether.textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}