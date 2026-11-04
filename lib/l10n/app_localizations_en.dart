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
  String get dragToDelete => 'Drag to the foot to delete';

  @override
  String get dragToDeleteHint =>
      'A tray comes up at the foot of the wall; drop a note on it to delete it (Undo is offered).';

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
  String get exportPdf => 'Export PDF';

  @override
  String get exportMore => 'More options';

  @override
  String get exportFewer => 'Fewer options';

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
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

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
      'Tap the pin to keep a note on top. Drag from a pin onto another note to tie a thread; tap a thread to color it, write on it, add an arrowhead or cut it.';

  @override
  String get tipWallTitle => 'The wall';

  @override
  String get tipWallBody =>
      'Long-press an empty spot to stick a note or photos there. Pinch to zoom, pan out to the wall’s margins and park notes there. Double-tap a note to zoom in on it; the frame button shows everything.';

  @override
  String get tipDropTitle => 'Move to another board';

  @override
  String get tipDropBody =>
      'Drop a dragged note on a board tab to move it to that board. Deleting by dragging it to a tray at the foot of the wall can be switched on in Customize.';

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
  String get typeAudio => 'Voice note';

  @override
  String get recordHint => 'Tap to record, or hold and let go';

  @override
  String get recordStart => 'Start recording';

  @override
  String get recordStop => 'Stop recording';

  @override
  String get recordingNow => 'Recording';

  @override
  String get recordAgain => 'Record again';

  @override
  String get deleteRecording => 'Delete recording';

  @override
  String get playVoice => 'Play voice note';

  @override
  String get pauseVoice => 'Pause voice note';

  @override
  String get recordingRequired => 'Record something first';

  @override
  String get micDenied =>
      'The microphone is off for Sticky Wall. Allow it in the phone\'s settings to record.';

  @override
  String get recordFailed => 'Could not record. Try again.';

  @override
  String get recordingMissing => 'This recording is no longer on the device';

  @override
  String get autoBackup => 'Automatic weekly backup';

  @override
  String get autoBackupHint => 'Keeps the last 4 copies on this device';

  @override
  String autoBackupLast(String date) {
    return 'Last automatic backup: $date';
  }

  @override
  String get autoBackupNone => 'No automatic backup yet';

  @override
  String get autoBackupRestore => 'Restore it';

  @override
  String autoBackupRestoreTitle(String date) {
    return 'Restore the backup from $date?';
  }

  @override
  String get autoBackupMissing => 'No automatic backup found on this device';

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
  String get remindInHour => 'In an hour';

  @override
  String get remindTonight => 'This evening';

  @override
  String get remindTomorrow => 'Tomorrow morning';

  @override
  String get remindPick => 'Pick a date & time';

  @override
  String get pinShort => 'Pin';

  @override
  String get toolFilter => 'Filter';

  @override
  String get toolPen => 'Pen';

  @override
  String get toolSort => 'Sort';

  @override
  String get toolLayout => 'Layout';

  @override
  String get toolMore => 'More';

  @override
  String get addOtherKinds => 'Add another kind of note';

  @override
  String get addOtherKindsShort => 'Other kinds';

  @override
  String get colorShort => 'Color';

  @override
  String typeChangeDrops(String type) {
    return 'Save as “$type”? Its drawing or link address won\'t be kept.';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get paperAuto => 'Automatic color';

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

  @override
  String get stackNotes => 'Stack with…';

  @override
  String get stackSelected => 'Stack';

  @override
  String stackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes in this stack',
      one: '1 note in this stack',
    );
    return '$_temp0';
  }

  @override
  String get unstack => 'Spread out';

  @override
  String get stackOpen => 'Open stack';

  @override
  String otherBoardsMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more on other walls',
      one: '1 more on other walls',
    );
    return '$_temp0';
  }

  @override
  String get onOtherBoards => 'On other walls';

  @override
  String get proTitle => 'Sticky Wall Pro';

  @override
  String get proPitch =>
      'One payment, yours for good. Everything you have now stays free.';

  @override
  String get proPerkPapers => '6 more paper colors';

  @override
  String get proPerkWalls => '5 more walls';

  @override
  String get proPerkFonts => '5 more fonts';

  @override
  String get proPerkPins =>
      '5 more ways to hold notes up: colorful pins, thumbtacks, washi tape, paper clips and magnets';

  @override
  String proBuy(String price) {
    return 'Unlock for $price';
  }

  @override
  String get proBuyNoPrice => 'Unlock Pro';

  @override
  String get proRestore => 'Restore purchase';

  @override
  String get proRestored => 'Pro restored. Welcome back!';

  @override
  String get proRestoreNone => 'No earlier purchase found for this account.';

  @override
  String get proUnlocked => 'Pro is unlocked. Thank you!';

  @override
  String get proPending =>
      'Payment pending. Pro unlocks as soon as Google Play confirms it.';

  @override
  String get proFailed => 'The purchase didn\'t go through. Please try again.';

  @override
  String get proUnavailable =>
      'Purchases aren\'t available right now. Check your connection and Google Play, then try again.';

  @override
  String get proKeepsLook =>
      'Notes keep their Pro paper and wall, wherever they go.';

  @override
  String proLocked(String name) {
    return '$name, Pro';
  }

  @override
  String get proSettingsHint =>
      'Stickers, paper styles, walls, fonts, pins and more';

  @override
  String get proSettingsThanks => 'Unlocked. Thank you!';

  @override
  String get paperLime => 'Lime';

  @override
  String get paperCoral => 'Coral';

  @override
  String get paperPeriwinkle => 'Periwinkle';

  @override
  String get paperSage => 'Sage';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperWhite => 'White';

  @override
  String get wallChalkNavy => 'Navy chalkboard';

  @override
  String get wallChalkWine => 'Wine chalkboard';

  @override
  String get wallBlush => 'Blush plaster';

  @override
  String get wallSage => 'Sage plaster';

  @override
  String get wallSky => 'Sky cotton';

  @override
  String get pinSection => 'Pins';

  @override
  String get pinClassic => 'Red pin';

  @override
  String get pinColorful => 'Colorful pins';

  @override
  String get pinTack => 'Thumbtack';

  @override
  String get pinWashi => 'Washi tape';

  @override
  String get pinClip => 'Paper clip';

  @override
  String get pinMagnet => 'Magnet';

  @override
  String get privacySection => 'Privacy';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'Asks for your fingerprint, face or screen lock when Sticky Wall opens, and when it comes back after a minute away.';

  @override
  String get appLockReason => 'Unlock Sticky Wall';

  @override
  String get appLockLocked => 'Sticky Wall is locked';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockNoLock => 'Set a screen lock on this phone first.';

  @override
  String get widgetSection => 'Home-screen widget';

  @override
  String get widgetSettingsHint =>
      'Which wall, what it lists, colors and text size';

  @override
  String get widgetBoardLabel => 'Wall';

  @override
  String get widgetBoardCurrent => 'The open wall';

  @override
  String get widgetContentLabel => 'Shows';

  @override
  String get widgetContentPinned => 'Pinned notes';

  @override
  String get widgetContentNewest => 'Newest notes';

  @override
  String get widgetContentPicture => 'Board picture';

  @override
  String get widgetLookLabel => 'Colors';

  @override
  String get widgetLookWall => 'Wall brown';

  @override
  String get widgetLookPaper => 'Paper';

  @override
  String get widgetLookInk => 'Ink';

  @override
  String get widgetTextSizeLabel => 'Text size';

  @override
  String get widgetTextSmall => 'Small';

  @override
  String get widgetTextNormal => 'Normal';

  @override
  String get widgetTextLarge => 'Large';

  @override
  String get widgetEmptyPinned => 'No pinned notes';

  @override
  String get widgetEmptyNewest => 'No notes yet';

  @override
  String get widgetAddHint =>
      'To add it: touch and hold your home screen, then Widgets → Sticky Wall.';

  @override
  String get swatchPink => 'Pink';

  @override
  String get swatchTeal => 'Teal';

  @override
  String get swatchBrown => 'Brown';

  @override
  String get swatchWhite => 'White';

  @override
  String get swatchYellow => 'Yellow';

  @override
  String get paperPlain => 'Plain';

  @override
  String get paperLined => 'Lined';

  @override
  String get paperGrid => 'Grid';

  @override
  String get paperDots => 'Dotted';

  @override
  String get paperIndex => 'Index card';

  @override
  String get paperNotebook => 'Notebook page';

  @override
  String get typeSticker => 'Sticker';

  @override
  String get stickerHere => 'Sticker here';

  @override
  String get stickerPick => 'Pick a sticker';

  @override
  String get stampUrgent => 'Urgent';

  @override
  String get stampDone => 'Done';

  @override
  String get stampImportant => 'Important';

  @override
  String get stampLater => 'Later';

  @override
  String get stickerArrow => 'Arrow';

  @override
  String get stickerCircle => 'Circled';

  @override
  String get stickerUnderline => 'Underline';

  @override
  String get stickerRing => 'Coffee ring';

  @override
  String get highlighter => 'Highlighter';

  @override
  String get threadStyle => 'Made of';

  @override
  String get threadYarn => 'Yarn';

  @override
  String get threadTwine => 'Twine';

  @override
  String get threadRibbon => 'Ribbon';

  @override
  String get threadDashed => 'Dashed';

  @override
  String get threadBeads => 'Beads';

  @override
  String get tryingOn =>
      'Trying it on: this is how it looks. Unlock Pro to keep it.';

  @override
  String get tryOnStop => 'Put back';

  @override
  String get tryOnKeep => 'Keep it';

  @override
  String get proNudge =>
      'Enjoying Sticky Wall? Pro adds stickers, paper styles, walls, fonts and more, for one payment.';

  @override
  String get proNudgeAction => 'See Pro';

  @override
  String get proPerkPaperStyles =>
      '5 paper styles: lined, grid, dotted, index card, notebook page';

  @override
  String get proPerkStickers =>
      '15 more stickers: rubber stamps, emoji and marker doodles';

  @override
  String get proPerkMarkers =>
      '5 more marker colors and a highlighter for the wall';

  @override
  String get proPerkThreads =>
      '4 thread styles (twine, ribbon, dashed, beads) and 4 more colors';

  @override
  String get proTryHint =>
      'Tap a Pro wall, font or pin in Customize to try it on your own wall first.';

  @override
  String get paperCustom => 'Your own color';

  @override
  String get paperCustomTitle => 'Mix a paper color';

  @override
  String get paperCustomHue => 'Color';

  @override
  String get paperCustomStrength => 'Strength';

  @override
  String get paperCustomLightness => 'Lightness';

  @override
  String get boardMakePrivate => 'Make private';

  @override
  String get boardMakePublic => 'Make public again';

  @override
  String get boardPrivateHint =>
      'Opens with your fingerprint or screen lock; kept off the widget, search and reminder texts';

  @override
  String get boardPrivate => 'Private board';

  @override
  String get boardShutHint => 'Its notes stay hidden until you unlock it.';

  @override
  String get boardUnlockReason => 'Open the private board';

  @override
  String get reminderPrivate => 'A reminder on a private board';

  @override
  String get widgetPrivate => 'Private board';

  @override
  String get packEveryday => 'Everyday';

  @override
  String get packTet => 'Tết';

  @override
  String get packChristmas => 'Christmas';

  @override
  String get packMidAutumn => 'Mid-Autumn';

  @override
  String get packValentine => 'Valentine\'s';

  @override
  String get stampNewYear => 'Happy New Year';

  @override
  String get stampMerry => 'Merry Christmas';

  @override
  String get stampMidAutumn => 'Mid-Autumn';

  @override
  String get stampLove => 'Love you';

  @override
  String get stickerMai => 'Apricot blossom';

  @override
  String get stickerDao => 'Peach blossom';

  @override
  String get stickerStarLantern => 'Star lantern';

  @override
  String get wallTet => 'Tết · apricot';

  @override
  String get wallTetDao => 'Tết · peach';

  @override
  String get wallXmas => 'Christmas green';

  @override
  String get wallMoon => 'Mid-Autumn night';

  @override
  String get wallLove => 'Valentine pink';

  @override
  String get proPerkSeasons =>
      'Seasonal packs: Tết, Christmas, Mid-Autumn and Valentine\'s walls and stickers';

  @override
  String get proPerkPrivate => 'Private boards that open with your fingerprint';

  @override
  String get proPerkCustomColor => 'Mix any paper color you like';

  @override
  String seasonUntil(String date) {
    return 'until $date';
  }

  @override
  String get confirmItsYou => 'Confirm it\'s you';

  @override
  String get galleryTitle => 'Templates & themes';

  @override
  String get galleryTemplates => 'Board templates';

  @override
  String get galleryThemes => 'Themes';

  @override
  String get gallerySearch => 'Search templates';

  @override
  String get galleryAll => 'All';

  @override
  String get galleryFree => 'Free';

  @override
  String get galleryNothing => 'No template matches that.';

  @override
  String get catProductivity => 'Plans & lists';

  @override
  String get catStudy => 'Study';

  @override
  String get catCreative => 'Creative';

  @override
  String get catPersonal => 'Personal';

  @override
  String get catFamily => 'Family';

  @override
  String get catSeasonal => 'Seasonal';

  @override
  String get catClassic => 'Classic';

  @override
  String get useTemplate => 'Use this template';

  @override
  String templateLook(String name) {
    return 'Look: $name';
  }

  @override
  String get templateFreeLook =>
      'That look is part of Pro, so the board starts on cork; you can change it any time.';

  @override
  String templateUsed(String name) {
    return '“$name” is ready. Change any note, or clear the examples from the board\'s sheet.';
  }

  @override
  String applyTheme(String board) {
    return 'Apply to “$board”';
  }

  @override
  String themeApplied(String name) {
    return '“$name” applied';
  }

  @override
  String get themeKeepsContent =>
      'Changes the wall, the papers and their ruling, the pins, the handwriting and the threads on this board. What you wrote and where it sits stay as they are.';

  @override
  String get proUnlock => 'Unlock with Pro';

  @override
  String get previewNoteA => 'Call the bakery';

  @override
  String get previewNoteB => 'Picnic on Sunday';

  @override
  String get previewItemA => 'Tickets';

  @override
  String get previewItemB => 'Snacks';

  @override
  String get newBoardBlank => 'Blank board';

  @override
  String get newBoardFromTemplate => 'From a template';

  @override
  String get newBoardFromTemplateHint =>
      '45 boards to start from: planners, study, family, moodboards…';

  @override
  String get clearSamples => 'Clear the examples';

  @override
  String get clearSamplesHint => 'Keeps the headings, stickers and wall';

  @override
  String get samplesCleared => 'Examples cleared';

  @override
  String get changeTheme => 'Change the theme';

  @override
  String get welcomeTitle => 'Welcome to Sticky Wall';

  @override
  String get welcomeBody =>
      'Notes on a real wall: write them, move them, tie them together. How would you like to start?';

  @override
  String get welcomeTemplate => 'Pick a template';

  @override
  String get welcomeTemplateHint =>
      'Planners, study boards, moodboards and more, ready to edit';

  @override
  String get welcomeBlank => 'Start with a blank wall';

  @override
  String get welcomeBlankHint => 'The sample notes are cleared';

  @override
  String get welcomeExplore => 'Explore the sample wall';

  @override
  String get welcomeExploreHint =>
      'A few notes that show what you can do; delete them any time';

  @override
  String get memoryWall => 'Memory wall';

  @override
  String get memoryWallHint => 'Many photos at once, laid out for you to edit';

  @override
  String memoryPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String memoryTooMany(int max) {
    return 'A wall holds up to $max; the first $max are used.';
  }

  @override
  String get memoryLayout => 'Layout';

  @override
  String get layoutCollage => 'Collage';

  @override
  String get layoutPrints => 'Prints in rows';

  @override
  String get layoutFilm => 'Film strip';

  @override
  String get layoutTimeline => 'Timeline';

  @override
  String get memoryLook => 'Look';

  @override
  String get memoryCreate => 'Make the wall';

  @override
  String get memoryTitle => 'Memories';

  @override
  String memoryMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos are on your memory wall',
      one: '1 photo is on your memory wall',
    );
    return '$_temp0. Tap one to add a caption.';
  }

  @override
  String get allBoards => 'All boards';

  @override
  String boardNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'No notes',
    );
    return '$_temp0';
  }

  @override
  String get duplicateBoard => 'Duplicate board';

  @override
  String boardCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get boardDuplicated => 'Board duplicated';

  @override
  String get shareWhere => 'Save to which board?';

  @override
  String sharedSaved(String board) {
    return 'Saved to “$board”';
  }

  @override
  String get openNote => 'Open';
}
