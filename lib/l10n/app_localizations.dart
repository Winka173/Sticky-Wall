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
  /// **'Add note'**
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
  /// **'This link is already on this board'**
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
  /// **'{count, plural, =1{Delete the 1 item in the Trash for good? It can\'t be brought back.} other{Delete all {count} items in the Trash for good? They can\'t be brought back.}}'**
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

  /// No description provided for @arrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange…'**
  String get arrange;

  /// No description provided for @tidyHint.
  ///
  /// In en, this message translates to:
  /// **'Neat rows, nothing overlapping'**
  String get tidyHint;

  /// No description provided for @tidyByColorHint.
  ///
  /// In en, this message translates to:
  /// **'Notes of the same paper colour together'**
  String get tidyByColorHint;

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
  /// **'Thread color'**
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

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImage;

  /// No description provided for @saveShort.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveShort;

  /// No description provided for @shareBoard.
  ///
  /// In en, this message translates to:
  /// **'Share or save this board'**
  String get shareBoard;

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
  /// **'Lined'**
  String get patternRuled;

  /// No description provided for @patternGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get patternGrid;

  /// No description provided for @patternDots.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get patternDots;

  /// No description provided for @emote.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
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

  /// No description provided for @boardTrashed.
  ///
  /// In en, this message translates to:
  /// **'“{name}” moved to the Trash'**
  String boardTrashed(String name);

  /// No description provided for @trashNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get trashNotes;

  /// No description provided for @trashBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get trashBoards;

  /// No description provided for @boardInTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty board} =1{1 note} other{{count} notes}}'**
  String boardInTrash(int count);

  /// No description provided for @boardRestored.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is back'**
  String boardRestored(String name);

  /// No description provided for @deleteBoardForeverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” and everything on it for good? It can\'t be brought back.'**
  String deleteBoardForeverConfirm(String name);

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

  /// No description provided for @notesThisWay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note this way} other{{count} notes this way}}'**
  String notesThisWay(int count);

  /// No description provided for @gestureTips.
  ///
  /// In en, this message translates to:
  /// **'Gesture tips'**
  String get gestureTips;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupRestore;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall feedback'**
  String get feedbackSubject;

  /// No description provided for @feedbackNoMail.
  ///
  /// In en, this message translates to:
  /// **'No email app found. Write to {email}'**
  String feedbackNoMail(String email);

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataHint.
  ///
  /// In en, this message translates to:
  /// **'Every board, note, photo and recording on this phone'**
  String get deleteAllDataHint;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes every board and note on this phone, the Trash, the photos and recordings, and the automatic backups. Your settings and Sticky Wall Pro stay. If sync is on, it is switched off first, so your other devices keep their copy. Make a backup first if you might want anything back.'**
  String get deleteAllBody;

  /// No description provided for @deleteAllContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get deleteAllContinue;

  /// No description provided for @deleteAllSureTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAllSureTitle;

  /// No description provided for @deleteAllSureBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteAllSureBody;

  /// No description provided for @deleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get deleteAllDone;

  /// No description provided for @wallSemantics.
  ///
  /// In en, this message translates to:
  /// **'Wall. Long-press an empty spot to stick a note there.'**
  String get wallSemantics;

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
  /// **'Long-press an empty spot to stick a note or photos there. Pinch to zoom, or double-tap the wall to zoom back. The frame button shows everything.'**
  String get tipWallBody;

  /// No description provided for @tipDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to another board'**
  String get tipDropTitle;

  /// No description provided for @tipDropBody.
  ///
  /// In en, this message translates to:
  /// **'Drop a dragged note on a board tab to move it to that board. To delete a note, long-press it and choose Delete; it waits in the Trash for 30 days.'**
  String get tipDropBody;

  /// No description provided for @tipSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select several'**
  String get tipSelectTitle;

  /// No description provided for @tipSelectBody.
  ///
  /// In en, this message translates to:
  /// **'Long-press a note → Select. Starting on an empty spot, draw a loop around notes to add them; drag any selected note to move the whole group.'**
  String get tipSelectBody;

  /// No description provided for @tipDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw on the wall'**
  String get tipDrawTitle;

  /// No description provided for @tipDrawBody.
  ///
  /// In en, this message translates to:
  /// **'The pen in the toolbar starts marker mode: one finger draws behind the notes, two still zoom. Rub the eraser across ink to remove only the parts you touch. Undo and Done sit in the bar below.'**
  String get tipDrawBody;

  /// No description provided for @tipUndoTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tipUndoTitle;

  /// No description provided for @tipUndoBody.
  ///
  /// In en, this message translates to:
  /// **'An Undo button appears for a few seconds after every move, turn, resize, tidy-up or board change.'**
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
  /// **'Backup restored'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that backup'**
  String get importFailed;

  /// No description provided for @importReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Next you choose: add the backup to what is here, or replace everything.'**
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
  /// **'This isn\'t a backup file, or part of it is missing. Paste the whole file, with nothing cut off.'**
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

  /// No description provided for @importTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This backup is too big to open on this phone (over 300 MB). Make a smaller backup on the other device, or move fewer photos at a time.'**
  String get importTooLarge;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get syncTitle;

  /// No description provided for @syncOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off: everything stays on this phone'**
  String get syncOffHint;

  /// No description provided for @syncReady.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get syncReady;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Synced {when}'**
  String syncDone(String when);

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: will sync when the connection is back'**
  String get syncOffline;

  /// No description provided for @syncAuthNeeded.
  ///
  /// In en, this message translates to:
  /// **'Google needs you to allow access again: turn sync off and on'**
  String get syncAuthNeeded;

  /// No description provided for @syncQuota.
  ///
  /// In en, this message translates to:
  /// **'Your Google Drive is full, so nothing new was sent'**
  String get syncQuota;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync this time. Your notes here are unchanged.'**
  String get syncFailed;

  /// No description provided for @syncExplain.
  ///
  /// In en, this message translates to:
  /// **'Keeps your boards, notes, threads, photos, recordings and Trash the same on every Android device signed in to the same Google account. It uses a hidden Sticky Wall folder in your Google Drive; your other Drive files are never seen. Works offline and catches up later. Not the same as a backup: a deletion syncs too, so keep making backups.'**
  String get syncExplain;

  /// No description provided for @syncWithDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get syncWithDrive;

  /// No description provided for @syncIncludeLocked.
  ///
  /// In en, this message translates to:
  /// **'Include locked boards'**
  String get syncIncludeLocked;

  /// No description provided for @syncIncludeLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Locked boards are locked in the app, not encrypted: switched on, their notes are stored in your Google Drive like the others.'**
  String get syncIncludeLockedHint;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncConflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note was changed on two devices at once: both versions are kept.} other{{count} notes were changed on two devices at once: both versions are kept.}}'**
  String syncConflicts(int count);

  /// No description provided for @syncMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo or recording hasn\'t arrived from another device yet.} other{{count} photos or recordings haven\'t arrived from another device yet.}}'**
  String syncMissing(int count);

  /// No description provided for @syncOffNote.
  ///
  /// In en, this message translates to:
  /// **'Turning sync off keeps everything on this phone. The copy in Google Drive stays for your other devices; delete it in Google Drive settings → Manage apps.'**
  String get syncOffNote;

  /// No description provided for @syncPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall has no servers: the data goes only to your own Google Drive. iPhone and Android do not sync with each other; move between them with a backup file.'**
  String get syncPrivacy;

  /// No description provided for @syncConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to Google Drive. Check the connection, or try again later.'**
  String get syncConnectFailed;

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

  /// No description provided for @saveChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your changes to this note?'**
  String get saveChangesTitle;

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
  /// **'{count, plural, =1{Its note goes to the Trash with it. You can restore the board within 30 days.} other{Its {count} notes go to the Trash with it. You can restore the board within 30 days.}}'**
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

  /// No description provided for @toolLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get toolLayout;

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
  /// **'Tap notes, or draw a loop around them'**
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
  /// **'No other notes on this board to tie to'**
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
  /// **'Unstack all'**
  String get unstack;

  /// No description provided for @takeOutOfStack.
  ///
  /// In en, this message translates to:
  /// **'Take out of the stack'**
  String get takeOutOfStack;

  /// No description provided for @otherBoardsMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more on other boards} other{{count} more on other boards}}'**
  String otherBoardsMatches(int count);

  /// No description provided for @onOtherBoards.
  ///
  /// In en, this message translates to:
  /// **'On other boards'**
  String get onOtherBoards;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticky Wall Pro'**
  String get proTitle;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @proPitch.
  ///
  /// In en, this message translates to:
  /// **'One payment, yours for good. Everything you have now stays free.'**
  String get proPitch;

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
  /// **'Payment pending. Pro unlocks as soon as the store confirms it.'**
  String get proPending;

  /// No description provided for @proFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Please try again.'**
  String get proFailed;

  /// No description provided for @proUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren\'t available right now. Check your connection and app store account, then try again.'**
  String get proUnavailable;

  /// No description provided for @proKeepsLook.
  ///
  /// In en, this message translates to:
  /// **'Notes keep their Pro papers and styles wherever you move them.'**
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

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyHint.
  ///
  /// In en, this message translates to:
  /// **'What Sticky Wall keeps, and where. Opens in your browser.'**
  String get privacyPolicyHint;

  /// No description provided for @termsOfServiceHint.
  ///
  /// In en, this message translates to:
  /// **'The rules for using Sticky Wall and Pro. Opens in your browser.'**
  String get termsOfServiceHint;

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
  /// **'Which board, what it lists, colors and text size'**
  String get widgetSettingsHint;

  /// No description provided for @widgetBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get widgetBoardLabel;

  /// No description provided for @widgetBoardCurrent.
  ///
  /// In en, this message translates to:
  /// **'The open board'**
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
  /// **'To add it: touch and hold an empty spot on your home screen, add a widget and pick Sticky Wall.'**
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

  /// No description provided for @paperFlecks.
  ///
  /// In en, this message translates to:
  /// **'Soft flecks'**
  String get paperFlecks;

  /// No description provided for @paperStitched.
  ///
  /// In en, this message translates to:
  /// **'Stitched edge'**
  String get paperStitched;

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
  /// **'Circle'**
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

  /// No description provided for @inkCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Mix a pen color'**
  String get inkCustomTitle;

  /// No description provided for @inkCustom.
  ///
  /// In en, this message translates to:
  /// **'Any color'**
  String get inkCustom;

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
  /// **'Lock this board'**
  String get boardMakePrivate;

  /// No description provided for @boardMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Remove the lock'**
  String get boardMakePublic;

  /// No description provided for @boardPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Opens with your fingerprint or screen lock; kept off the widget, search and reminder texts. A lock in the app, not encryption.'**
  String get boardPrivateHint;

  /// No description provided for @boardPrivate.
  ///
  /// In en, this message translates to:
  /// **'Locked board'**
  String get boardPrivate;

  /// No description provided for @boardShutHint.
  ///
  /// In en, this message translates to:
  /// **'Its notes stay hidden until you unlock it.'**
  String get boardShutHint;

  /// No description provided for @boardUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Open the locked board'**
  String get boardUnlockReason;

  /// No description provided for @reminderPrivate.
  ///
  /// In en, this message translates to:
  /// **'A reminder on a locked board'**
  String get reminderPrivate;

  /// No description provided for @widgetPrivate.
  ///
  /// In en, this message translates to:
  /// **'Locked board'**
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
  /// **'Theme: {name}'**
  String templateLook(String name);

  /// No description provided for @templateFreeLook.
  ///
  /// In en, this message translates to:
  /// **'Without Pro this board is made in “{name}”, shown above. Pro brings the look it was designed for.'**
  String templateFreeLook(String name);

  /// No description provided for @templateUsed.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is ready. Change any note, or clear the examples from the board\'s menu.'**
  String templateUsed(String name);

  /// No description provided for @applyTheme.
  ///
  /// In en, this message translates to:
  /// **'Apply to this board'**
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
  /// **'A memory wall holds up to {max} photos; the first {max} are used.'**
  String memoryTooMany(int max);

  /// No description provided for @memoryLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get memoryLayout;

  /// No description provided for @memoryPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview of the memory wall with your photos'**
  String get memoryPreview;

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
  /// **'Theme'**
  String get memoryLook;

  /// No description provided for @memoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Make the wall'**
  String get memoryCreate;

  /// No description provided for @memoryAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get memoryAddPhotos;

  /// No description provided for @memoryAddPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Select several photos, then confirm. Add up to {max} photos here.'**
  String memoryAddPhotosHint(int max);

  /// No description provided for @memoryDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo was already chosen, so it was left out.} other{{count} photos were already chosen, so they were left out.}}'**
  String memoryDuplicates(int count);

  /// No description provided for @memoryRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {n}'**
  String memoryRemovePhoto(int n);

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

  /// No description provided for @allBoards.
  ///
  /// In en, this message translates to:
  /// **'All boards'**
  String get allBoards;

  /// No description provided for @allBoardsCount.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String allBoardsCount(int count);

  /// No description provided for @dropOnBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Drop on a board'**
  String get dropOnBoardHint;

  /// No description provided for @boardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boardsTitle;

  /// No description provided for @boardPanelShow.
  ///
  /// In en, this message translates to:
  /// **'Show board list'**
  String get boardPanelShow;

  /// No description provided for @boardPanelHide.
  ///
  /// In en, this message translates to:
  /// **'Hide board list'**
  String get boardPanelHide;

  /// No description provided for @boardNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notes} =1{1 note} other{{count} notes}}'**
  String boardNoteCount(int count);

  /// No description provided for @duplicateBoard.
  ///
  /// In en, this message translates to:
  /// **'Duplicate board'**
  String get duplicateBoard;

  /// No description provided for @boardCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String boardCopyName(String name);

  /// No description provided for @boardDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Board duplicated'**
  String get boardDuplicated;

  /// No description provided for @shareWhere.
  ///
  /// In en, this message translates to:
  /// **'Save to which board?'**
  String get shareWhere;

  /// No description provided for @sharedPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo shared} other{{count} photos shared}}'**
  String sharedPhotos(int count);

  /// No description provided for @sharePinPhotos.
  ///
  /// In en, this message translates to:
  /// **'Pin them on a board'**
  String get sharePinPhotos;

  /// No description provided for @sharePinPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Each photo as its own print'**
  String get sharePinPhotosHint;

  /// No description provided for @sharedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo couldn\'t be used: too big, unreadable, or over the 20 a share can bring.} other{{count} photos couldn\'t be used: too big, unreadable, or over the 20 a share can bring.}}'**
  String sharedSkipped(int count);

  /// No description provided for @sharedSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to “{board}”'**
  String sharedSaved(String board);

  /// No description provided for @openNote.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openNote;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get restoreTitle;

  /// No description provided for @restoreMade.
  ///
  /// In en, this message translates to:
  /// **'Made {date}'**
  String restoreMade(String date);

  /// No description provided for @restoreUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'Date unknown'**
  String get restoreUnknownDate;

  /// No description provided for @restoreSize.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String restoreSize(String size);

  /// No description provided for @restoreBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get restoreBoards;

  /// No description provided for @restoreNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get restoreNotes;

  /// No description provided for @restoreInTrash.
  ///
  /// In en, this message translates to:
  /// **'{count} in the trash'**
  String restoreInTrash(int count);

  /// No description provided for @restorePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get restorePhotos;

  /// No description provided for @restoreRecordings.
  ///
  /// In en, this message translates to:
  /// **'Voice notes'**
  String get restoreRecordings;

  /// No description provided for @restoreThreads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get restoreThreads;

  /// No description provided for @restoreStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get restoreStickers;

  /// No description provided for @restoreLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked boards'**
  String get restoreLocked;

  /// No description provided for @restoreBoardsInTrash.
  ///
  /// In en, this message translates to:
  /// **'Boards in the Trash'**
  String get restoreBoardsInTrash;

  /// No description provided for @restoreOmitted.
  ///
  /// In en, this message translates to:
  /// **'Files that can\'t be read (left out)'**
  String get restoreOmitted;

  /// No description provided for @restoreConflicts.
  ///
  /// In en, this message translates to:
  /// **'{boards, plural, =1{1 board} other{{boards} boards}} and {notes, plural, =1{1 note} other{{notes} notes}} in it are already on this phone.'**
  String restoreConflicts(int boards, int notes);

  /// No description provided for @restoreMerge.
  ///
  /// In en, this message translates to:
  /// **'Add to what is here'**
  String get restoreMerge;

  /// No description provided for @restoreMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Everything here stays. Boards and notes from the backup are added; anything already here is not copied twice.'**
  String get restoreMergeHint;

  /// No description provided for @restoreReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace everything'**
  String get restoreReplace;

  /// No description provided for @restoreReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'What is here now is replaced by the backup. Undo is offered right after.'**
  String get restoreReplaceHint;

  /// No description provided for @restoreMerged.
  ///
  /// In en, this message translates to:
  /// **'Backup added'**
  String get restoreMerged;

  /// No description provided for @packFeelings.
  ///
  /// In en, this message translates to:
  /// **'Feelings'**
  String get packFeelings;

  /// No description provided for @packStudy.
  ///
  /// In en, this message translates to:
  /// **'Study & desk'**
  String get packStudy;

  /// No description provided for @packHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get packHome;

  /// No description provided for @packPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get packPlanner;

  /// No description provided for @packNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get packNature;

  /// No description provided for @packFood.
  ///
  /// In en, this message translates to:
  /// **'Food & treats'**
  String get packFood;

  /// No description provided for @packTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get packTravel;

  /// No description provided for @packVietnam.
  ///
  /// In en, this message translates to:
  /// **'Vietnam'**
  String get packVietnam;

  /// No description provided for @packTapes.
  ///
  /// In en, this message translates to:
  /// **'Washi tape'**
  String get packTapes;

  /// No description provided for @framePrint.
  ///
  /// In en, this message translates to:
  /// **'Plain print'**
  String get framePrint;

  /// No description provided for @framePolaroid.
  ///
  /// In en, this message translates to:
  /// **'Polaroid'**
  String get framePolaroid;

  /// No description provided for @frameFilm.
  ///
  /// In en, this message translates to:
  /// **'Film strip'**
  String get frameFilm;

  /// No description provided for @frameVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get frameVintage;

  /// No description provided for @frameTorn.
  ///
  /// In en, this message translates to:
  /// **'Torn paper'**
  String get frameTorn;

  /// No description provided for @frameRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get frameRounded;

  /// No description provided for @frameScrapbook.
  ///
  /// In en, this message translates to:
  /// **'Scrapbook'**
  String get frameScrapbook;

  /// No description provided for @photoFrame.
  ///
  /// In en, this message translates to:
  /// **'Photo frame'**
  String get photoFrame;

  /// No description provided for @memoryCaption.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get memoryCaption;

  /// No description provided for @captionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get captionNone;

  /// No description provided for @captionNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get captionNumbers;

  /// No description provided for @captionDate.
  ///
  /// In en, this message translates to:
  /// **'Today\'s date'**
  String get captionDate;

  /// No description provided for @layoutHero.
  ///
  /// In en, this message translates to:
  /// **'Big photo'**
  String get layoutHero;

  /// No description provided for @shufflePhotos.
  ///
  /// In en, this message translates to:
  /// **'Shuffle the photos'**
  String get shufflePhotos;

  /// No description provided for @framesAll.
  ///
  /// In en, this message translates to:
  /// **'One frame for every photo'**
  String get framesAll;

  /// No description provided for @photosShuffled.
  ///
  /// In en, this message translates to:
  /// **'Photos shuffled'**
  String get photosShuffled;

  /// No description provided for @framesApplied.
  ///
  /// In en, this message translates to:
  /// **'Frame changed'**
  String get framesApplied;

  /// No description provided for @makeHero.
  ///
  /// In en, this message translates to:
  /// **'Make it the big photo'**
  String get makeHero;

  /// No description provided for @heroSet.
  ///
  /// In en, this message translates to:
  /// **'Big photo set'**
  String get heroSet;

  /// No description provided for @pinBoard.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pinBoard;

  /// No description provided for @unpinBoard.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinBoard;

  /// No description provided for @editedToday.
  ///
  /// In en, this message translates to:
  /// **'edited today'**
  String get editedToday;

  /// No description provided for @editedYesterday.
  ///
  /// In en, this message translates to:
  /// **'edited yesterday'**
  String get editedYesterday;

  /// No description provided for @editedOn.
  ///
  /// In en, this message translates to:
  /// **'edited {date}'**
  String editedOn(String date);

  /// No description provided for @archiveNote.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveNote;

  /// No description provided for @archiveDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Every item is done: keep it out of the way'**
  String get archiveDoneHint;

  /// No description provided for @archiveBoard.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveBoard;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Moved to the Archive board'**
  String get archived;

  /// No description provided for @editorReadable.
  ///
  /// In en, this message translates to:
  /// **'Readable text'**
  String get editorReadable;

  /// No description provided for @editorHandwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get editorHandwriting;

  /// No description provided for @wallSoften.
  ///
  /// In en, this message translates to:
  /// **'Calm the wall behind the notes'**
  String get wallSoften;

  /// No description provided for @packMarks.
  ///
  /// In en, this message translates to:
  /// **'Note marks'**
  String get packMarks;

  /// No description provided for @packAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get packAnimals;

  /// No description provided for @packGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get packGarden;

  /// No description provided for @packOcean.
  ///
  /// In en, this message translates to:
  /// **'Sea & beach'**
  String get packOcean;

  /// No description provided for @packCozy.
  ///
  /// In en, this message translates to:
  /// **'Cozy home'**
  String get packCozy;

  /// No description provided for @packHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get packHobbies;

  /// No description provided for @packOffice.
  ///
  /// In en, this message translates to:
  /// **'Desk & office'**
  String get packOffice;

  /// No description provided for @packLove.
  ///
  /// In en, this message translates to:
  /// **'Love & celebration'**
  String get packLove;

  /// No description provided for @packFestiveVn.
  ///
  /// In en, this message translates to:
  /// **'Tết & Mid-Autumn'**
  String get packFestiveVn;

  /// No description provided for @packHolidays.
  ///
  /// In en, this message translates to:
  /// **'Christmas & Halloween'**
  String get packHolidays;

  /// No description provided for @addToWall.
  ///
  /// In en, this message translates to:
  /// **'Add to your wall'**
  String get addToWall;

  /// No description provided for @addToWallHint.
  ///
  /// In en, this message translates to:
  /// **'A thought, a plan, a little memory.'**
  String get addToWallHint;

  /// No description provided for @addTextHint.
  ///
  /// In en, this message translates to:
  /// **'Catch a thought'**
  String get addTextHint;

  /// No description provided for @addChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'One small step at a time'**
  String get addChecklistHint;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Pin a favorite moment'**
  String get addPhotoHint;

  /// No description provided for @addLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Keep something worth a look'**
  String get addLinkHint;

  /// No description provided for @addVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Say it before it slips away'**
  String get addVoiceHint;

  /// No description provided for @addDrawingHint.
  ///
  /// In en, this message translates to:
  /// **'Let your pen wander'**
  String get addDrawingHint;

  /// No description provided for @editorOptions.
  ///
  /// In en, this message translates to:
  /// **'Note options'**
  String get editorOptions;

  /// No description provided for @changeNoteType.
  ///
  /// In en, this message translates to:
  /// **'Change note type'**
  String get changeNoteType;

  /// No description provided for @galleryFeatured.
  ///
  /// In en, this message translates to:
  /// **'A few favorites to start'**
  String get galleryFeatured;

  /// No description provided for @previewOnYourWall.
  ///
  /// In en, this message translates to:
  /// **'Preview on your wall'**
  String get previewOnYourWall;

  /// No description provided for @previewOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Just a preview. Your wall stays as it was until you apply.'**
  String get previewOnlyHint;

  /// No description provided for @memoryPreviewPro.
  ///
  /// In en, this message translates to:
  /// **'Previewing Pro. Unlock to create with this look.'**
  String get memoryPreviewPro;

  /// No description provided for @guideReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay the guide'**
  String get guideReplay;

  /// No description provided for @guideReplayHint.
  ///
  /// In en, this message translates to:
  /// **'The wall in a minute, with a practice wall. Nothing on your boards changes.'**
  String get guideReplayHint;

  /// No description provided for @guideStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String guideStepOf(int step, int total);

  /// No description provided for @guideBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get guideBack;

  /// No description provided for @guideSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guideSkip;

  /// No description provided for @guideNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideNext;

  /// No description provided for @guideDoItForMe.
  ///
  /// In en, this message translates to:
  /// **'Do it for me'**
  String get guideDoItForMe;

  /// No description provided for @guideScatterTop.
  ///
  /// In en, this message translates to:
  /// **'Notes everywhere.'**
  String get guideScatterTop;

  /// No description provided for @guideScatterKey.
  ///
  /// In en, this message translates to:
  /// **'Found nowhere.'**
  String get guideScatterKey;

  /// No description provided for @guideScatterBody.
  ///
  /// In en, this message translates to:
  /// **'On a receipt, a torn sticky, your phone, a napkin…'**
  String get guideScatterBody;

  /// No description provided for @guideScatterAction.
  ///
  /// In en, this message translates to:
  /// **'Put them on a wall'**
  String get guideScatterAction;

  /// No description provided for @guideWallBefore.
  ///
  /// In en, this message translates to:
  /// **'One wall for '**
  String get guideWallBefore;

  /// No description provided for @guideWallKey.
  ///
  /// In en, this message translates to:
  /// **'all of it'**
  String get guideWallKey;

  /// No description provided for @guideWallBody.
  ///
  /// In en, this message translates to:
  /// **'On your phone. No account, no ads.'**
  String get guideWallBody;

  /// No description provided for @guideWallAction.
  ///
  /// In en, this message translates to:
  /// **'Show me how'**
  String get guideWallAction;

  /// No description provided for @guidePracticeBefore.
  ///
  /// In en, this message translates to:
  /// **'Try it on a '**
  String get guidePracticeBefore;

  /// No description provided for @guidePracticeKey.
  ///
  /// In en, this message translates to:
  /// **'practice wall'**
  String get guidePracticeKey;

  /// No description provided for @guidePracticeBody.
  ///
  /// In en, this message translates to:
  /// **'Do what is lit. It is only practice: nothing here is saved.'**
  String get guidePracticeBody;

  /// No description provided for @guidePracticeDoneBefore.
  ///
  /// In en, this message translates to:
  /// **'That’s '**
  String get guidePracticeDoneBefore;

  /// No description provided for @guidePracticeDoneKey.
  ///
  /// In en, this message translates to:
  /// **'the wall'**
  String get guidePracticeDoneKey;

  /// No description provided for @guidePracticeDoneBody.
  ///
  /// In en, this message translates to:
  /// **'The yellow paper adds a note, a finger moves it, and a red pin ties a thread. It was only practice: nothing was saved.'**
  String get guidePracticeDoneBody;

  /// No description provided for @guideTaskAdd.
  ///
  /// In en, this message translates to:
  /// **'A practice wall. Nothing here is saved.'**
  String get guideTaskAdd;

  /// No description provided for @guideTaskMove.
  ///
  /// In en, this message translates to:
  /// **'Your note is on the wall.'**
  String get guideTaskMove;

  /// No description provided for @guideTaskTie.
  ///
  /// In en, this message translates to:
  /// **'Tie it to the day it belongs to.'**
  String get guideTaskTie;

  /// No description provided for @guideLitAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap the yellow paper'**
  String get guideLitAdd;

  /// No description provided for @guideLitMove.
  ///
  /// In en, this message translates to:
  /// **'Drag the note onto the dashed spot'**
  String get guideLitMove;

  /// No description provided for @guideLitTie.
  ///
  /// In en, this message translates to:
  /// **'Pull its red pin onto “Saturday”'**
  String get guideLitTie;

  /// No description provided for @guideNoteWater.
  ///
  /// In en, this message translates to:
  /// **'Water the plants'**
  String get guideNoteWater;

  /// No description provided for @guideNoteSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get guideNoteSaturday;

  /// No description provided for @guideNoteMum.
  ///
  /// In en, this message translates to:
  /// **'Call Mum'**
  String get guideNoteMum;

  /// No description provided for @guideSpot.
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get guideSpot;

  /// No description provided for @guideNothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Done. Nothing was saved.'**
  String get guideNothingSaved;

  /// No description provided for @guideScrapPlumber.
  ///
  /// In en, this message translates to:
  /// **'Call the plumber'**
  String get guideScrapPlumber;

  /// No description provided for @guideScrapBirthday.
  ///
  /// In en, this message translates to:
  /// **'Mum’s birthday, Sat'**
  String get guideScrapBirthday;

  /// No description provided for @guideScrapWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi: garden2026'**
  String get guideScrapWifi;

  /// No description provided for @guideScrapFlowers.
  ///
  /// In en, this message translates to:
  /// **'Buy flowers'**
  String get guideScrapFlowers;

  /// No description provided for @guideChooseBefore.
  ///
  /// In en, this message translates to:
  /// **'Make it '**
  String get guideChooseBefore;

  /// No description provided for @guideChooseKey.
  ///
  /// In en, this message translates to:
  /// **'yours'**
  String get guideChooseKey;

  /// No description provided for @guideChooseBody.
  ///
  /// In en, this message translates to:
  /// **'How would you like to start? Templates and new boards stay in the menu.'**
  String get guideChooseBody;

  /// No description provided for @guideChooseReplayBody.
  ///
  /// In en, this message translates to:
  /// **'Templates & themes wait in the More menu, and the + tab starts a new board, whenever you like.'**
  String get guideChooseReplayBody;

  /// No description provided for @guideStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get guideStart;

  /// No description provided for @guideDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guideDone;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @howToUseHint.
  ///
  /// In en, this message translates to:
  /// **'Short steps for each feature, or replay the introduction'**
  String get howToUseHint;

  /// No description provided for @howToUseTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get howToUseTopics;

  /// No description provided for @howToUseTopicOf.
  ///
  /// In en, this message translates to:
  /// **'Topic {n} of {total}'**
  String howToUseTopicOf(int n, int total);

  /// No description provided for @howToUsePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get howToUsePrevious;

  /// No description provided for @manualFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first note'**
  String get manualFirstTitle;

  /// No description provided for @manualFirstSummary.
  ///
  /// In en, this message translates to:
  /// **'Add, write, and save to your wall.'**
  String get manualFirstSummary;

  /// No description provided for @manualFirstStep1.
  ///
  /// In en, this message translates to:
  /// **'Tap the yellow paper at the bottom right.'**
  String get manualFirstStep1;

  /// No description provided for @manualFirstStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose Text to start writing.'**
  String get manualFirstStep2;

  /// No description provided for @manualFirstStep3.
  ///
  /// In en, this message translates to:
  /// **'Write your note, then tap the checkmark to save. Tap the note on the wall to edit it.'**
  String get manualFirstStep3;

  /// No description provided for @manualMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving and arranging'**
  String get manualMoveTitle;

  /// No description provided for @manualMoveSummary.
  ///
  /// In en, this message translates to:
  /// **'Put every note where you want it.'**
  String get manualMoveSummary;

  /// No description provided for @manualMoveStep1.
  ///
  /// In en, this message translates to:
  /// **'Drag a note with one finger to move it.'**
  String get manualMoveStep1;

  /// No description provided for @manualMoveStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap a note to show its corner handles. Drag the right handle to resize; the left one rotates it.'**
  String get manualMoveStep2;

  /// No description provided for @manualMoveStep3.
  ///
  /// In en, this message translates to:
  /// **'Open More → Arrange to tidy notes into rows. Pinch the wall with two fingers to zoom.'**
  String get manualMoveStep3;

  /// No description provided for @manualMoveStep4.
  ///
  /// In en, this message translates to:
  /// **'Made a mistake? Tap Undo just after a change.'**
  String get manualMoveStep4;

  /// No description provided for @manualThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Threads between notes'**
  String get manualThreadTitle;

  /// No description provided for @manualThreadSummary.
  ///
  /// In en, this message translates to:
  /// **'Connect ideas that belong together.'**
  String get manualThreadSummary;

  /// No description provided for @manualThreadStep1.
  ///
  /// In en, this message translates to:
  /// **'Drag a note’s red pin onto another note to connect them.'**
  String get manualThreadStep1;

  /// No description provided for @manualThreadStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap a thread to change its color, add a label or arrow, or cut it.'**
  String get manualThreadStep2;

  /// No description provided for @manualThreadStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the red pin to keep that note on top.'**
  String get manualThreadStep3;

  /// No description provided for @manualDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw on the wall'**
  String get manualDrawTitle;

  /// No description provided for @manualDrawSummary.
  ///
  /// In en, this message translates to:
  /// **'Sketch behind your notes.'**
  String get manualDrawSummary;

  /// No description provided for @manualDrawStep1.
  ///
  /// In en, this message translates to:
  /// **'Tap the pen in the bottom toolbar.'**
  String get manualDrawStep1;

  /// No description provided for @manualDrawStep2.
  ///
  /// In en, this message translates to:
  /// **'Draw with one finger. Use two fingers to move or zoom the wall.'**
  String get manualDrawStep2;

  /// No description provided for @manualDrawStep3.
  ///
  /// In en, this message translates to:
  /// **'Rub the eraser across ink to remove only the parts you touch. Undo restores the whole erase gesture. Tap Done to stop drawing.'**
  String get manualDrawStep3;

  /// No description provided for @manualBoardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Boards and Trash'**
  String get manualBoardsTitle;

  /// No description provided for @manualBoardsSummary.
  ///
  /// In en, this message translates to:
  /// **'Separate your projects and recover deleted notes.'**
  String get manualBoardsSummary;

  /// No description provided for @manualBoardsStep1.
  ///
  /// In en, this message translates to:
  /// **'Tap + beside the board tabs. Start with a blank board or a template.'**
  String get manualBoardsStep1;

  /// No description provided for @manualBoardsStep2.
  ///
  /// In en, this message translates to:
  /// **'Drag a note onto another board’s tab to move it there.'**
  String get manualBoardsStep2;

  /// No description provided for @manualBoardsStep3.
  ///
  /// In en, this message translates to:
  /// **'Open More → Trash to restore deleted notes or boards within 30 days.'**
  String get manualBoardsStep3;

  /// No description provided for @manualPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and memory walls'**
  String get manualPhotosTitle;

  /// No description provided for @manualPhotosSummary.
  ///
  /// In en, this message translates to:
  /// **'Add several photos and arrange your memories.'**
  String get manualPhotosSummary;

  /// No description provided for @manualPhotosStep1.
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot → Photos here to pin photos at that spot.'**
  String get manualPhotosStep1;

  /// No description provided for @manualPhotosStep2.
  ///
  /// In en, this message translates to:
  /// **'More → Pin photos on the wall lets you select several photos in one go. Confirm your selection in the photo picker.'**
  String get manualPhotosStep2;

  /// No description provided for @manualPhotosStep4.
  ///
  /// In en, this message translates to:
  /// **'Tap the add-photo icon beside the photo count for more (up to 20). Choose a layout, frame and theme, then tap Make the wall.'**
  String get manualPhotosStep4;

  /// No description provided for @manualPhotosStep3.
  ///
  /// In en, this message translates to:
  /// **'Yellow paper → Memory wall. Select photos and confirm to open the preview.'**
  String get manualPhotosStep3;

  /// No description provided for @manualFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Search and views'**
  String get manualFindTitle;

  /// No description provided for @manualFindSummary.
  ///
  /// In en, this message translates to:
  /// **'Find notes and switch how you see them.'**
  String get manualFindSummary;

  /// No description provided for @manualFindStep1.
  ///
  /// In en, this message translates to:
  /// **'Tap Search and type a word. Accents are optional: “tuoi” finds “Tưới cây”.'**
  String get manualFindStep1;

  /// No description provided for @manualFindStep2.
  ///
  /// In en, this message translates to:
  /// **'Use the view button at the bottom left to choose Wall, Grid, or List.'**
  String get manualFindStep2;

  /// No description provided for @manualFindStep3.
  ///
  /// In en, this message translates to:
  /// **'Long-press a note → Select notes to act on several at once. You can also draw a loop from an empty spot.'**
  String get manualFindStep3;

  /// No description provided for @manualKindsTitle.
  ///
  /// In en, this message translates to:
  /// **'Note types and reminders'**
  String get manualKindsTitle;

  /// No description provided for @manualKindsSummary.
  ///
  /// In en, this message translates to:
  /// **'Lists, recordings, and reminders in one place.'**
  String get manualKindsSummary;

  /// No description provided for @manualKindsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the yellow paper and choose a type. Try a to-do list; labels and stickers are further down.'**
  String get manualKindsStep1;

  /// No description provided for @manualKindsStep2.
  ///
  /// In en, this message translates to:
  /// **'Choose Voice note. Tap the microphone to record, or hold it and release to stop.'**
  String get manualKindsStep2;

  /// No description provided for @manualKindsStep3.
  ///
  /// In en, this message translates to:
  /// **'In a note, tap Reminder. Choose a time and repeat schedule if needed.'**
  String get manualKindsStep3;

  /// No description provided for @manualKindsStep4.
  ///
  /// In en, this message translates to:
  /// **'Long-press a note → Lock in place to prevent accidental moves.'**
  String get manualKindsStep4;

  /// No description provided for @manualLooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates and themes'**
  String get manualLooksTitle;

  /// No description provided for @manualLooksSummary.
  ///
  /// In en, this message translates to:
  /// **'Start with a layout, then choose its look.'**
  String get manualLooksSummary;

  /// No description provided for @manualLooksStep1.
  ///
  /// In en, this message translates to:
  /// **'Open More → Templates & themes to browse board templates.'**
  String get manualLooksStep1;

  /// No description provided for @manualLooksStep2.
  ///
  /// In en, this message translates to:
  /// **'Apply a template to create an editable board. Its menu → Clear examples removes sample notes and keeps the headings.'**
  String get manualLooksStep2;

  /// No description provided for @manualLooksStep3.
  ///
  /// In en, this message translates to:
  /// **'Board menu → Change theme updates its look without changing your words. Use Undo to go back.'**
  String get manualLooksStep3;

  /// No description provided for @manualLooksStep4.
  ///
  /// In en, this message translates to:
  /// **'Tap the active board’s tab again to edit, lock, or delete that board.'**
  String get manualLooksStep4;

  /// No description provided for @manualShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share and export'**
  String get manualShareTitle;

  /// No description provided for @manualShareSummary.
  ///
  /// In en, this message translates to:
  /// **'Send a note or board; receive content from other apps.'**
  String get manualShareSummary;

  /// No description provided for @manualShareStep1.
  ///
  /// In en, this message translates to:
  /// **'Long-press a note. Share sends a picture; Save image saves it to your photos.'**
  String get manualShareStep1;

  /// No description provided for @manualShareStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap Share at the top. Export the whole board or the visible area as an image or PDF.'**
  String get manualShareStep2;

  /// No description provided for @manualShareStep3.
  ///
  /// In en, this message translates to:
  /// **'From another app, share text, a link, or photos to Sticky Wall, then choose a board.'**
  String get manualShareStep3;

  /// No description provided for @manualSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Keeping it safe'**
  String get manualSafeTitle;

  /// No description provided for @manualSafeSummary.
  ///
  /// In en, this message translates to:
  /// **'Back up, move to a new phone, and protect your wall.'**
  String get manualSafeSummary;

  /// No description provided for @manualSafeStep1.
  ///
  /// In en, this message translates to:
  /// **'Settings → Data → Back up notes saves all boards, photos, and recordings in one file. Keep a copy outside this phone.'**
  String get manualSafeStep1;

  /// No description provided for @manualSafeStep2.
  ///
  /// In en, this message translates to:
  /// **'New phone: back up on the old one and transfer the file. On the new phone, open Settings → Data → Restore backup and review before restoring.'**
  String get manualSafeStep2;

  /// No description provided for @manualSafeSync.
  ///
  /// In en, this message translates to:
  /// **'Settings → Data → Sync across devices uses your Google Drive. Turn it on on each device you want to sync.'**
  String get manualSafeSync;

  /// No description provided for @manualSafeStep3.
  ///
  /// In en, this message translates to:
  /// **'Settings → Privacy → App lock protects the app with your device lock. Lock one board from its tab menu.'**
  String get manualSafeStep3;

  /// No description provided for @manualYoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get manualYoursTitle;

  /// No description provided for @manualYoursSummary.
  ///
  /// In en, this message translates to:
  /// **'Change the look, language, and home-screen widget.'**
  String get manualYoursSummary;

  /// No description provided for @manualYoursStep1.
  ///
  /// In en, this message translates to:
  /// **'Tap the palette at the top to change the wall, handwriting, or pins. Pro styles can be previewed.'**
  String get manualYoursStep1;

  /// No description provided for @manualYoursStep2.
  ///
  /// In en, this message translates to:
  /// **'More → Lights off dims the wall. Set a schedule in Customize if you like.'**
  String get manualYoursStep2;

  /// No description provided for @manualYoursStep3.
  ///
  /// In en, this message translates to:
  /// **'Settings → General → Home-screen widget: choose a board, then add the widget from your phone’s home screen.'**
  String get manualYoursStep3;

  /// No description provided for @manualYoursStep4.
  ///
  /// In en, this message translates to:
  /// **'Settings → General → Language changes the app’s language.'**
  String get manualYoursStep4;

  /// No description provided for @manualTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get manualTabHome;

  /// No description provided for @manualTabWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get manualTabWork;

  /// No description provided for @manualSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'tuoi'**
  String get manualSearchQuery;

  /// No description provided for @manualPhotoCaption.
  ///
  /// In en, this message translates to:
  /// **'Summer 2026'**
  String get manualPhotoCaption;

  /// No description provided for @proGroupWall.
  ///
  /// In en, this message translates to:
  /// **'Make the wall yours'**
  String get proGroupWall;

  /// No description provided for @proGroupPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper, pins and stickers'**
  String get proGroupPaper;

  /// No description provided for @proGroupMore.
  ///
  /// In en, this message translates to:
  /// **'Tie, draw, keep private'**
  String get proGroupMore;

  /// No description provided for @proWallsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more walls'**
  String proWallsTitle(int count);

  /// No description provided for @proWallsBody.
  ///
  /// In en, this message translates to:
  /// **'A Pro wall changes the whole board under your notes. Tap one in Customize to try it on your own board first.'**
  String get proWallsBody;

  /// No description provided for @proPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more theme packs'**
  String proPacksTitle(int count);

  /// No description provided for @proPacksLine.
  ///
  /// In en, this message translates to:
  /// **'Wall, papers, font and pins in one tap'**
  String get proPacksLine;

  /// No description provided for @proPacksBody.
  ///
  /// In en, this message translates to:
  /// **'A theme pack restyles a board at once: its wall, paper colors and ruling, handwriting, pins and threads. Preview any pack on your board; Undo puts it back.'**
  String get proPacksBody;

  /// No description provided for @proSeasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seasonal packs'**
  String get proSeasonsTitle;

  /// No description provided for @proSeasonsBody.
  ///
  /// In en, this message translates to:
  /// **'{walls} festive walls and {stickers} stickers for the holidays. Each pack moves to the front of the list around its day.'**
  String proSeasonsBody(int walls, int stickers);

  /// No description provided for @proFontsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more handwriting fonts'**
  String proFontsTitle(int count);

  /// No description provided for @proFontsBody.
  ///
  /// In en, this message translates to:
  /// **'Each one has the full Vietnamese alphabet and is sized to match the others, so notes keep their shape when you switch. Try one on in Customize first.'**
  String get proFontsBody;

  /// No description provided for @proPapersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more paper colors'**
  String proPapersTitle(int count);

  /// No description provided for @proPapersLine.
  ///
  /// In en, this message translates to:
  /// **'And any color you mix yourself'**
  String get proPapersLine;

  /// No description provided for @proPapersBody.
  ///
  /// In en, this message translates to:
  /// **'Lime, coral, periwinkle, sage, kraft and white, each still easy to read with the lights off. Or mix a paper of your own for one note.'**
  String get proPapersBody;

  /// No description provided for @proPaperStylesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} paper styles'**
  String proPaperStylesTitle(int count);

  /// No description provided for @proPaperStylesBody.
  ///
  /// In en, this message translates to:
  /// **'Rule a note like a notebook page, graph paper or an index card. Ruled papers suit running text; lists take squares or dots.'**
  String get proPaperStylesBody;

  /// No description provided for @proPinsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more ways to pin'**
  String proPinsTitle(int count);

  /// No description provided for @proPinsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what holds your notes up. A note pinned to the top still shows its pin in gold.'**
  String get proPinsBody;

  /// No description provided for @proStickersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more stickers'**
  String proStickersTitle(int count);

  /// No description provided for @proStickersLine.
  ///
  /// In en, this message translates to:
  /// **'Illustrated packs and washi tapes'**
  String get proStickersLine;

  /// No description provided for @proStickersBody.
  ///
  /// In en, this message translates to:
  /// **'The whole library: hand-drawn stickers for study, home, planning, feelings and the holidays, plus washi tapes to stick across the wall.'**
  String get proStickersBody;

  /// No description provided for @proFramesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} photo frames'**
  String proFramesTitle(int count);

  /// No description provided for @proFramesBody.
  ///
  /// In en, this message translates to:
  /// **'Frame one photo print, or every photo on a memory wall at once.'**
  String get proFramesBody;

  /// No description provided for @proThreadsTitle.
  ///
  /// In en, this message translates to:
  /// **'{styles} thread styles, {colors} more colors'**
  String proThreadsTitle(int styles, int colors);

  /// No description provided for @proThreadsBody.
  ///
  /// In en, this message translates to:
  /// **'Tie notes together with twine, ribbon, a dashed cord or a string of beads, in pink, teal, brown or white.'**
  String get proThreadsBody;

  /// No description provided for @proMarkersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more marker colors'**
  String proMarkersTitle(int count);

  /// No description provided for @proMarkersLine.
  ///
  /// In en, this message translates to:
  /// **'And any ink you mix'**
  String get proMarkersLine;

  /// No description provided for @proMarkersBody.
  ///
  /// In en, this message translates to:
  /// **'Draw on the wall and in drawing notes in orange, purple, pink, teal and yellow, or mix an ink of your own.'**
  String get proMarkersBody;

  /// No description provided for @proPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private boards'**
  String get proPrivateTitle;

  /// No description provided for @proPrivateLine.
  ///
  /// In en, this message translates to:
  /// **'Opened with your fingerprint or screen lock'**
  String get proPrivateLine;

  /// No description provided for @proPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Lock a board with your phone\'s own fingerprint, face or screen lock. It shuts whenever you leave the app; while shut, its notes stay out of search and the widget, and its reminders hide their words.'**
  String get proPrivateBody;

  /// No description provided for @proPlayIt.
  ///
  /// In en, this message translates to:
  /// **'{name}. Play it above'**
  String proPlayIt(String name);

  /// No description provided for @proReplay.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get proReplay;

  /// No description provided for @proCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Free and Pro'**
  String get proCompareTitle;

  /// No description provided for @proFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get proFree;

  /// No description provided for @proPlus.
  ///
  /// In en, this message translates to:
  /// **'+ {count}'**
  String proPlus(int count);

  /// No description provided for @proPlusMix.
  ///
  /// In en, this message translates to:
  /// **'+ {count}, and any color you mix'**
  String proPlusMix(int count);

  /// No description provided for @proAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String proAll(int count);

  /// No description provided for @proNoLimits.
  ///
  /// In en, this message translates to:
  /// **'No limits'**
  String get proNoLimits;

  /// No description provided for @proRowNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes, boards, reminders'**
  String get proRowNotes;

  /// No description provided for @proRowTemplates.
  ///
  /// In en, this message translates to:
  /// **'Board templates'**
  String get proRowTemplates;

  /// No description provided for @proRowWalls.
  ///
  /// In en, this message translates to:
  /// **'Walls'**
  String get proRowWalls;

  /// No description provided for @proFreeWalls.
  ///
  /// In en, this message translates to:
  /// **'{count}, and your own photo'**
  String proFreeWalls(int count);

  /// No description provided for @proProWalls.
  ///
  /// In en, this message translates to:
  /// **'+ {count}, and {seasonal} for the holidays'**
  String proProWalls(int count, int seasonal);

  /// No description provided for @proRowPacks.
  ///
  /// In en, this message translates to:
  /// **'Theme packs'**
  String get proRowPacks;

  /// No description provided for @proRowFonts.
  ///
  /// In en, this message translates to:
  /// **'Handwriting fonts'**
  String get proRowFonts;

  /// No description provided for @proRowPapers.
  ///
  /// In en, this message translates to:
  /// **'Paper colors'**
  String get proRowPapers;

  /// No description provided for @proRowPaperStyles.
  ///
  /// In en, this message translates to:
  /// **'Paper styles'**
  String get proRowPaperStyles;

  /// No description provided for @proRowPins.
  ///
  /// In en, this message translates to:
  /// **'Pins'**
  String get proRowPins;

  /// No description provided for @proRowStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get proRowStickers;

  /// No description provided for @proRowFrames.
  ///
  /// In en, this message translates to:
  /// **'Photo frames'**
  String get proRowFrames;

  /// No description provided for @proRowThreads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get proRowThreads;

  /// No description provided for @proFreeThreads.
  ///
  /// In en, this message translates to:
  /// **'Yarn in {count} colors'**
  String proFreeThreads(int count);

  /// No description provided for @proProThreads.
  ///
  /// In en, this message translates to:
  /// **'+ {styles} styles, {colors} colors'**
  String proProThreads(int styles, int colors);

  /// No description provided for @proRowMarkers.
  ///
  /// In en, this message translates to:
  /// **'Marker on the wall'**
  String get proRowMarkers;

  /// No description provided for @proFreeMarkers.
  ///
  /// In en, this message translates to:
  /// **'{count} colors and a highlighter'**
  String proFreeMarkers(int count);

  /// No description provided for @proRowLock.
  ///
  /// In en, this message translates to:
  /// **'Locking'**
  String get proRowLock;

  /// No description provided for @proAlwaysFree.
  ///
  /// In en, this message translates to:
  /// **'Always free: every kind of note, as many boards as you like, all the templates, reminders, the home-screen widget, search, backups, sync across devices and lights off. If you ever lose Pro, your notes keep every Pro look they already have.'**
  String get proAlwaysFree;

  /// No description provided for @noteLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Links in this note'**
  String get noteLinksTitle;

  /// No description provided for @linkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get linkRemove;

  /// No description provided for @linkRestore.
  ///
  /// In en, this message translates to:
  /// **'Make it a link'**
  String get linkRestore;

  /// No description provided for @linkPlain.
  ///
  /// In en, this message translates to:
  /// **'{url}, shown as plain words'**
  String linkPlain(String url);
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
