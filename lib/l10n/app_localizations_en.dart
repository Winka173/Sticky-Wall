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
  String get typeNormal => 'Text';

  @override
  String get typeLink => 'Link';

  @override
  String get typeChecklist => 'To-do list';

  @override
  String get typeDrawing => 'Drawing';

  @override
  String get title => 'Title';

  @override
  String get contentHint => 'Write something…';

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
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get clear => 'Clear';

  @override
  String get contentRequired => 'Write something first';

  @override
  String get linkRequired => 'Add a link first';

  @override
  String get noteEmpty => 'The note is still empty';

  @override
  String get duplicateExists => 'This link is already on the wall';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get undo => 'Undo';

  @override
  String get emptyState =>
      'No notes yet.\nTap here to stick the first one on the wall!';

  @override
  String get wallCreateHint =>
      'Tip: long-press anywhere on the wall to stick a note right there.';

  @override
  String get noMatches => 'No notes match';

  @override
  String couldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String get customize => 'Customize';

  @override
  String get wallSection => 'Wall texture';

  @override
  String get fontSection => 'Font';

  @override
  String get languageSection => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortAZ => 'A → Z';

  @override
  String get sortZA => 'Z → A';

  @override
  String get layout => 'Layout';

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
  String get photo => 'Photo';

  @override
  String get fromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

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
  String get pin => 'Pin to top';

  @override
  String get unpin => 'Unpin';

  @override
  String get reminder => 'Reminder';

  @override
  String get addItem => 'Add item';

  @override
  String get penSize => 'Pen size';

  @override
  String get emote => 'Emote';

  @override
  String get color => 'Paper color';

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
  String get moveToBoard => 'Move to another board';

  @override
  String movedToBoard(String name) {
    return 'Moved to “$name”';
  }

  @override
  String get dataSection => 'Backup';

  @override
  String get exportData => 'Back up notes';

  @override
  String get importData => 'Restore backup';

  @override
  String get importHint => 'Paste a backup here';

  @override
  String get importSuccess => 'Restored successfully';

  @override
  String get importFailed => 'Could not read that backup';

  @override
  String get importReplaceWarning =>
      'Restoring replaces all current boards and notes.';
}
