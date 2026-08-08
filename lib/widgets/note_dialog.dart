import 'package:flutter/material.dart';

import '../models/note.dart';

/// Result returned by [showNoteDialog] when the user saves.
class NoteDialogResult {
  NoteDialogResult({required this.content, required this.url});

  final String content;
  final String url;
}

/// Opens the Create/Edit Note dialog. Returns null when cancelled.
///
/// [existingNotes] is used to reject duplicates: a note with the same content
/// (or the same URL for link notes) may not be added twice. When editing,
/// the note being edited is excluded from that check.
Future<NoteDialogResult?> showNoteDialog(
  BuildContext context, {
  required List<Note> existingNotes,
  Note? note,
}) {
  return showDialog<NoteDialogResult>(
    context: context,
    builder: (context) => _NoteDialog(existingNotes: existingNotes, note: note),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.existingNotes, this.note});

  final List<Note> existingNotes;
  final Note? note;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;
  late final TextEditingController _urlController;
  late NoteType _type;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    _type = widget.note?.type ?? NoteType.normal;
    _contentController = TextEditingController(text: widget.note?.content);
    _urlController = TextEditingController(text: widget.note?.url);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool _isDuplicate(String content, String url) {
    return widget.existingNotes.any((n) {
      if (n.guid == widget.note?.guid) return false;
      if (_type == NoteType.link) {
        return n.url == url || n.content == content;
      }
      return n.content == content;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    final url = _type == NoteType.link ? _urlController.text.trim() : '';

    if (_isDuplicate(content, url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content or Link is already existed'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.of(context).pop(NoteDialogResult(content: content, url: url));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Note' : 'Create Note'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: NoteType.normal,
                    child: Text('Normal'),
                  ),
                  DropdownMenuItem(value: NoteType.link, child: Text('Link')),
                ],
                onChanged: (type) {
                  if (type == null) return;
                  setState(() {
                    _type = type;
                    if (type == NoteType.normal) {
                      _urlController.text = '';
                    } else {
                      _urlController.text = widget.note?.url ?? '';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Note something...',
                ),
                maxLines: _type == NoteType.normal ? 4 : 1,
                minLines: 1,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Content is required'
                    : null,
              ),
              if (_type == NoteType.link) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'Link'),
                  keyboardType: TextInputType.url,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Link is required'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
