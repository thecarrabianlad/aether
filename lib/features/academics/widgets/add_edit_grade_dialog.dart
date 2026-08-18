import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/widgets/dialog_field.dart';

class AddEditGradeDialog extends ConsumerStatefulWidget {
  final String courseId;
  final Grade? gradeToEdit; // If null, it's an add operation

  const AddEditGradeDialog({
    super.key,
    required this.courseId,
    this.gradeToEdit,
  });

  @override
  ConsumerState<AddEditGradeDialog> createState() => _AddEditGradeDialogState();
}

class _AddEditGradeDialogState extends ConsumerState<AddEditGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _gradeValueController;
  late TextEditingController _totalPointsController;
  late TextEditingController _weightController;
  late TextEditingController _feedbackController;
  DateTime? _gradedAt;

  bool get isEditing => widget.gradeToEdit != null;
  AetherTheme get _aether => Theme.of(context).extension<AetherTheme>()!;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.gradeToEdit?.title ?? '');
    _gradeValueController = TextEditingController(
        text: widget.gradeToEdit?.gradeValue?.toString() ?? '');
    _totalPointsController = TextEditingController(
        text: widget.gradeToEdit?.totalPoints?.toString() ?? '');
    _weightController = TextEditingController(
        text: widget.gradeToEdit?.weight?.toString() ?? '1.0');
    _feedbackController =
        TextEditingController(text: widget.gradeToEdit?.feedback ?? '');
    _gradedAt = widget.gradeToEdit?.gradedAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _gradeValueController.dispose();
    _totalPointsController.dispose();
    _weightController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _gradedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: _aether.accent),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && pickedDate != _gradedAt) {
      setState(() {
        _gradedAt = pickedDate;
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: _aether.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _aether.surface,
      title: Text(isEditing ? 'Edit Grade' : 'Add Grade',
          style: TextStyle(color: _aether.text)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogField(
                controller: _titleController,
                labelText: 'Title *',
                validator: (value) =>
                    value!.isEmpty ? 'Title is required' : null,
              ),
              DialogField(
                controller: _gradeValueController,
                labelText: 'Grade Value',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
              DialogField(
                controller: _totalPointsController,
                labelText: 'Total Points',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
              DialogField(
                controller: _weightController,
                labelText: 'Weight',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
              DialogField(
                controller: _feedbackController,
                labelText: 'Feedback',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildDateTimeField(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: _aether.textMuted)),
        ),
        ElevatedButton(
          onPressed: _saveGrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: _aether.accent,
            foregroundColor: _aether.onAccent,
          ),
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _aether.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _aether.textMuted, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _gradedAt == null
                    ? 'Graded At'
                    : DateFormat('dd MMM yyyy').format(_gradedAt!),
                style: TextStyle(
                  color: _gradedAt == null ? _aether.textMuted : _aether.text,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final academicsService = ref.read(academicsServiceProvider);

    final gradeValue = double.tryParse(_gradeValueController.text);
    final totalPoints = double.tryParse(_totalPointsController.text);
    final weight = double.tryParse(_weightController.text) ?? 1.0;
    final feedback =
        _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim();

    try {
      if (isEditing) {
        final updatedGrade = widget.gradeToEdit!.copyWith(
          title: _titleController.text.trim(),
          gradeValue: gradeValue!= null? Value(gradeValue) : const Value.absent(),
          totalPoints: totalPoints!= null? Value(totalPoints) : const Value.absent(),
          weight: Value(weight),
          feedback: feedback!= null? Value(feedback) : const Value.absent(),
          gradedAt: _gradedAt!= null? Value(_gradedAt) : const Value.absent(),
        );
        await academicsService.updateGrade(updatedGrade);
      } else {
        await academicsService.createGrade(
          courseId: widget.courseId,
          title: _titleController.text.trim(),
          gradeValue: gradeValue,
          totalPoints: totalPoints,
          weight: weight,
          feedback: feedback,
          gradedAt: _gradedAt,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to ${isEditing ? 'save' : 'add'} grade: $e');
      }
    }
  }
}