import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/widgets/dashboard_top_bar.dart';
import 'package:aether/features/health/models/exercise.dart';
import 'package:aether/features/health/providers/health_providers.dart';

// Workouts persist through HealthService: writes go to the local Drift
// `workout_exercises` table first (instant UI update via weeklyPlanProvider's
// stream), then push to Supabase in the background — the same offline-first
// shape as AcademicsService / HabitsService.

// ── Screen ─────────────────────────────────────────────────────

class HealthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProfileTap;
  const HealthScreen({super.key, this.onProfileTap});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  AetherTheme get _aether => context.aether;

  void _addExerciseAction() =>
      _showExerciseDialog(ref.read(selectedWeekdayProvider));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(globalAddActionProvider.notifier).state = _addExerciseAction;
      }
    });
  }

  @override
  void dispose() {
    final notifier = ref.read(globalAddActionProvider.notifier);
    final action = _addExerciseAction;
    Future.microtask(() {
      if (notifier.state == action) notifier.state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final selectedDay = ref.watch(selectedWeekdayProvider);
    final planAsync = ref.watch(weeklyPlanProvider);

    return Container(
      color: aether.background,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            DashboardTopBar(onProfileTap: widget.onProfileTap ?? () {}),
            Expanded(
              child: planAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Could not load your workout plan.',
                      style: TextStyle(color: aether.textMuted)),
                ),
                data: (plan) {
                  final exercises = plan[selectedDay] ?? const <Exercise>[];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(aether),
                        const SizedBox(height: 20),
                        _buildWeekSummary(aether, plan),
                        const SizedBox(height: 20),
                        _buildDaySelector(aether, selectedDay, plan),
                        const SizedBox(height: 20),
                        _buildDayDetail(aether, selectedDay, exercises),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AetherTheme aether) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health',
            style: TextStyle(
                color: aether.text, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Plan your weekly workouts.',
            style: TextStyle(color: aether.textMuted, fontSize: 14)),
      ],
    );
  }

  // ── Weekly summary strip ──────────────────────────

  Widget _buildWeekSummary(
      AetherTheme aether, Map<Weekday, List<Exercise>> plan) {
    final allExercises = plan.values.expand((e) => e).toList();
    final total = allExercises.length;
    final done = allExercises.where((e) => e.isCompleted).length;
    final activeDays = plan.values.where((e) => e.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: aether.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryStat(aether, '$activeDays', 'Active days'),
          _summaryStat(aether, '$total', 'Exercises'),
          _summaryStat(aether, total == 0 ? '0%' : '${(done / total * 100).round()}%',
              'Done this week'),
        ],
      ),
    );
  }

  Widget _summaryStat(AetherTheme aether, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: aether.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: aether.textMuted, fontSize: 11)),
      ],
    );
  }

  // ── Day selector ───────────────────────────────────

  Widget _buildDaySelector(
      AetherTheme aether, Weekday selected, Map<Weekday, List<Exercise>> plan) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Weekday.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = Weekday.values[i];
          final isSelected = day == selected;
          final count = plan[day]?.length ?? 0;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedWeekdayProvider.notifier).state = day,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? aether.accent : aether.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day.short,
                      style: TextStyle(
                          color: isSelected ? Colors.white : aether.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count > 0
                          ? (isSelected ? Colors.white : aether.accent)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Selected day detail ────────────────────────────

  Widget _buildDayDetail(
      AetherTheme aether, Weekday day, List<Exercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${day.full} Workout',
                style: TextStyle(
                    color: aether.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => _showExerciseDialog(day),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: aether.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: aether.accent, size: 16),
                    const SizedBox(width: 4),
                    Text('Add Exercise',
                        style: TextStyle(
                            color: aether.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        exercises.isEmpty
            ? _emptyState(aether, 'Rest day — no exercises planned yet.')
            : Column(
                children: exercises
                    .map((e) => _ExerciseTile(
                          exercise: e,
                          accent: aether.accent,
                          onToggle: (v) => ref
                              .read(healthServiceProvider)
                              .toggleCompletion(e.id, v),
                          onTap: () => _showExerciseDialog(day, existing: e),
                          onDelete: () => ref
                              .read(healthServiceProvider)
                              .deleteExercise(e.id),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _emptyState(AetherTheme aether, String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.self_improvement, color: aether.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(msg,
              style: TextStyle(color: aether.textMuted, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Add / Edit Exercise dialog ─────────────────────

  void _showExerciseDialog(Weekday day, {Exercise? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    ExerciseType type = existing?.type ?? ExerciseType.reps;
    final formKey = GlobalKey<FormState>();

    // One row of controllers per set. Starts with the existing exercise's
    // sets when editing, or a single blank set when adding.
    final List<_SetInputRow> setRows = existing != null
        ? existing.sets.map((s) => _SetInputRow.fromEntry(s)).toList()
        : [_SetInputRow()];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _aether.surface,
          title: Text(existing == null ? 'Add Exercise' : 'Edit Exercise',
              style: TextStyle(color: _aether.text)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField('Exercise Name *', nameCtrl, required: true),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip('Reps & Weight', ExerciseType.reps,
                            type, (t) => setDialogState(() => type = t)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeChip('Timed Hold', ExerciseType.timed,
                            type, (t) => setDialogState(() => type = t)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(
                    setRows.length,
                    (i) => _buildSetRow(
                      index: i,
                      row: setRows[i],
                      type: type,
                      canDelete: setRows.length > 1,
                      onChanged: () => setDialogState(() {}),
                      onDelete: () => setDialogState(() => setRows.removeAt(i)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setDialogState(
                        () => setRows.add(_SetInputRow.copyLast(setRows))),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _aether.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('+ Add Set',
                          style: TextStyle(
                              color: _aether.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final sets = <SetEntry>[];
                for (final row in setRows) {
                  if (type == ExerciseType.reps) {
                    final weightText = row.weight.text.trim();
                    final weight =
                        weightText.isEmpty ? null : double.tryParse(weightText);
                    if (row.toFailure) {
                      sets.add(SetEntry(toFailure: true, weight: weight));
                    } else {
                      final reps = int.tryParse(row.reps.text.trim());
                      if (reps == null || reps <= 0) {
                        _showSnack(
                            'Enter reps for every set, or mark it Failure.');
                        return;
                      }
                      sets.add(SetEntry(reps: reps, weight: weight));
                    }
                  } else {
                    final duration = int.tryParse(row.duration.text.trim());
                    if (duration == null || duration <= 0) {
                      _showSnack('Enter a hold duration for every set.');
                      return;
                    }
                    sets.add(SetEntry(durationSeconds: duration));
                  }
                }

                final exercise = Exercise(
                  id: existing?.id ?? '',
                  name: nameCtrl.text.trim(),
                  type: type,
                  sets: sets,
                  isCompleted: existing?.isCompleted ?? false,
                );

                final service = ref.read(healthServiceProvider);
                if (existing == null) {
                  service.createExercise(
                    weekday: day.dbValue,
                    name: exercise.name,
                    type: exercise.type.dbValue,
                    setsJson: exercise.setsJson,
                  );
                } else {
                  service.updateExercise(
                    id: existing.id,
                    weekday: day.dbValue,
                    name: exercise.name,
                    type: exercise.type.dbValue,
                    setsJson: exercise.setsJson,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Add' : 'Save',
                  style: TextStyle(color: _aether.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow({
    required int index,
    required _SetInputRow row,
    required ExerciseType type,
    required bool canDelete,
    required VoidCallback onChanged,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _aether.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set ${index + 1}',
                    style: TextStyle(
                        color: _aether.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (canDelete)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.close,
                        color: _aether.textMuted, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (type == ExerciseType.timed)
              TextFormField(
                controller: row.duration,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
                style: TextStyle(color: _aether.text, fontSize: 13),
                decoration: _compactFieldDecoration('Duration (sec)'),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: row.reps,
                      enabled: !row.toFailure,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onChanged(),
                      style: TextStyle(color: _aether.text, fontSize: 13),
                      decoration: _compactFieldDecoration('Reps'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: row.weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => onChanged(),
                      style: TextStyle(color: _aether.text, fontSize: 13),
                      decoration: _compactFieldDecoration('Weight (kg)'),
                    ),
                  ),
                ],
              ),
            if (type == ExerciseType.reps) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  row.toFailure = !row.toFailure;
                  onChanged();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      row.toFailure
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: row.toFailure ? _aether.accent : _aether.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text('Take this set to failure',
                        style: TextStyle(
                            color: row.toFailure
                                ? _aether.accent
                                : _aether.textMuted,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _compactFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _aether.textMuted, fontSize: 11),
      filled: true,
      fillColor: _aether.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  Widget _typeChip(String label, ExerciseType value, ExerciseType groupValue,
      ValueChanged<ExerciseType> onChanged) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _aether.accent.withValues(alpha: 0.15)
              : _aether.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? _aether.accent : Colors.transparent, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? _aether.accent : _aether.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: _aether.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _aether.textMuted, fontSize: 12),
          filled: true,
          fillColor: _aether.surfaceAlt,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: _aether.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Dialog helper: one set's worth of input controllers ────────

class _SetInputRow {
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController duration;
  bool toFailure;

  _SetInputRow({
    String reps = '',
    String weight = '',
    String duration = '',
    this.toFailure = false,
  })  : reps = TextEditingController(text: reps),
        weight = TextEditingController(text: weight),
        duration = TextEditingController(text: duration);

  factory _SetInputRow.fromEntry(SetEntry e) => _SetInputRow(
        reps: e.reps?.toString() ?? '',
        weight: (e.weight != null && e.weight != 0) ? e.weight.toString() : '',
        duration: e.durationSeconds?.toString() ?? '',
        toFailure: e.toFailure,
      );

  /// New set row pre-filled from the previous one — most workouts repeat
  /// the same reps/weight across sets, so this saves re-typing.
  factory _SetInputRow.copyLast(List<_SetInputRow> rows) {
    if (rows.isEmpty) return _SetInputRow();
    final last = rows.last;
    return _SetInputRow(
      reps: last.reps.text,
      weight: last.weight.text,
      duration: last.duration.text,
      toFailure: last.toFailure,
    );
  }
}

// ── Extracted widget: Exercise tile ───────────────────────────

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final Color accent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExerciseTile({
    required this.exercise,
    required this.accent,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: aether.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onToggle(!exercise.isCompleted),
                child: Icon(
                  exercise.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: exercise.isCompleted ? accent : aether.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        style: TextStyle(
                            color: aether.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: exercise.isCompleted
                                ? TextDecoration.lineThrough
                                : null)),
                    const SizedBox(height: 2),
                    Text(exercise.subtitle,
                        style:
                            TextStyle(color: aether.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, color: aether.textMuted, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}