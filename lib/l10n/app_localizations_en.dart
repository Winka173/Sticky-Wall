// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sticky Wall';

  @override
  String get addNote => 'Add Note';

  @override
  String get search => 'Search';

  @override
  String get type => 'Type';

  @override
  String get typeAll => 'All';

  @override
  String get typeNormal => 'Normal';

  @override
  String get typeLink => 'Link';

  @override
  String get createNote => 'Create Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get content => 'Content';

  @override
  String get contentHint => 'Note something...';

  @override
  String get link => 'Link';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get contentRequired => 'Content is required';

  @override
  String get linkRequired => 'Link is required';

  @override
  String get duplicateExists => 'This content or link already exists';

  @override
  String get addSuccess => 'Added successfully';

  @override
  String get updateSuccess => 'Updated successfully';

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get deleteConfirm => 'Delete this note?';

  @override
  String get yes => 'Yes';

  @override
  String get emptyState =>
      'No notes yet.\nTap “Add Note” to stick one on the wall!';

  @override
  String couldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String get customize => 'Customize';

  @override
  String get wallSection => 'Wall';

  @override
  String get fontSection => 'Font';

  @override
  String get languageSection => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get listView => 'List view';

  @override
  String get gridView => 'Grid view';

  @override
  String get wallCork => 'Cork board';

  @override
  String get wallChalkGreen => 'Green chalkboard';

  @override
  String get wallChalkBlack => 'Black chalkboard';

  @override
  String get wallPlaster => 'Painted wall';

  @override
  String get wallBrick => 'Brick wall';

  @override
  String get wallWood => 'Wood planks';

  @override
  String get fontPreview => 'Hello! A quick note on the wall.';
}
