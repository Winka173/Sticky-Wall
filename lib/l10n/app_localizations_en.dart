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
  String get noteDeleted => 'Moved to trash';

  @override
  String notesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes moved to trash',
      one: '1 note moved to trash',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String get dropToDelete => 'Drop here to delete';

  @override
  String get trash => 'Trash';

  @override
  String get trashEmpty => 'The trash is empty';

  @override
  String get trashHint => 'Notes here are deleted for good after 30 days.';

  @override
  String get restore => 'Restore';

  @override
  String get restored => 'Note restored';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String emptyTrashConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete all $count notes in the trash for good?',
      one: 'Delete the 1 note in the trash for good?',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String deletedOn(String date) {
    return 'Deleted $date';
  }

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNone => 'Once';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get select => 'Select notes';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get move => 'Move';

  @override
  String get tidy => 'Tidy up';

  @override
  String get tidyByColor => 'Arrange by color';

  @override
  String get moreActions => 'More';

  @override
  String get threadCut => 'Thread cut';

  @override
  String get threadTied => 'Thread tied';

  @override
  String get threadTip => 'Drag from a pin onto another note to tie a thread.';

  @override
  String get nightSection => 'Lights';

  @override
  String get nightModeOff => 'Always on';

  @override
  String get nightModeOn => 'Always off';

  @override
  String get nightModeSystem => 'Follow system';

  @override
  String get nightModeSchedule => 'On a schedule';

  @override
  String get lightsOff => 'Lights off';

  @override
  String get lightsOn => 'Lights on';

  @override
  String nightSchedule(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get nightStart => 'Lights off at';

  @override
  String get nightEnd => 'Lights on at';

  @override
  String get customWall => 'Your photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get autoTrashDone => 'Tidy finished to-do lists';

  @override
  String get autoTrashDoneHint =>
      'A list with every item ticked moves to the trash after a day.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get boardIcon => 'Board icon';

  @override
  String get none => 'None';

  @override
  String get sampleDrag =>
      'Drag me anywhere on the wall 👉\nLong-press an empty spot to stick a new note there.';

  @override
  String get sampleLongPress =>
      'Long-press me for more: move to another board, share, delete…';

  @override
  String get sampleChecklistTitle => 'Try ticking these ✅';

  @override
  String get sampleChecklist1 => 'Tap the red pin to keep a note on top';

  @override
  String get sampleChecklist2 => 'Drag the corner handle to resize';

  @override
  String get sampleChecklist3 => 'Delete us once you know the ropes';

  @override
  String get sampleThread =>
      'Drag from my pin onto another note to tie a thread 🧵';

  @override
  String get sampleDrawing => 'Doodles too ✏️';

  @override
  String get emptyState =>
      'No notes yet.\nTap here to stick the first one on the wall!';

  @override
  String get wallCreateHint =>
      'Tip: long-press anywhere on the wall to stick a note or a photo right there.';

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
  String get wallKraft => 'Kraft paper';

  @override
  String get wallMarble => 'Marble';

  @override
  String get wallTerrazzo => 'Terrazzo';

  @override
  String get wallDenim => 'Denim';

  @override
  String get wallFelt => 'Felt board';

  @override
  String get wallLinen => 'Dark linen';

  @override
  String get wallCardboard => 'Cardboard';

  @override
  String get wallCement => 'Cement wall';

  @override
  String get wallCotton => 'White cotton';

  @override
  String get wallPaper => 'White paper';

  @override
  String get wallMoss => 'Moss';

  @override
  String get wallLeather => 'Red leather';

  @override
  String get wallDarkMarble => 'Dark marble';

  @override
  String get wallDarkWood => 'Dark planks';

  @override
  String get wallTiles => 'Checker tiles';

  @override
  String get fontPreview => 'Hello! A quick note on the wall.';

  @override
  String get fromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get typePhoto => 'Photo';

  @override
  String get typeLabel => 'Label';

  @override
  String get labelHint => 'Column or section name…';

  @override
  String get lockInPlace => 'Lock in place';

  @override
  String get unlock => 'Unlock';

  @override
  String get thread => 'Thread';

  @override
  String get yarnColor => 'Yarn color';

  @override
  String get threadLabelHint => 'Write on the thread…';

  @override
  String get threadArrow => 'Arrowhead';

  @override
  String get cutThread => 'Cut thread';

  @override
  String get drawOnWall => 'Draw on the wall';

  @override
  String get done => 'Done';

  @override
  String get caption => 'Caption';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get replacePhoto => 'Replace photo';

  @override
  String get photoRequired => 'Add a photo';

  @override
  String get pinPhotos => 'Pin photos on the wall';

  @override
  String get noteHere => 'Sticky note here';

  @override
  String get photosHere => 'Photos here';

  @override
  String get viewPhoto => 'View photo';

  @override
  String get rotate => 'Rotate';

  @override
  String photosPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos pinned on the wall',
      one: '1 photo pinned on the wall',
    );
    return '$_temp0';
  }

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get saveImage => 'Save image';

  @override
  String get exportBoard => 'Export board as image';

  @override
  String get exportWholeWall => 'Whole wall';

  @override
  String get exportVisible => 'Part in view';

  @override
  String get exportAllNotes => 'All notes';

  @override
  String exportSelectedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get sharePdf => 'Share as PDF';

  @override
  String get cropImage => 'Trim';

  @override
  String get cropHint =>
      'Drag the corners or edges to trim the picture; drag inside to move the frame.';

  @override
  String get cropReset => 'Whole picture';

  @override
  String get putOnHomeScreen => 'Show on the home-screen widget';

  @override
  String get widgetUpdated => 'Home-screen widget updated';

  @override
  String get widgetUpdateFailed => 'Could not update the widget';

  @override
  String get bullets => 'Bullet list';

  @override
  String get exportHint =>
      'Just the wall, its notes and threads — no toolbars. Share it, or save it to your gallery.';

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
  String get eraser => 'Eraser';

  @override
  String get redo => 'Redo';

  @override
  String get canvasSection => 'Canvas paper';

  @override
  String get patternPlain => 'Plain';

  @override
  String get patternRuled => 'Ruled';

  @override
  String get patternGrid => 'Grid';

  @override
  String get patternDots => 'Dots';

  @override
  String get emote => 'Emote';

  @override
  String get color => 'Paper color';

  @override
  String get newBoard => 'New board';

  @override
  String get boardName => 'Board name';

  @override
  String get editBoard => 'Edit board';

  @override
  String get nameStyle => 'Name style';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get underline => 'Underline';

  @override
  String get defaultBoardName => 'My Wall';

  @override
  String get deleteBoard => 'Delete board';

  @override
  String deleteBoardConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get moveToBoard => 'Move to another board';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get copy => 'Copy';

  @override
  String get copyToBoard => 'Copy to another board';

  @override
  String copiedToBoard(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count notes to “$name”',
      one: 'Copied 1 note to “$name”',
    );
    return '$_temp0';
  }

  @override
  String get fitAll => 'Show everything';

  @override
  String get gestureTips => 'Gesture tips';

  @override
  String get gotIt => 'Got it';

  @override
  String get tipDragTitle => 'Move, turn, resize';

  @override
  String get tipDragBody =>
      'Drag a note with one finger. Put two fingers on it to twist and pinch, or use the grips at its bottom corners: resize on the right, rotate on the left (tap that one to square the note up).';

  @override
  String get tipPinTitle => 'Pins and threads';

  @override
  String get tipPinBody =>
      'Tap the pin to keep a note on top. Drag from a pin onto another note to tie a thread; tap a thread to colour it, write on it, add an arrowhead or cut it.';

  @override
  String get tipWallTitle => 'The wall';

  @override
  String get tipWallBody =>
      'Long-press an empty spot to stick a note or photos there. Pinch to zoom, pan out to the wall’s margins and park notes there. Double-tap a note to zoom in on it; the frame button shows everything.';

  @override
  String get tipDropTitle => 'Drop to delete or move';

  @override
  String get tipDropBody =>
      'Drag a note down near the foot of the wall and a small tray appears; drop the note on it to delete. Drop on a board tab instead to move it to that board.';

  @override
  String get tipSelectTitle => 'Select several';

  @override
  String get tipSelectBody =>
      'Long-press a note → Select. Draw a loop round notes on empty wall to add them, and drag any selected note to move the whole group.';

  @override
  String get tipDrawTitle => 'Draw on the wall';

  @override
  String get tipDrawBody =>
      'The pen in the toolbar starts marker mode: one finger draws behind the notes, two still zoom. Undo, clear and done sit in the bar below.';

  @override
  String get tipUndoTitle => 'Undo';

  @override
  String get tipUndoBody =>
      'An Undo pill appears for a few seconds after every move, turn, resize, tidy-up or board change.';

  @override
  String movedToBoard(String name) {
    return 'Moved to “$name”';
  }

  @override
  String get dataSection => 'Backup';

  @override
  String get exportData => 'Back up notes';

  @override
  String get importData => 'Load backup';

  @override
  String get importHint => 'Paste a backup here';

  @override
  String get importSuccess => 'Backup loaded';

  @override
  String get importFailed => 'Could not read that backup';

  @override
  String get importReplaceWarning =>
      'Loading a backup replaces all current boards and notes.';

  @override
  String get importChooseFile => 'Choose file';

  @override
  String get importNotJson =>
      'This isn\'t a backup file: the text is not valid JSON. Paste the whole file, with nothing cut off.';

  @override
  String get importNotBackup => 'This isn\'t a Sticky Wall backup.';

  @override
  String get importNewerVersion =>
      'This backup was made by a newer version of Sticky Wall. Update the app, then try again.';

  @override
  String get backupFailed => 'Could not make the backup';

  @override
  String get backupShareSubject => 'Sticky Wall backup';

  @override
  String restoredTo(String board) {
    return 'Restored to “$board”';
  }

  @override
  String get shareFailed => 'Could not share';

  @override
  String get share => 'Share';

  @override
  String get cropDone => 'Finish trimming';

  @override
  String get penThin => 'Thin pen';

  @override
  String get penMedium => 'Medium pen';

  @override
  String get penThick => 'Thick pen';

  @override
  String get colorInk => 'Ink';

  @override
  String get colorChalk => 'Chalk white';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorPink => 'Pink';

  @override
  String get toneWhite => 'White paper';

  @override
  String get toneCream => 'Cream paper';

  @override
  String get toneBlush => 'Blush paper';

  @override
  String get toneSky => 'Sky paper';

  @override
  String get toneMint => 'Mint paper';

  @override
  String get toneKraft => 'Kraft paper';

  @override
  String get toneChalkboard => 'Chalkboard';

  @override
  String get discardChangesTitle => 'Discard your changes?';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get deleteForeverConfirm =>
      'Delete this note for good? It can\'t be brought back.';

  @override
  String deleteBoardWithNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Its $count notes are deleted for good — they don\'t go to the trash.',
      one: 'Its note is deleted for good — it doesn\'t go to the trash.',
    );
    return '$_temp0';
  }

  @override
  String get reminderInPast => 'That time has passed — pick a later one.';

  @override
  String get notificationsOff =>
      'Notifications are off for Sticky Wall, so this reminder won\'t ring. Turn them on in the phone\'s settings.';

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String typeChangeDrops(String type) {
    return 'Save as “$type”? Its drawing or link address won\'t be kept.';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get paperAuto => 'Automatic colour';

  @override
  String get paperYellow => 'Yellow';

  @override
  String get paperPink => 'Pink';

  @override
  String get paperMint => 'Mint';

  @override
  String get paperBlue => 'Blue';

  @override
  String get paperOrange => 'Orange';

  @override
  String get paperLilac => 'Lilac';

  @override
  String get swatchRed => 'Red';

  @override
  String get swatchOrange => 'Orange';

  @override
  String get swatchGold => 'Gold';

  @override
  String get swatchGreen => 'Green';

  @override
  String get swatchBlue => 'Blue';

  @override
  String get swatchPurple => 'Purple';

  @override
  String get swatchInk => 'Ink';

  @override
  String get swatchChalk => 'Chalk';

  @override
  String get locked => 'Locked';

  @override
  String get selectHint => 'Tap notes, or draw a loop round them';

  @override
  String filterShowing(String what) {
    return 'Showing: $what';
  }

  @override
  String get clearFilter => 'Clear';

  @override
  String get undoMove => 'Undo move';

  @override
  String get undoResize => 'Undo resize';

  @override
  String get undoRotate => 'Undo turn';

  @override
  String get undoTidy => 'Undo tidy';

  @override
  String get undoMoveBoard => 'Undo move to board';

  @override
  String get clearInkConfirm => 'Wipe everything drawn on this wall?';

  @override
  String get photoMissing => 'Photo not found on this device';

  @override
  String get photoPickFailed => 'Couldn\'t open that photo';

  @override
  String get sizeAndTurn => 'Size and turn';

  @override
  String get smaller => 'Smaller';

  @override
  String get larger => 'Larger';

  @override
  String get turnLeft => 'Turn left';

  @override
  String get turnRight => 'Turn right';

  @override
  String get straighten => 'Straighten';

  @override
  String get tieThreadTo => 'Tie a thread to…';

  @override
  String get threadsOfNote => 'Threads';

  @override
  String get noOtherNotes => 'No other notes on this wall to tie to';

  @override
  String get moveBoardLeft => 'Move left';

  @override
  String get moveBoardRight => 'Move right';

  @override
  String get resize => 'Resize';

  @override
  String get untitledNote => 'Untitled note';

  @override
  String get remindersChannel => 'Reminders';

  @override
  String get remindersChannelDescription => 'Reminders you set on your notes';
}
