import 'package:flutter/material.dart';
import 'package:aether/features/schedule/screens/schedule_screen.dart'
    show ScheduleScreen;
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
      backgroundColor: ScheduleScreen.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ScheduleScreen.cardBorder),
      ),
      title: const Text(
        'New Custom Template',
        style: TextStyle(color: ScheduleScreen.white, fontSize: 16),
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
              style: const TextStyle(
                color: ScheduleScreen.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Template name',
                hintStyle: const TextStyle(color: ScheduleScreen.grey),
                filled: true,
                fillColor: ScheduleScreen.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: ScheduleScreen.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: ScheduleScreen.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ScheduleScreen.red),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Icon',
              style: TextStyle(color: ScheduleScreen.grey, fontSize: 12),
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
                          ? ScheduleScreen.red.withOpacity(0.15)
                          : ScheduleScreen.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? ScheduleScreen.red
                            : ScheduleScreen.cardBorder,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 17,
                      color:
                          selected ? ScheduleScreen.red : ScheduleScreen.grey,
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
          child: const Text(
            'Cancel',
            style: TextStyle(color: ScheduleScreen.grey),
          ),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text(
            'Create',
            style: TextStyle(
              color: ScheduleScreen.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}