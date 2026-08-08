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
  /// **'Normal'**
  String get typeNormal;

  /// No description provided for @typeLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get typeLink;

  /// No description provided for @typeChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get typeChecklist;

  /// No description provided for @createNote.
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get createNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @contentHint.
  ///
  /// In en, this message translates to:
  /// **'Note something...'**
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

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequired;

  /// No description provided for @linkRequired.
  ///
  /// In en, this message translates to:
  /// **'Link is required'**
  String get linkRequired;

  /// No description provided for @duplicateExists.
  ///
  /// In en, this message translates to:
  /// **'This content or link already exists'**
  String get duplicateExists;

  /// No description provided for @addSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get addSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updateSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.\nTap “Add Note” to stick one on the wall!'**
  String get emptyState;

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
  /// **'Wall'**
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

  /// No description provided for @fontPreview.
  ///
  /// In en, this message translates to:
  /// **'Hello! A quick note on the wall.'**
  String get fontPreview;

  /// No description provided for @emote.
  ///
  /// In en, this message translates to:
  /// **'Emote'**
  String get emote;

  /// No description provided for @wallDecor.
  ///
  /// In en, this message translates to:
  /// **'Wall stains & marks'**
  String get wallDecor;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Paper color'**
  String get color;

  /// No description provided for @colorAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get colorAuto;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get pin;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @clearReminder.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearReminder;

  /// No description provided for @checklistItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get checklistItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @sortByCreated.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortByCreated;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @boards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boards;

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

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export notes'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import notes'**
  String get importData;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a backup here'**
  String get importHint;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that backup'**
  String get importFailed;

  /// No description provided for @importReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Importing replaces all current boards and notes.'**
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
