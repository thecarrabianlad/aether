import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    // Temporarily removed globalAddActionProvider assignment
  }

  @override
  void dispose() {
    // Temporarily removed globalAddActionProvider check
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Scaffold(
      backgroundColor: aether.background,
      body: Center(
        child: Text('Health Screen', style: TextStyle(color: aether.text)),
      ),
    );
  }
}
