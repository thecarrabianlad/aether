import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/habits/widgets/add_habit_dialog.dart';
import 'package:aether/features/habits/models/habit_codec.dart'; // Import HabitCodec

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(globalAddActionProvider.notifier).state = () => _showAddHabitDialog();
    });
  }

  @override
  void dispose() {
    if (ref.read(globalAddActionProvider) == _showAddHabitDialog) {
      ref.read(globalAddActionProvider.notifier).state = null;
    }
    super.dispose();
  }

  Future<void> _showAddHabitDialog() async {
    final result = await showAddHabitDialog(context);
    if (result == null || !mounted) return;
    await ref.read(habitsServiceProvider).createHabit(
          name: result.name,
          category: result.category.name,
          icon: HabitCodec.iconToString(result.icon),
          color: HabitCodec.colorToString(result.color),
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
