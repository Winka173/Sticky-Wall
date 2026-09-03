import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall'**
  String get appTitle;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @typeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get typeAll;

  /// No description provided for @typeNormal.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get typeNormal;

  /// No description provided for @typeLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get typeLink;

  /// No description provided for @typeChecklist.
  ///
  /// In en, this message translates to:
  /// **'To-do list'**
  String get typeChecklist;

  /// No description provided for @typeDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get typeDrawing;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @contentHint.
  ///
  /// In en, this message translates to:
  /// **'Write something…'**
  String get contentHint;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Write something first'**
  String get contentRequired;

  /// No description provided for @linkRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a link first'**
  String get linkRequired;

  /// No description provided for @noteEmpty.
  ///
  /// In en, this message translates to:
  /// **'The note is still empty'**
  String get noteEmpty;

  /// No description provided for @duplicateExists.
  ///
  /// In en, this message translates to:
  /// **'This link is already on the wall'**
  String get duplicateExists;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get noteDeleted;

  /// No description provided for @notesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note moved to trash} other{{count} notes moved to trash}}'**
  String notesDeleted(int count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @dropToDelete.
  ///
  /// In en, this message translates to:
  /// **'Drop here to delete'**
  String get dropToDelete;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashHint.
  ///
  /// In en, this message translates to:
  /// **'Notes here are deleted for good after 30 days.'**
  String get trashHint;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Note restored'**
  String get restored;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete the 1 note in the trash for good?} other{Delete all {count} notes in the trash for good?}}'**
  String emptyTrashConfirm(int count);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Expires today} =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @deletedOn.
  ///
  /// In en, this message translates to:
  /// **'Deleted {date}'**
  String deletedOn(String date);

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select notes'**
  String get select;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @tidy.
  ///
  /// In en, this message translates to:
  /// **'Tidy up'**
  String get tidy;

  /// No description provided for @tidyByColor.
  ///
  /// In en, this message translates to:
  /// **'Arrange by color'**
  String get tidyByColor;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @threadCut.
  ///
  /// In en, this message translates to:
  /// **'Thread cut'**
  String get threadCut;

  /// No description provided for @threadTied.
  ///
  /// In en, this message translates to:
  /// **'Thread tied'**
  String get threadTied;

  /// No description provided for @threadTip.
  ///
  /// In en, this message translates to:
  /// **'Drag from a pin onto another note to tie a thread.'**
  String get threadTip;

  /// No description provided for @nightSection.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get nightSection;

  /// No description provided for @nightModeOff.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get nightModeOff;

  /// No description provided for @nightModeOn.
  ///
  /// In en, this message translates to:
  /// **'Always off'**
  String get nightModeOn;

  /// No description provided for @nightModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get nightModeSystem;

  /// No description provided for @nightModeSchedule.
  ///
  /// In en, this message translates to:
  /// **'On a schedule'**
  String get nightModeSchedule;

  /// No description provided for @lightsOff.
  ///
  /// In en, this message translates to:
  /// **'Lights off'**
  String get lightsOff;

  /// No description provided for @lightsOn.
  ///
  /// In en, this message translates to:
  /// **'Lights on'**
  String get lightsOn;

  /// No description provided for @nightSchedule.
  ///
  /// In en, this message translates to:
  /// **'From {start} to {end}'**
  String nightSchedule(String start, String end);

  /// No description provided for @nightStart.
  ///
  /// In en, this message translates to:
  /// **'Lights off at'**
  String get nightStart;

  /// No description provided for @nightEnd.
  ///
  /// In en, this message translates to:
  /// **'Lights on at'**
  String get nightEnd;

  /// No description provided for @customWall.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get customWall;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @autoTrashDone.
  ///
  /// In en, this message translates to:
  /// **'Tidy finished to-do lists'**
  String get autoTrashDone;

  /// No description provided for @autoTrashDoneHint.
  ///
  /// In en, this message translates to:
  /// **'A list with every item ticked moves to the trash after a day.'**
  String get autoTrashDoneHint;

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 note} other{{count} notes}}'**
  String resultCount(int count);

  /// No description provided for @boardIcon.
  ///
  /// In en, this message translates to:
  /// **'Board icon'**
  String get boardIcon;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @sampleDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag me anywhere on the wall 👉\nLong-press an empty spot to stick a new note there.'**
  String get sampleDrag;

  /// No description provided for @sampleLongPress.
  ///
  /// In en, this message translates to:
  /// **'Long-press me for more: move to another board, share, delete…'**
  String get sampleLongPress;

  /// No description provided for @sampleChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Try ticking these ✅'**
  String get sampleChecklistTitle;

  /// No description provided for @sampleChecklist1.
  ///
  /// In en, this message translates to:
  /// **'Tap the red pin to keep a note on top'**
  String get sampleChecklist1;

  /// No description provided for @sampleChecklist2.
  ///
  /// In en, this message translates to:
  /// **'Drag the corner handle to resize'**
  String get sampleChecklist2;

  /// No description provided for @sampleChecklist3.
  ///
  /// In en, this message translates to:
  /// **'Delete us once you know the ropes'**
  String get sampleChecklist3;

  /// No description provided for @sampleThread.
  ///
  /// In en, this message translates to:
  /// **'Drag from my pin onto another note to tie a thread 🧵'**
  String get sampleThread;

  /// No description provided for @sampleDrawing.
  ///
  /// In en, this message translates to:
  /// **'Doodles too ✏️'**
  String get sampleDrawing;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.\nTap here to stick the first one on the wall!'**
  String get emptyState;

  /// No description provided for @wallCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: long-press anywhere on the wall to stick a note or a photo right there.'**
  String get wallCreateHint;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No notes match'**
  String get noMatches;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpen(String url);

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @wallSection.
  ///
  /// In en, this message translates to:
  /// **'Wall texture'**
  String get wallSection;

  /// No description provided for @fontSection.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontSection;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTooltip;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortAZ.
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get sortAZ;

  /// No description provided for @sortZA.
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get sortZA;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @viewWall.
  ///
  /// In en, this message translates to:
  /// **'Wall'**
  String get viewWall;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @wallCork.
  ///
  /// In en, this message translates to:
  /// **'Cork board'**
  String get wallCork;

  /// No description provided for @wallChalkGreen.
  ///
  /// In en, this message translates to:
  /// **'Green chalkboard'**
  String get wallChalkGreen;

  /// No description provided for @wallChalkBlack.
  ///
  /// In en, this message translates to:
  /// **'Black chalkboard'**
  String get wallChalkBlack;

  /// No description provided for @wallPlaster.
  ///
  /// In en, this message translates to:
  /// **'Painted wall'**
  String get wallPlaster;

  /// No description provided for @wallBrick.
  ///
  /// In en, this message translates to:
  /// **'Brick wall'**
  String get wallBrick;

  /// No description provided for @wallWood.
  ///
  /// In en, this message translates to:
  /// **'Wood planks'**
  String get wallWood;

  /// No description provided for @wallKraft.
  ///
  /// In en, this message translates to:
  /// **'Kraft paper'**
  String get wallKraft;

  /// No description provided for @wallMarble.
  ///
  /// In en, this message translates to:
  /// **'Marble'**
  String get wallMarble;

  /// No description provided for @wallTerrazzo.
  ///
  /// In en, this message translates to:
  /// **'Terrazzo'**
  String get wallTerrazzo;

  /// No description provided for @wallDenim.
  ///
  /// In en, this message translates to:
  /// **'Denim'**
  String get wallDenim;

  /// No description provided for @wallFelt.
  ///
  /// In en, this message translates to:
  /// **'Felt board'**
  String get wallFelt;

  /// No description provided for @wallLinen.
  ///
  /// In en, this message translates to:
  /// **'Dark linen'**
  String get wallLinen;

  /// No description provided for @fontPreview.
  ///
  /// In en, this message translates to:
  /// **'Hello! A quick note on the wall.'**
  String get fontPreview;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get fromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @typePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get typePhoto;

  /// No description provided for @caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get caption;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get replacePhoto;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get photoRequired;

  /// No description provided for @pinPhotos.
  ///
  /// In en, this message translates to:
  /// **'Pin photos on the wall'**
  String get pinPhotos;

  /// No description provided for @noteHere.
  ///
  /// In en, this message translates to:
  /// **'Sticky note here'**
  String get noteHere;

  /// No description provided for @photosHere.
  ///
  /// In en, this message translates to:
  /// **'Photos here'**
  String get photosHere;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @photosPinned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo pinned on the wall} other{{count} photos pinned on the wall}}'**
  String photosPinned(int count);

  /// No description provided for @shareAsImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareAsImage;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImage;

  /// No description provided for @exportBoard.
  ///
  /// In en, this message translates to:
  /// **'Export board as image'**
  String get exportBoard;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'Just the wall, its notes and threads — no toolbars. Share it, or save it to your gallery.'**
  String get exportHint;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get imageSaved;

  /// No description provided for @imageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save image'**
  String get imageSaveFailed;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoom;

  /// No description provided for @wallDecor.
  ///
  /// In en, this message translates to:
  /// **'Wall stains & marks'**
  String get wallDecor;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @penSize.
  ///
  /// In en, this message translates to:
  /// **'Pen size'**
  String get penSize;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @canvasSection.
  ///
  /// In en, this message translates to:
  /// **'Canvas paper'**
  String get canvasSection;

  /// No description provided for @patternPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get patternPlain;

  /// No description provided for @patternRuled.
  ///
  /// In en, this message translates to:
  /// **'Ruled'**
  String get patternRuled;

  /// No description provided for @patternGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get patternGrid;

  /// No description provided for @patternDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get patternDots;

  /// No description provided for @emote.
  ///
  /// In en, this message translates to:
  /// **'Emote'**
  String get emote;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Paper color'**
  String get color;

  /// No description provided for @newBoard.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get newBoard;

  /// No description provided for @boardName.
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get boardName;

  /// No description provided for @editBoard.
  ///
  /// In en, this message translates to:
  /// **'Edit board'**
  String get editBoard;

  /// No description provided for @nameStyle.
  ///
  /// In en, this message translates to:
  /// **'Name style'**
  String get nameStyle;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @defaultBoardName.
  ///
  /// In en, this message translates to:
  /// **'My Wall'**
  String get defaultBoardName;

  /// No description provided for @deleteBoard.
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get deleteBoard;

  /// No description provided for @deleteBoardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” and all its notes?'**
  String deleteBoardConfirm(String name);

  /// No description provided for @moveToBoard.
  ///
  /// In en, this message translates to:
  /// **'Move to another board'**
  String get moveToBoard;

  /// No description provided for @movedToBoard.
  ///
  /// In en, this message translates to:
  /// **'Moved to “{name}”'**
  String movedToBoard(String name);

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Back up notes'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get importData;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a backup here'**
  String get importHint;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored successfully'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that backup'**
  String get importFailed;

  /// No description provided for @importReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Restoring replaces all current boards and notes.'**
  String get importReplaceWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
