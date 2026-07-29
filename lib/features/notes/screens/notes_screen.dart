import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/notes/providers/notes_providers.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notes',
            style: TextStyle(
                color: aether.text, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: aether.textMuted),
            onPressed: () => _showSearchDialog(aether),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: aether.accent)),
        error: (e, _) => Center(
          child: Text('Could not load notes',
              style: TextStyle(color: aether.textMuted)),
        ),
        data: (notes) {
          final filtered = _searchQuery.isEmpty
              ? notes
              : notes
                  .where((n) =>
                      n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      n.content
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                  .toList();

          if (filtered.isEmpty) {
            return _buildEmpty(aether);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _NoteCard(
              note: filtered[i],
              onTap: () => _openNoteEditor(filtered[i]),
              onDelete: () => _deleteNote(filtered[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(null),
        backgroundColor: aether.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(AetherTheme aether) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes_rounded, color: aether.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No notes yet',
                style: TextStyle(color: aether.textMuted, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + to create your first note',
                style: TextStyle(color: aether.textMuted, fontSize: 13)),
          ],
        ),
      );

  void _showSearchDialog(AetherTheme aether) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Search Notes', style: TextStyle(color: aether.text)),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: aether.text),
          decoration: InputDecoration(
            hintText: 'Search by title or content...',
            hintStyle: TextStyle(color: aether.textMuted),
            filled: true,
            fillColor: aether.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: aether.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _openNoteEditor(Note? note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditorSheet(
        note: note,
        onSave: (title, content) async {
          final service = ref.read(notesServiceProvider);
          if (note == null) {
            await service.createNote(title: title, content: content);
          } else {
            await service.updateNote(note.copyWith(title: title, content: content));
          }
        },
      ),
    );
  }

  void _deleteNote(Note note) {
    final aether = context.aether;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Delete Note', style: TextStyle(color: aether.text)),
        content: Text('Delete "${note.title}"?',
            style: TextStyle(color: aether.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesServiceProvider).deleteNote(note.id);
            },
            child: Text('Delete', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final preview = note.content.length > 120
        ? '${note.content.substring(0, 120)}...'
        : note.content;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title,
                style: TextStyle(
                    color: aether.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(preview,
                  style: TextStyle(color: aether.textMuted, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(note.updatedAt),
              style: TextStyle(color: aether.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  final Note? note;
  final Future<void> Function(String title, String content) onSave;

  const _NoteEditorSheet({this.note, required this.onSave});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(_titleCtrl.text.trim(), _contentCtrl.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: aether.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: aether.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.note == null ? 'New Note' : 'Edit Note',
              style: TextStyle(
                  color: aether.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: aether.textMuted),
                filled: true,
                fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              style: TextStyle(color: aether.text),
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Write your note...',
                hintStyle: TextStyle(color: aether.textMuted),
                filled: true,
                fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: aether.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
