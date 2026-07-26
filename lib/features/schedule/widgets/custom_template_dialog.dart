import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/schedule/widgets/schedule_options.dart';

class CustomTemplateResult {
  final String title;
  final String icon;
  const CustomTemplateResult({required this.title, required this.icon});
}

Future<CustomTemplateResult?> showCustomTemplateDialog(BuildContext context) {
  return showDialog<CustomTemplateResult>(
    context: context,
    builder: (_) => const _CustomTemplateDialog(),
  );
}

class _CustomTemplateDialog extends StatefulWidget {
  const _CustomTemplateDialog();

  @override
  State<_CustomTemplateDialog> createState() => _CustomTemplateDialogState();
}

class _CustomTemplateDialogState extends State<_CustomTemplateDialog> {
  final _titleController = TextEditingController();
  String _icon = 'other';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _confirm() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      CustomTemplateResult(title: title, icon: _icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.aether.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.aether.border),
      ),
      title: Text(
        'New Custom Template',
        style: TextStyle(color: context.aether.text, fontSize: 16),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                color: context.aether.text,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Template name',
                hintStyle: TextStyle(color: context.aether.textMuted),
                filled: true,
                fillColor: context.aether.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: context.aether.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: context.aether.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.aether.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: TextStyle(color: context.aether.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kScheduleIconOptions.entries.map((entry) {
                final selected = _icon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _icon = entry.key),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? context.aether.accent.withValues(alpha: 0.15)
                          : context.aether.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? context.aether.accent
                            : context.aether.border,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 17,
                      color:
                          selected ? context.aether.accent : context.aether.textMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.aether.textMuted),
          ),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(
            'Create',
            style: TextStyle(
              color: context.aether.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}