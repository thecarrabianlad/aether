import 'package:aether/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:aether/features/schedule/screens/schedule_screen.dart'
    show ScheduleScreen;

void showBlockOptionsSheet(
  BuildContext context, {
  required String blockTitle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _BlockOptionsSheet(
      blockTitle: blockTitle,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}

class _BlockOptionsSheet extends StatelessWidget {
  final String blockTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BlockOptionsSheet({
    required this.blockTitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: context.aether.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: context.aether.border),
          left: BorderSide(color: context.aether.border),
          right: BorderSide(color: context.aether.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.aether.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            blockTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.aether.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),
          _OptionTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: ScheduleScreen.red,
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.aether.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.aether.border),
        ),
        title: Text(
          'Delete time block?',
          style: TextStyle(color: context.aether.text),
        ),
        content: Text(
          '"$blockTitle" will be removed from this device and your account.',
          style: TextStyle(color: context.aether.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.aether.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: ScheduleScreen.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.aether.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}