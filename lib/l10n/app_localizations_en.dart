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
  String get typeChecklist => 'Checklist';

  @override
  String get createNote => 'Create Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get content => 'Content';

  @override
  String get title => 'Title';

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
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

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
  String get noteDeleted => 'Note deleted';

  @override
  String get undo => 'Undo';

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
  String get viewWall => 'Wall';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'List';

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

  @override
  String get emote => 'Emote';

  @override
  String get typeDrawing => 'Drawing';

  @override
  String get photo => 'Photo';

  @override
  String get fromGallery => 'Gallery';

  @override
  String get takePhoto => 'Camera';

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get saveImage => 'Save image';

  @override
  String get imageSaved => 'Saved to gallery';

  @override
  String get imageSaveFailed => 'Could not save image';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get wallDecor => 'Wall stains & marks';

  @override
  String get color => 'Paper color';

  @override
  String get colorAuto => 'Auto';

  @override
  String get pin => 'Pin to top';

  @override
  String get reminder => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get clearReminder => 'Clear';

  @override
  String get checklistItems => 'Items';

  @override
  String get addItem => 'Add item';

  @override
  String get sortByCreated => 'Newest first';

  @override
  String get sortByName => 'By name';

  @override
  String get sortAsc => 'Ascending';

  @override
  String get sortDesc => 'Descending';

  @override
  String get boards => 'Boards';

  @override
  String get newBoard => 'New board';

  @override
  String get boardName => 'Board name';

  @override
  String get defaultBoardName => 'My Wall';

  @override
  String get deleteBoard => 'Delete board';

  @override
  String deleteBoardConfirm(String name) {
    return 'Delete “$name” and all its notes?';
  }

  @override
  String get dataSection => 'Backup';

  @override
  String get exportData => 'Export notes';

  @override
  String get importData => 'Import notes';

  @override
  String get importHint => 'Paste a backup here';

  @override
  String get importSuccess => 'Imported successfully';

  @override
  String get importFailed => 'Could not read that backup';

  @override
  String get importReplaceWarning =>
      'Importing replaces all current boards and notes.';
}
