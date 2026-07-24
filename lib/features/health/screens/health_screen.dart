import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/habits/providers/habits_providers.dart'; // Added for habits provider
import 'package:aether/features/habits/widgets/add_habit_dialog.dart'; // Added for habits dialog

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    // Register the habit add action for the global Add button as a default
    Future.microtask(() {
      ref.read(globalAddActionProvider.notifier).state = () => _showAddHabitDialog();
    });
  }

  @override
  void dispose() {
    // Clear the action when leaving the screen if it's still this screen's action
    if (ref.read(globalAddActionProvider) == _showAddHabitDialog) {
      ref.read(globalAddActionProvider.notifier).state = null;
    }
    super.dispose();
  }

  Future<void> _showAddHabitDialog() async {
    final result = await showAddHabitDialog(context);
    if (result == null || !mounted) return;
    ref.read(habitsProvider.notifier).createHabit(
          name: result.name,
          category: result.category,
          icon: result.icon,
          color: result.color,
        );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Health Screen — Coming Soon',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
