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

  /// No description provided for @dragToDelete.
  ///
  /// In en, this message translates to:
  /// **'Drag to the foot to delete'**
  String get dragToDelete;

  /// No description provided for @dragToDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'A tray comes up at the foot of the wall; drop a note on it to delete it (Undo is offered).'**
  String get dragToDeleteHint;

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

  /// No description provided for @wallCardboard.
  ///
  /// In en, this message translates to:
  /// **'Cardboard'**
  String get wallCardboard;

  /// No description provided for @wallCement.
  ///
  /// In en, this message translates to:
  /// **'Cement wall'**
  String get wallCement;

  /// No description provided for @wallCotton.
  ///
  /// In en, this message translates to:
  /// **'White cotton'**
  String get wallCotton;

  /// No description provided for @wallPaper.
  ///
  /// In en, this message translates to:
  /// **'White paper'**
  String get wallPaper;

  /// No description provided for @wallMoss.
  ///
  /// In en, this message translates to:
  /// **'Moss'**
  String get wallMoss;

  /// No description provided for @wallLeather.
  ///
  /// In en, this message translates to:
  /// **'Red leather'**
  String get wallLeather;

  /// No description provided for @wallDarkMarble.
  ///
  /// In en, this message translates to:
  /// **'Dark marble'**
  String get wallDarkMarble;

  /// No description provided for @wallDarkWood.
  ///
  /// In en, this message translates to:
  /// **'Dark planks'**
  String get wallDarkWood;

  /// No description provided for @wallTiles.
  ///
  /// In en, this message translates to:
  /// **'Checker tiles'**
  String get wallTiles;

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

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get typeLabel;

  /// No description provided for @labelHint.
  ///
  /// In en, this message translates to:
  /// **'Column or section name…'**
  String get labelHint;

  /// No description provided for @lockInPlace.
  ///
  /// In en, this message translates to:
  /// **'Lock in place'**
  String get lockInPlace;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @thread.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get thread;

  /// No description provided for @yarnColor.
  ///
  /// In en, this message translates to:
  /// **'Yarn color'**
  String get yarnColor;

  /// No description provided for @threadLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Write on the thread…'**
  String get threadLabelHint;

  /// No description provided for @threadArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrowhead'**
  String get threadArrow;

  /// No description provided for @cutThread.
  ///
  /// In en, this message translates to:
  /// **'Cut thread'**
  String get cutThread;

  /// No description provided for @drawOnWall.
  ///
  /// In en, this message translates to:
  /// **'Draw on the wall'**
  String get drawOnWall;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

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

  /// No description provided for @exportWholeWall.
  ///
  /// In en, this message translates to:
  /// **'Whole wall'**
  String get exportWholeWall;

  /// No description provided for @exportVisible.
  ///
  /// In en, this message translates to:
  /// **'Part in view'**
  String get exportVisible;

  /// No description provided for @exportAllNotes.
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get exportAllNotes;

  /// No description provided for @exportSelectedNotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String exportSelectedNotes(int count);

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get exportMore;

  /// No description provided for @exportFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer options'**
  String get exportFewer;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get cropImage;

  /// No description provided for @cropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the corners or edges to trim the picture; drag inside to move the frame.'**
  String get cropHint;

  /// No description provided for @cropReset.
  ///
  /// In en, this message translates to:
  /// **'Whole picture'**
  String get cropReset;

  /// No description provided for @putOnHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Show on the home-screen widget'**
  String get putOnHomeScreen;

  /// No description provided for @widgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget updated'**
  String get widgetUpdated;

  /// No description provided for @widgetUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the widget'**
  String get widgetUpdateFailed;

  /// No description provided for @bullets.
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get bullets;

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
  /// **'Delete “{name}”?'**
  String deleteBoardConfirm(String name);

  /// No description provided for @moveToBoard.
  ///
  /// In en, this message translates to:
  /// **'Move to another board'**
  String get moveToBoard;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyToBoard.
  ///
  /// In en, this message translates to:
  /// **'Copy to another board'**
  String get copyToBoard;

  /// No description provided for @copiedToBoard.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 note to “{name}”} other{Copied {count} notes to “{name}”}}'**
  String copiedToBoard(int count, String name);

  /// No description provided for @fitAll.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get fitAll;

  /// No description provided for @gestureTips.
  ///
  /// In en, this message translates to:
  /// **'Gesture tips'**
  String get gestureTips;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @tipDragTitle.
  ///
  /// In en, this message translates to:
  /// **'Move, turn, resize'**
  String get tipDragTitle;

  /// No description provided for @tipDragBody.
  ///
  /// In en, this message translates to:
  /// **'Drag a note with one finger. Put two fingers on it to twist and pinch, or use the grips at its bottom corners: resize on the right, rotate on the left (tap that one to square the note up).'**
  String get tipDragBody;

  /// No description provided for @tipPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Pins and threads'**
  String get tipPinTitle;

  /// No description provided for @tipPinBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the pin to keep a note on top. Drag from a pin onto another note to tie a thread; tap a thread to color it, write on it, add an arrowhead or cut it.'**
  String get tipPinBody;

  /// No description provided for @tipWallTitle.
  ///
  /// In en, this message translates to:
  /// **'The wall'**
  String get tipWallTitle;

  /// No description provided for @tipWallBody.
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot to stick a note or photos there. Pinch to zoom, pan out to the wall’s margins and park notes there. Double-tap a note to zoom in on it; the frame button shows everything.'**
  String get tipWallBody;

  /// No description provided for @tipDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to another board'**
  String get tipDropTitle;

  /// No description provided for @tipDropBody.
  ///
  /// In en, this message translates to:
  /// **'Drop a dragged note on a board tab to move it to that board. Deleting by dragging it to a tray at the foot of the wall can be switched on in Customize.'**
  String get tipDropBody;

  /// No description provided for @tipSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select several'**
  String get tipSelectTitle;

  /// No description provided for @tipSelectBody.
  ///
  /// In en, this message translates to:
  /// **'Long-press a note → Select. Draw a loop round notes on empty wall to add them, and drag any selected note to move the whole group.'**
  String get tipSelectBody;

  /// No description provided for @tipDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw on the wall'**
  String get tipDrawTitle;

  /// No description provided for @tipDrawBody.
  ///
  /// In en, this message translates to:
  /// **'The pen in the toolbar starts marker mode: one finger draws behind the notes, two still zoom. Undo, clear and done sit in the bar below.'**
  String get tipDrawBody;

  /// No description provided for @tipUndoTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tipUndoTitle;

  /// No description provided for @tipUndoBody.
  ///
  /// In en, this message translates to:
  /// **'An Undo pill appears for a few seconds after every move, turn, resize, tidy-up or board change.'**
  String get tipUndoBody;

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
  /// **'Load backup'**
  String get importData;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a backup here'**
  String get importHint;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup loaded'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that backup'**
  String get importFailed;

  /// No description provided for @importReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Loading a backup replaces all current boards and notes.'**
  String get importReplaceWarning;

  /// No description provided for @typeAudio.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get typeAudio;

  /// No description provided for @recordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to record, or hold and let go'**
  String get recordHint;

  /// No description provided for @recordStart.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get recordStart;

  /// No description provided for @recordStop.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get recordStop;

  /// No description provided for @recordingNow.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingNow;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get deleteRecording;

  /// No description provided for @playVoice.
  ///
  /// In en, this message translates to:
  /// **'Play voice note'**
  String get playVoice;

  /// No description provided for @pauseVoice.
  ///
  /// In en, this message translates to:
  /// **'Pause voice note'**
  String get pauseVoice;

  /// No description provided for @recordingRequired.
  ///
  /// In en, this message translates to:
  /// **'Record something first'**
  String get recordingRequired;

  /// No description provided for @micDenied.
  ///
  /// In en, this message translates to:
  /// **'The microphone is off for Sticky Wall. Allow it in the phone\'s settings to record.'**
  String get micDenied;

  /// No description provided for @recordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record. Try again.'**
  String get recordFailed;

  /// No description provided for @recordingMissing.
  ///
  /// In en, this message translates to:
  /// **'This recording is no longer on the device'**
  String get recordingMissing;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic weekly backup'**
  String get autoBackup;

  /// No description provided for @autoBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps the last 4 copies on this device'**
  String get autoBackupHint;

  /// No description provided for @autoBackupLast.
  ///
  /// In en, this message translates to:
  /// **'Last automatic backup: {date}'**
  String autoBackupLast(String date);

  /// No description provided for @autoBackupNone.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup yet'**
  String get autoBackupNone;

  /// No description provided for @autoBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore it'**
  String get autoBackupRestore;

  /// No description provided for @autoBackupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the backup from {date}?'**
  String autoBackupRestoreTitle(String date);

  /// No description provided for @autoBackupMissing.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup found on this device'**
  String get autoBackupMissing;

  /// No description provided for @importChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get importChooseFile;

  /// No description provided for @importNotJson.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a backup file: the text is not valid JSON. Paste the whole file, with nothing cut off.'**
  String get importNotJson;

  /// No description provided for @importNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Sticky Wall backup.'**
  String get importNotBackup;

  /// No description provided for @importNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Sticky Wall. Update the app, then try again.'**
  String get importNewerVersion;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make the backup'**
  String get backupFailed;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall backup'**
  String get backupShareSubject;

  /// No description provided for @restoredTo.
  ///
  /// In en, this message translates to:
  /// **'Restored to “{board}”'**
  String restoredTo(String board);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share'**
  String get shareFailed;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @cropDone.
  ///
  /// In en, this message translates to:
  /// **'Finish trimming'**
  String get cropDone;

  /// No description provided for @penThin.
  ///
  /// In en, this message translates to:
  /// **'Thin pen'**
  String get penThin;

  /// No description provided for @penMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium pen'**
  String get penMedium;

  /// No description provided for @penThick.
  ///
  /// In en, this message translates to:
  /// **'Thick pen'**
  String get penThick;

  /// No description provided for @colorInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get colorInk;

  /// No description provided for @colorChalk.
  ///
  /// In en, this message translates to:
  /// **'Chalk white'**
  String get colorChalk;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @toneWhite.
  ///
  /// In en, this message translates to:
  /// **'White paper'**
  String get toneWhite;

  /// No description provided for @toneCream.
  ///
  /// In en, this message translates to:
  /// **'Cream paper'**
  String get toneCream;

  /// No description provided for @toneBlush.
  ///
  /// In en, this message translates to:
  /// **'Blush paper'**
  String get toneBlush;

  /// No description provided for @toneSky.
  ///
  /// In en, this message translates to:
  /// **'Sky paper'**
  String get toneSky;

  /// No description provided for @toneMint.
  ///
  /// In en, this message translates to:
  /// **'Mint paper'**
  String get toneMint;

  /// No description provided for @toneKraft.
  ///
  /// In en, this message translates to:
  /// **'Kraft paper'**
  String get toneKraft;

  /// No description provided for @toneChalkboard.
  ///
  /// In en, this message translates to:
  /// **'Chalkboard'**
  String get toneChalkboard;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardChangesTitle;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @deleteForeverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this note for good? It can\'t be brought back.'**
  String get deleteForeverConfirm;

  /// No description provided for @deleteBoardWithNotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its note is deleted for good — it doesn\'t go to the trash.} other{Its {count} notes are deleted for good — they don\'t go to the trash.}}'**
  String deleteBoardWithNotes(int count);

  /// No description provided for @reminderInPast.
  ///
  /// In en, this message translates to:
  /// **'That time has passed — pick a later one.'**
  String get reminderInPast;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Sticky Wall, so this reminder won\'t ring. Turn them on in the phone\'s settings.'**
  String get notificationsOff;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @remindInHour.
  ///
  /// In en, this message translates to:
  /// **'In an hour'**
  String get remindInHour;

  /// No description provided for @remindTonight.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get remindTonight;

  /// No description provided for @remindTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow morning'**
  String get remindTomorrow;

  /// No description provided for @remindPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date & time'**
  String get remindPick;

  /// No description provided for @pinShort.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinShort;

  /// No description provided for @toolFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get toolFilter;

  /// No description provided for @toolPen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get toolPen;

  /// No description provided for @toolSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get toolSort;

  /// No description provided for @toolMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get toolMore;

  /// No description provided for @addOtherKinds.
  ///
  /// In en, this message translates to:
  /// **'Add another kind of note'**
  String get addOtherKinds;

  /// No description provided for @addOtherKindsShort.
  ///
  /// In en, this message translates to:
  /// **'Other kinds'**
  String get addOtherKindsShort;

  /// No description provided for @colorShort.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorShort;

  /// No description provided for @typeChangeDrops.
  ///
  /// In en, this message translates to:
  /// **'Save as “{type}”? Its drawing or link address won\'t be kept.'**
  String typeChangeDrops(String type);

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @paperAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic color'**
  String get paperAuto;

  /// No description provided for @paperYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get paperYellow;

  /// No description provided for @paperPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get paperPink;

  /// No description provided for @paperMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get paperMint;

  /// No description provided for @paperBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get paperBlue;

  /// No description provided for @paperOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get paperOrange;

  /// No description provided for @paperLilac.
  ///
  /// In en, this message translates to:
  /// **'Lilac'**
  String get paperLilac;

  /// No description provided for @swatchRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get swatchRed;

  /// No description provided for @swatchOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get swatchOrange;

  /// No description provided for @swatchGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get swatchGold;

  /// No description provided for @swatchGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get swatchGreen;

  /// No description provided for @swatchBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get swatchBlue;

  /// No description provided for @swatchPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get swatchPurple;

  /// No description provided for @swatchInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get swatchInk;

  /// No description provided for @swatchChalk.
  ///
  /// In en, this message translates to:
  /// **'Chalk'**
  String get swatchChalk;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @selectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap notes, or draw a loop round them'**
  String get selectHint;

  /// No description provided for @filterShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing: {what}'**
  String filterShowing(String what);

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilter;

  /// No description provided for @undoMove.
  ///
  /// In en, this message translates to:
  /// **'Undo move'**
  String get undoMove;

  /// No description provided for @undoResize.
  ///
  /// In en, this message translates to:
  /// **'Undo resize'**
  String get undoResize;

  /// No description provided for @undoRotate.
  ///
  /// In en, this message translates to:
  /// **'Undo turn'**
  String get undoRotate;

  /// No description provided for @undoTidy.
  ///
  /// In en, this message translates to:
  /// **'Undo tidy'**
  String get undoTidy;

  /// No description provided for @undoMoveBoard.
  ///
  /// In en, this message translates to:
  /// **'Undo move to board'**
  String get undoMoveBoard;

  /// No description provided for @clearInkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Wipe everything drawn on this wall?'**
  String get clearInkConfirm;

  /// No description provided for @photoMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo not found on this device'**
  String get photoMissing;

  /// No description provided for @photoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that photo'**
  String get photoPickFailed;

  /// No description provided for @sizeAndTurn.
  ///
  /// In en, this message translates to:
  /// **'Size and turn'**
  String get sizeAndTurn;

  /// No description provided for @smaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get smaller;

  /// No description provided for @larger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get larger;

  /// No description provided for @turnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get turnLeft;

  /// No description provided for @turnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get turnRight;

  /// No description provided for @straighten.
  ///
  /// In en, this message translates to:
  /// **'Straighten'**
  String get straighten;

  /// No description provided for @tieThreadTo.
  ///
  /// In en, this message translates to:
  /// **'Tie a thread to…'**
  String get tieThreadTo;

  /// No description provided for @threadsOfNote.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get threadsOfNote;

  /// No description provided for @noOtherNotes.
  ///
  /// In en, this message translates to:
  /// **'No other notes on this wall to tie to'**
  String get noOtherNotes;

  /// No description provided for @moveBoardLeft.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get moveBoardLeft;

  /// No description provided for @moveBoardRight.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get moveBoardRight;

  /// No description provided for @resize.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get resize;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get untitledNote;

  /// No description provided for @remindersChannel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersChannel;

  /// No description provided for @remindersChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders you set on your notes'**
  String get remindersChannelDescription;

  /// No description provided for @stackNotes.
  ///
  /// In en, this message translates to:
  /// **'Stack with…'**
  String get stackNotes;

  /// No description provided for @stackSelected.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get stackSelected;

  /// No description provided for @stackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note in this stack} other{{count} notes in this stack}}'**
  String stackCount(int count);

  /// No description provided for @unstack.
  ///
  /// In en, this message translates to:
  /// **'Spread out'**
  String get unstack;

  /// No description provided for @stackOpen.
  ///
  /// In en, this message translates to:
  /// **'Open stack'**
  String get stackOpen;

  /// No description provided for @otherBoardsMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more on other walls} other{{count} more on other walls}}'**
  String otherBoardsMatches(int count);

  /// No description provided for @onOtherBoards.
  ///
  /// In en, this message translates to:
  /// **'On other walls'**
  String get onOtherBoards;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall Pro'**
  String get proTitle;

  /// No description provided for @proPitch.
  ///
  /// In en, this message translates to:
  /// **'One payment, yours for good. Everything you have now stays free.'**
  String get proPitch;

  /// No description provided for @proPerkPapers.
  ///
  /// In en, this message translates to:
  /// **'6 more paper colors'**
  String get proPerkPapers;

  /// No description provided for @proPerkWalls.
  ///
  /// In en, this message translates to:
  /// **'5 more walls'**
  String get proPerkWalls;

  /// No description provided for @proPerkFonts.
  ///
  /// In en, this message translates to:
  /// **'5 more fonts'**
  String get proPerkFonts;

  /// No description provided for @proPerkPins.
  ///
  /// In en, this message translates to:
  /// **'5 more ways to hold notes up: colorful pins, thumbtacks, washi tape, paper clips and magnets'**
  String get proPerkPins;

  /// No description provided for @proBuy.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String proBuy(String price);

  /// No description provided for @proBuyNoPrice.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get proBuyNoPrice;

  /// No description provided for @proRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get proRestore;

  /// No description provided for @proRestored.
  ///
  /// In en, this message translates to:
  /// **'Pro restored. Welcome back!'**
  String get proRestored;

  /// No description provided for @proRestoreNone.
  ///
  /// In en, this message translates to:
  /// **'No earlier purchase found for this account.'**
  String get proRestoreNone;

  /// No description provided for @proUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Pro is unlocked. Thank you!'**
  String get proUnlocked;

  /// No description provided for @proPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending. Pro unlocks as soon as Google Play confirms it.'**
  String get proPending;

  /// No description provided for @proFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Please try again.'**
  String get proFailed;

  /// No description provided for @proUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren\'t available right now. Check your connection and Google Play, then try again.'**
  String get proUnavailable;

  /// No description provided for @proKeepsLook.
  ///
  /// In en, this message translates to:
  /// **'Notes keep their Pro paper and wall, wherever they go.'**
  String get proKeepsLook;

  /// No description provided for @proLocked.
  ///
  /// In en, this message translates to:
  /// **'{name}, Pro'**
  String proLocked(String name);

  /// No description provided for @proSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Stickers, paper styles, walls, fonts, pins and more'**
  String get proSettingsHint;

  /// No description provided for @proSettingsThanks.
  ///
  /// In en, this message translates to:
  /// **'Unlocked. Thank you!'**
  String get proSettingsThanks;

  /// No description provided for @paperLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get paperLime;

  /// No description provided for @paperCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get paperCoral;

  /// No description provided for @paperPeriwinkle.
  ///
  /// In en, this message translates to:
  /// **'Periwinkle'**
  String get paperPeriwinkle;

  /// No description provided for @paperSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get paperSage;

  /// No description provided for @paperKraft.
  ///
  /// In en, this message translates to:
  /// **'Kraft'**
  String get paperKraft;

  /// No description provided for @paperWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get paperWhite;

  /// No description provided for @wallChalkNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy chalkboard'**
  String get wallChalkNavy;

  /// No description provided for @wallChalkWine.
  ///
  /// In en, this message translates to:
  /// **'Wine chalkboard'**
  String get wallChalkWine;

  /// No description provided for @wallBlush.
  ///
  /// In en, this message translates to:
  /// **'Blush plaster'**
  String get wallBlush;

  /// No description provided for @wallSage.
  ///
  /// In en, this message translates to:
  /// **'Sage plaster'**
  String get wallSage;

  /// No description provided for @wallSky.
  ///
  /// In en, this message translates to:
  /// **'Sky cotton'**
  String get wallSky;

  /// No description provided for @pinSection.
  ///
  /// In en, this message translates to:
  /// **'Pins'**
  String get pinSection;

  /// No description provided for @pinClassic.
  ///
  /// In en, this message translates to:
  /// **'Red pin'**
  String get pinClassic;

  /// No description provided for @pinColorful.
  ///
  /// In en, this message translates to:
  /// **'Colorful pins'**
  String get pinColorful;

  /// No description provided for @pinTack.
  ///
  /// In en, this message translates to:
  /// **'Thumbtack'**
  String get pinTack;

  /// No description provided for @pinWashi.
  ///
  /// In en, this message translates to:
  /// **'Washi tape'**
  String get pinWashi;

  /// No description provided for @pinClip.
  ///
  /// In en, this message translates to:
  /// **'Paper clip'**
  String get pinClip;

  /// No description provided for @pinMagnet.
  ///
  /// In en, this message translates to:
  /// **'Magnet'**
  String get pinMagnet;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySection;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockHint.
  ///
  /// In en, this message translates to:
  /// **'Asks for your fingerprint, face or screen lock when Sticky Wall opens, and when it comes back after a minute away.'**
  String get appLockHint;

  /// No description provided for @appLockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Sticky Wall'**
  String get appLockReason;

  /// No description provided for @appLockLocked.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall is locked'**
  String get appLockLocked;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @appLockNoLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock on this phone first.'**
  String get appLockNoLock;

  /// No description provided for @widgetSection.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get widgetSection;

  /// No description provided for @widgetSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Which wall, what it lists, colors and text size'**
  String get widgetSettingsHint;

  /// No description provided for @widgetBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'Wall'**
  String get widgetBoardLabel;

  /// No description provided for @widgetBoardCurrent.
  ///
  /// In en, this message translates to:
  /// **'The open wall'**
  String get widgetBoardCurrent;

  /// No description provided for @widgetContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get widgetContentLabel;

  /// No description provided for @widgetContentPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned notes'**
  String get widgetContentPinned;

  /// No description provided for @widgetContentNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest notes'**
  String get widgetContentNewest;

  /// No description provided for @widgetContentPicture.
  ///
  /// In en, this message translates to:
  /// **'Board picture'**
  String get widgetContentPicture;

  /// No description provided for @widgetLookLabel.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get widgetLookLabel;

  /// No description provided for @widgetLookWall.
  ///
  /// In en, this message translates to:
  /// **'Wall brown'**
  String get widgetLookWall;

  /// No description provided for @widgetLookPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get widgetLookPaper;

  /// No description provided for @widgetLookInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get widgetLookInk;

  /// No description provided for @widgetTextSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get widgetTextSizeLabel;

  /// No description provided for @widgetTextSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get widgetTextSmall;

  /// No description provided for @widgetTextNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get widgetTextNormal;

  /// No description provided for @widgetTextLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get widgetTextLarge;

  /// No description provided for @widgetEmptyPinned.
  ///
  /// In en, this message translates to:
  /// **'No pinned notes'**
  String get widgetEmptyPinned;

  /// No description provided for @widgetEmptyNewest.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get widgetEmptyNewest;

  /// No description provided for @widgetAddHint.
  ///
  /// In en, this message translates to:
  /// **'To add it: touch and hold your home screen, then Widgets → Sticky Wall.'**
  String get widgetAddHint;

  /// No description provided for @swatchPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get swatchPink;

  /// No description provided for @swatchTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get swatchTeal;

  /// No description provided for @swatchBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get swatchBrown;

  /// No description provided for @swatchWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get swatchWhite;

  /// No description provided for @swatchYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get swatchYellow;

  /// No description provided for @paperPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get paperPlain;

  /// No description provided for @paperLined.
  ///
  /// In en, this message translates to:
  /// **'Lined'**
  String get paperLined;

  /// No description provided for @paperGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get paperGrid;

  /// No description provided for @paperDots.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get paperDots;

  /// No description provided for @paperIndex.
  ///
  /// In en, this message translates to:
  /// **'Index card'**
  String get paperIndex;

  /// No description provided for @paperNotebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook page'**
  String get paperNotebook;

  /// No description provided for @typeSticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get typeSticker;

  /// No description provided for @stickerHere.
  ///
  /// In en, this message translates to:
  /// **'Sticker here'**
  String get stickerHere;

  /// No description provided for @stickerPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a sticker'**
  String get stickerPick;

  /// No description provided for @stampUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get stampUrgent;

  /// No description provided for @stampDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stampDone;

  /// No description provided for @stampImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get stampImportant;

  /// No description provided for @stampLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get stampLater;

  /// No description provided for @stickerArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get stickerArrow;

  /// No description provided for @stickerCircle.
  ///
  /// In en, this message translates to:
  /// **'Circled'**
  String get stickerCircle;

  /// No description provided for @stickerUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get stickerUnderline;

  /// No description provided for @stickerRing.
  ///
  /// In en, this message translates to:
  /// **'Coffee ring'**
  String get stickerRing;

  /// No description provided for @highlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter'**
  String get highlighter;

  /// No description provided for @threadStyle.
  ///
  /// In en, this message translates to:
  /// **'Made of'**
  String get threadStyle;

  /// No description provided for @threadYarn.
  ///
  /// In en, this message translates to:
  /// **'Yarn'**
  String get threadYarn;

  /// No description provided for @threadTwine.
  ///
  /// In en, this message translates to:
  /// **'Twine'**
  String get threadTwine;

  /// No description provided for @threadRibbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get threadRibbon;

  /// No description provided for @threadDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get threadDashed;

  /// No description provided for @threadBeads.
  ///
  /// In en, this message translates to:
  /// **'Beads'**
  String get threadBeads;

  /// No description provided for @tryingOn.
  ///
  /// In en, this message translates to:
  /// **'Trying it on: this is how it looks. Unlock Pro to keep it.'**
  String get tryingOn;

  /// No description provided for @tryOnStop.
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get tryOnStop;

  /// No description provided for @tryOnKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get tryOnKeep;

  /// No description provided for @proNudge.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Sticky Wall? Pro adds stickers, paper styles, walls, fonts and more, for one payment.'**
  String get proNudge;

  /// No description provided for @proNudgeAction.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get proNudgeAction;

  /// No description provided for @proPerkPaperStyles.
  ///
  /// In en, this message translates to:
  /// **'5 paper styles: lined, grid, dotted, index card, notebook page'**
  String get proPerkPaperStyles;

  /// No description provided for @proPerkStickers.
  ///
  /// In en, this message translates to:
  /// **'15 more stickers: rubber stamps, emoji and marker doodles'**
  String get proPerkStickers;

  /// No description provided for @proPerkMarkers.
  ///
  /// In en, this message translates to:
  /// **'5 more marker colors and a highlighter for the wall'**
  String get proPerkMarkers;

  /// No description provided for @proPerkThreads.
  ///
  /// In en, this message translates to:
  /// **'4 thread styles (twine, ribbon, dashed, beads) and 4 more colors'**
  String get proPerkThreads;

  /// No description provided for @proTryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a Pro wall, font or pin in Customize to try it on your own wall first.'**
  String get proTryHint;

  /// No description provided for @paperCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own color'**
  String get paperCustom;

  /// No description provided for @paperCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Mix a paper color'**
  String get paperCustomTitle;

  /// No description provided for @paperCustomHue.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get paperCustomHue;

  /// No description provided for @paperCustomStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get paperCustomStrength;

  /// No description provided for @paperCustomLightness.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get paperCustomLightness;

  /// No description provided for @boardMakePrivate.
  ///
  /// In en, this message translates to:
  /// **'Make private'**
  String get boardMakePrivate;

  /// No description provided for @boardMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Make public again'**
  String get boardMakePublic;

  /// No description provided for @boardPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Opens with your fingerprint or screen lock; kept off the widget, search and reminder texts'**
  String get boardPrivateHint;

  /// No description provided for @boardPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private board'**
  String get boardPrivate;

  /// No description provided for @boardShutHint.
  ///
  /// In en, this message translates to:
  /// **'Its notes stay hidden until you unlock it.'**
  String get boardShutHint;

  /// No description provided for @boardUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Open the private board'**
  String get boardUnlockReason;

  /// No description provided for @reminderPrivate.
  ///
  /// In en, this message translates to:
  /// **'A reminder on a private board'**
  String get reminderPrivate;

  /// No description provided for @widgetPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private board'**
  String get widgetPrivate;

  /// No description provided for @packEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get packEveryday;

  /// No description provided for @packTet.
  ///
  /// In en, this message translates to:
  /// **'Tết'**
  String get packTet;

  /// No description provided for @packChristmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas'**
  String get packChristmas;

  /// No description provided for @packMidAutumn.
  ///
  /// In en, this message translates to:
  /// **'Mid-Autumn'**
  String get packMidAutumn;

  /// No description provided for @packValentine.
  ///
  /// In en, this message translates to:
  /// **'Valentine\'s'**
  String get packValentine;

  /// No description provided for @stampNewYear.
  ///
  /// In en, this message translates to:
  /// **'Happy New Year'**
  String get stampNewYear;

  /// No description provided for @stampMerry.
  ///
  /// In en, this message translates to:
  /// **'Merry Christmas'**
  String get stampMerry;

  /// No description provided for @stampMidAutumn.
  ///
  /// In en, this message translates to:
  /// **'Mid-Autumn'**
  String get stampMidAutumn;

  /// No description provided for @stampLove.
  ///
  /// In en, this message translates to:
  /// **'Love you'**
  String get stampLove;

  /// No description provided for @stickerMai.
  ///
  /// In en, this message translates to:
  /// **'Apricot blossom'**
  String get stickerMai;

  /// No description provided for @stickerDao.
  ///
  /// In en, this message translates to:
  /// **'Peach blossom'**
  String get stickerDao;

  /// No description provided for @stickerStarLantern.
  ///
  /// In en, this message translates to:
  /// **'Star lantern'**
  String get stickerStarLantern;

  /// No description provided for @wallTet.
  ///
  /// In en, this message translates to:
  /// **'Tết · apricot'**
  String get wallTet;

  /// No description provided for @wallTetDao.
  ///
  /// In en, this message translates to:
  /// **'Tết · peach'**
  String get wallTetDao;

  /// No description provided for @wallXmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas green'**
  String get wallXmas;

  /// No description provided for @wallMoon.
  ///
  /// In en, this message translates to:
  /// **'Mid-Autumn night'**
  String get wallMoon;

  /// No description provided for @wallLove.
  ///
  /// In en, this message translates to:
  /// **'Valentine pink'**
  String get wallLove;

  /// No description provided for @proPerkSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasonal packs: Tết, Christmas, Mid-Autumn and Valentine\'s walls and stickers'**
  String get proPerkSeasons;

  /// No description provided for @proPerkPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private boards that open with your fingerprint'**
  String get proPerkPrivate;

  /// No description provided for @proPerkCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Mix any paper color you like'**
  String get proPerkCustomColor;

  /// No description provided for @seasonUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String seasonUntil(String date);

  /// No description provided for @confirmItsYou.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get confirmItsYou;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates & themes'**
  String get galleryTitle;

  /// No description provided for @galleryTemplates.
  ///
  /// In en, this message translates to:
  /// **'Board templates'**
  String get galleryTemplates;

  /// No description provided for @galleryThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get galleryThemes;

  /// No description provided for @gallerySearch.
  ///
  /// In en, this message translates to:
  /// **'Search templates'**
  String get gallerySearch;

  /// No description provided for @galleryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get galleryAll;

  /// No description provided for @galleryFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get galleryFree;

  /// No description provided for @galleryNothing.
  ///
  /// In en, this message translates to:
  /// **'No template matches that.'**
  String get galleryNothing;

  /// No description provided for @catProductivity.
  ///
  /// In en, this message translates to:
  /// **'Plans & lists'**
  String get catProductivity;

  /// No description provided for @catStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get catStudy;

  /// No description provided for @catCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get catCreative;

  /// No description provided for @catPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get catPersonal;

  /// No description provided for @catFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catFamily;

  /// No description provided for @catSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get catSeasonal;

  /// No description provided for @catClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get catClassic;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get useTemplate;

  /// No description provided for @templateLook.
  ///
  /// In en, this message translates to:
  /// **'Look: {name}'**
  String templateLook(String name);

  /// No description provided for @templateFreeLook.
  ///
  /// In en, this message translates to:
  /// **'That look is part of Pro, so the board starts on cork; you can change it any time.'**
  String get templateFreeLook;

  /// No description provided for @templateUsed.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is ready. Change any note, or clear the examples from the board\'s sheet.'**
  String templateUsed(String name);

  /// No description provided for @applyTheme.
  ///
  /// In en, this message translates to:
  /// **'Apply to “{board}”'**
  String applyTheme(String board);

  /// No description provided for @themeApplied.
  ///
  /// In en, this message translates to:
  /// **'“{name}” applied'**
  String themeApplied(String name);

  /// No description provided for @themeKeepsContent.
  ///
  /// In en, this message translates to:
  /// **'Changes the wall, the papers and their ruling, the pins, the handwriting and the threads on this board. What you wrote and where it sits stay as they are.'**
  String get themeKeepsContent;

  /// No description provided for @proUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Pro'**
  String get proUnlock;

  /// No description provided for @previewNoteA.
  ///
  /// In en, this message translates to:
  /// **'Call the bakery'**
  String get previewNoteA;

  /// No description provided for @previewNoteB.
  ///
  /// In en, this message translates to:
  /// **'Picnic on Sunday'**
  String get previewNoteB;

  /// No description provided for @previewItemA.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get previewItemA;

  /// No description provided for @previewItemB.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get previewItemB;

  /// No description provided for @newBoardBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank board'**
  String get newBoardBlank;

  /// No description provided for @newBoardFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From a template'**
  String get newBoardFromTemplate;

  /// No description provided for @newBoardFromTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'45 boards to start from: planners, study, family, moodboards…'**
  String get newBoardFromTemplateHint;

  /// No description provided for @clearSamples.
  ///
  /// In en, this message translates to:
  /// **'Clear the examples'**
  String get clearSamples;

  /// No description provided for @clearSamplesHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps the headings, stickers and wall'**
  String get clearSamplesHint;

  /// No description provided for @samplesCleared.
  ///
  /// In en, this message translates to:
  /// **'Examples cleared'**
  String get samplesCleared;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change the theme'**
  String get changeTheme;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sticky Wall'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Notes on a real wall: write them, move them, tie them together. How would you like to start?'**
  String get welcomeBody;

  /// No description provided for @welcomeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Pick a template'**
  String get welcomeTemplate;

  /// No description provided for @welcomeTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Planners, study boards, moodboards and more, ready to edit'**
  String get welcomeTemplateHint;

  /// No description provided for @welcomeBlank.
  ///
  /// In en, this message translates to:
  /// **'Start with a blank wall'**
  String get welcomeBlank;

  /// No description provided for @welcomeBlankHint.
  ///
  /// In en, this message translates to:
  /// **'The sample notes are cleared'**
  String get welcomeBlankHint;

  /// No description provided for @welcomeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore the sample wall'**
  String get welcomeExplore;

  /// No description provided for @welcomeExploreHint.
  ///
  /// In en, this message translates to:
  /// **'A few notes that show what you can do; delete them any time'**
  String get welcomeExploreHint;

  /// No description provided for @memoryWall.
  ///
  /// In en, this message translates to:
  /// **'Memory wall'**
  String get memoryWall;

  /// No description provided for @memoryWallHint.
  ///
  /// In en, this message translates to:
  /// **'Many photos at once, laid out for you to edit'**
  String get memoryWallHint;

  /// No description provided for @memoryPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String memoryPhotoCount(int count);

  /// No description provided for @memoryTooMany.
  ///
  /// In en, this message translates to:
  /// **'A wall holds up to {max}; the first {max} are used.'**
  String memoryTooMany(int max);

  /// No description provided for @memoryLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get memoryLayout;

  /// No description provided for @layoutCollage.
  ///
  /// In en, this message translates to:
  /// **'Collage'**
  String get layoutCollage;

  /// No description provided for @layoutPrints.
  ///
  /// In en, this message translates to:
  /// **'Prints in rows'**
  String get layoutPrints;

  /// No description provided for @layoutFilm.
  ///
  /// In en, this message translates to:
  /// **'Film strip'**
  String get layoutFilm;

  /// No description provided for @layoutTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get layoutTimeline;

  /// No description provided for @memoryLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get memoryLook;

  /// No description provided for @memoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Make the wall'**
  String get memoryCreate;

  /// No description provided for @memoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoryTitle;

  /// No description provided for @memoryMade.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo is on your memory wall} other{{count} photos are on your memory wall}}. Tap one to add a caption.'**
  String memoryMade(int count);
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
