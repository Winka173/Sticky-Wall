import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../services/note_storage.dart';
import '../theme.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_views.dart';

const _kToastDuration = Duration(seconds: 3);

/// Type filter options: All (-1), Normal (0), Link (1) — same convention as
/// the original app.
const _typeOptions = [
  (key: -1, label: 'All'),
  (key: 0, label: 'Normal'),
  (key: 1, label: 'Link'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});

  final NoteStorage storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _uuid = const Uuid();

  List<Note> _notes = [];
  int _typeFilter = -1;
  bool _sortAscending = false;
  bool _gridView = false;
  int _wallIndex = 0;

  NoteStorage get _storage => widget.storage;
  WallStyle get _wall => walls[_wallIndex % walls.length];

  @override
  void initState() {
    super.initState();
    _notes = _storage.loadNotes();
    _typeFilter = _storage.typeFilter;
    _sortAscending = _storage.sortAscending;
    _gridView = _storage.gridView;
    _wallIndex = _storage.wallIndex % walls.length;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> get _visibleNotes {
    final search = _searchController.text.toLowerCase().trim();

    final filtered = _notes.where((note) {
      final matchesType = switch (_typeFilter) {
        0 => note.type == NoteType.normal,
        1 => note.type == NoteType.link,
        _ => true,
      };
      final matchesSearch = note.content.toLowerCase().contains(search) ||
          note.url.toLowerCase().contains(search);
      return matchesType && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      final byUrl =
          _sortAscending ? a.url.compareTo(b.url) : b.url.compareTo(a.url);
      if (byUrl != 0) return byUrl;
      return _sortAscending
          ? a.content.compareTo(b.content)
          : b.content.compareTo(a.content);
    });

    return filtered;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: _kToastDuration),
    );
  }

  Future<void> _addNote() async {
    final result = await showNoteDialog(context, existingNotes: _notes);
    if (result == null) return;

    setState(() {
      _notes.add(
        Note(guid: _uuid.v4(), content: result.content, url: result.url),
      );
    });
    await _storage.saveNotes(_notes);
    _toast('Add successfully');
  }

  Future<void> _editNote(Note note) async {
    final result =
        await showNoteDialog(context, existingNotes: _notes, note: note);
    if (result == null) return;

    setState(() {
      note.content = result.content;
      note.url = result.url;
    });
    await _storage.saveNotes(_notes);
    _toast('Update successfully');
  }

  void _deleteNote(Note note) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Are you sure to delete this note?'),
            duration: _kToastDuration,
            action: SnackBarAction(label: 'Yes', onPressed: () {}),
          ),
        )
        .closed
        .then((reason) async {
      if (reason != SnackBarClosedReason.action) return;
      setState(() => _notes.removeWhere((n) => n.guid == note.guid));
      await _storage.saveNotes(_notes);
      _toast('Delete successfully');
    });
  }

  void _toggleSort() {
    setState(() => _sortAscending = !_sortAscending);
    _storage.setSortAscending(_sortAscending);
  }

  void _toggleGrid() {
    setState(() => _gridView = !_gridView);
    _storage.setGridView(_gridView);
  }

  void _nextWall() {
    setState(() => _wallIndex = (_wallIndex + 1) % walls.length);
    _storage.setWallIndex(_wallIndex);
    _toast(_wall.label);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Text(
            'Sticky Wall',
            style: TextStyle(
              fontFamily: 'Pacifico',
              fontSize: 30,
              color: _wall.wallText,
              shadows: _wall.wallTextShadows,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Change wall',
            icon: Icon(Icons.wallpaper, color: _wall.wallText),
            onPressed: _nextWall,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final wallText = _wall.wallText;

    return Theme(
      data: wallControlsTheme(context, _wall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<int>(
                initialValue: _typeFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                dropdownColor: _wall.dropdownSurface,
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 17,
                  color: wallText,
                ),
                iconEnabledColor: wallText,
                items: [
                  for (final option in _typeOptions)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _typeFilter = value);
                  _storage.setTypeFilter(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: 'Search'),
                style: TextStyle(color: wallText, fontSize: 17),
              ),
            ),
            IconButton(
              tooltip: 'Sort',
              icon: Icon(
                _sortAscending ? Icons.filter_list_off : Icons.filter_list,
                color: wallText,
              ),
              onPressed: _toggleSort,
            ),
            IconButton(
              tooltip: _gridView ? 'List view' : 'Grid view',
              icon: Icon(
                _gridView ? Icons.format_list_bulleted : Icons.apps,
                color: wallText,
              ),
              onPressed: _toggleGrid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    final notes = _visibleNotes;

    if (notes.isEmpty) {
      return Center(
        child: Transform.rotate(
          angle: -0.03,
          child: Text(
            'No notes yet.\nTap "Add Note" to stick one on the wall!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              height: 1.4,
              color: _wall.wallTextFaded,
              shadows: _wall.wallTextShadows,
            ),
          ),
        ),
      );
    }

    if (_gridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 22,
          crossAxisSpacing: 18,
          childAspectRatio: 1.1,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteGridCard(
            note: note,
            onEdit: () => _editNote(note),
            onDelete: () => _deleteNote(note),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListTile(
          note: note,
          onEdit: () => _editNote(note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B5849),
        image: DecorationImage(
          image: AssetImage(_wall.asset),
          repeat: ImageRepeat.repeat,
          scale: 2.2,
        ),
      ),
      // The scrim quiets the texture so writing keeps its contrast.
      child: Container(
        color: _wall.overlay,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addNote,
            icon: const Icon(Icons.push_pin),
            label: const Text('Add Note', style: TextStyle(fontSize: 17)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildToolbar(),
                const SizedBox(height: 8),
                Expanded(child: _buildNotes()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
