import 'package:aether/widgets/common/async_value_widget.dart';
import 'package:aether/widgets/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/academics/providers/academics_providers.dart';
import 'package:aether/features/academics/widgets/grade_tile.dart'; import 'package:aether/features/academics/widgets/add_edit_grade_dialog.dart';
import 'package:aether/features/academics/widgets/grade_tile.dart';

class GradesScreen extends ConsumerWidget {
  final String courseId;
  final String courseName; // To display in the app bar

  const GradesScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;
    final gradesAsync = ref.watch(gradesProvider(courseId));

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: aether.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: aether.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '$courseName Grades',
          style: TextStyle(color: aether.text, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: aether.accent),
            onPressed: () {
              // TODO: Implement add grade dialog
              _showAddGradeDialog(context, ref, courseId);
            },
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: gradesAsync,
        loadingSkeleton: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SkeletonTile(),
              SizedBox(height: 8),
              SkeletonTile(),
              SizedBox(height: 8),
              SkeletonTile(),
            ],
          ),
        ),
        data: (grades) {
          if (grades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade_outlined, color: aether.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No grades recorded yet.',
                    style: TextStyle(color: aether.textMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement add grade dialog
                      _showAddGradeDialog(context, ref, courseId);
                    },
                    icon: Icon(Icons.add, color: aether.onAccent),
                    label: Text(
                      'Add First Grade',
                      style: TextStyle(color: aether.onAccent),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aether.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return GradeTile(
                grade: grade,
                onEdit: () {
                  // TODO: Implement edit grade dialog
                  _showEditGradeDialog(context, ref, grade);
                },
                onDelete: () {
                  // TODO: Implement delete grade confirmation
                  _confirmDeleteGrade(context, ref, grade);
                },
              );
            },
          );
        },
        onRetry: () => ref.invalidate(gradesProvider(courseId)),
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context, WidgetRef ref, String courseId) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditGradeDialog(courseId: courseId),
    );
  }

  void _showEditGradeDialog(BuildContext context, WidgetRef ref, Grade grade) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditGradeDialog(courseId: grade.courseId, gradeToEdit: grade),
    );
  }

  void _confirmDeleteGrade(BuildContext context, WidgetRef ref, Grade grade) {
    final aether = context.aether;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Delete Grade', style: TextStyle(color: aether.text)),
        content: Text(
            'Are you sure you want to delete the grade "${grade.title}"?',
            style: TextStyle(color: aether.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(academicsServiceProvider)
                  .deleteGrade(grade.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Basic SkeletonTile for loading states - can be moved to common widgets later
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: context.aether.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
