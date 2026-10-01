// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonShare => 'Share';

  @override
  String get commonGotIt => 'Got it';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsSubtitle(String version) {
    return 'Inklus $version · your notes are stored on this device';
  }

  @override
  String get settingsSectionDrive => 'Google Drive';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionFiles => 'Backups and files';

  @override
  String get settingsSectionTools => 'Tools';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsImportTitle => 'Import .inklus or backup';

  @override
  String get settingsImportSubtitle =>
      'A notebook (.inklus) or a full backup (.zip); detected automatically';

  @override
  String get settingsExportTitle => 'Export full backup';

  @override
  String get settingsExportSubtitle =>
      'All notebooks, images and trash in one .zip';

  @override
  String get settingsAutosaveTitle => 'Autosave';

  @override
  String get settingsAutosaveSubtitle =>
      'Every change is saved instantly on this device. A version is kept each time you open and close a note (⋮ menu → Version history).';

  @override
  String get settingsStatsTitle => 'Writing statistics';

  @override
  String get settingsStatsSubtitle => 'Strokes, pages, streaks and activity';

  @override
  String get settingsRemindersTitle => 'Reminders';

  @override
  String get settingsRemindersSubtitle => 'Alerts linked to your notebooks';

  @override
  String get settingsTrashTitle => 'Trash';

  @override
  String get settingsTrashSubtitle => 'Recover deleted notebooks and notes';

  @override
  String get settingsAppTagline => 'Handwriting for stylus tablets';

  @override
  String get settingsFreeTitle => 'Free and open';

  @override
  String get settingsFreeSubtitle =>
      'Open source (GPL-3.0). No paid features, no ads and no analytics.';

  @override
  String get settingsPrivacyTitle => 'Privacy policy';

  @override
  String get settingsPrivacySubtitle =>
      'What data the app handles and where it goes';

  @override
  String get settingsSourceTitle => 'Source code';

  @override
  String get settingsSourceSubtitle =>
      'Report a bug or suggest improvements on GitHub';

  @override
  String get settingsErrorLogTitle => 'Error log';

  @override
  String get settingsErrorLogSubtitle =>
      'Stored only on this device; you can share it to help fix a bug';

  @override
  String get settingsErrorLogEmpty => 'No errors recorded';

  @override
  String settingsErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors recorded',
      one: '1 error recorded',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorLogShareSubtitle => 'By email or in a GitHub issue';

  @override
  String get settingsErrorLogClear => 'Clear log';

  @override
  String get settingsErrorLogCleared => 'Log cleared';

  @override
  String settingsErrorLogSubject(String version) {
    return 'Inklus $version error log';
  }

  @override
  String settingsOpenFailed(String url) {
    return 'Could not open $url';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get driveConnected => 'Connected';

  @override
  String get driveCloudCopy => 'Cloud backup';

  @override
  String get driveGoogleAccount => 'Google account';

  @override
  String get driveOptionalPitch =>
      'Optional: keep a copy of your notes in your Google Drive';

  @override
  String get driveConnect => 'Connect';

  @override
  String get driveUploadNow => 'Upload now';

  @override
  String get driveUploadNowSubtitle =>
      'Uploads the notes of notebooks with sync enabled';

  @override
  String get driveRestore => 'Restore from Drive';

  @override
  String get driveRestoreSubtitle =>
      'Brings the newest versions and recovers notes missing on this device';

  @override
  String get driveNoteVersions => 'Versions of a note';

  @override
  String get driveNoteVersionsSubtitle => 'In the editor: ⋮ → Version history';

  @override
  String get driveSwitchAccount => 'Switch account';

  @override
  String get driveSignOut => 'Sign out';

  @override
  String get driveAccount => 'Account';

  @override
  String driveConnectedAs(String email) {
    return 'Connected as $email';
  }

  @override
  String get driveNotConfigured => 'Google is not configured';

  @override
  String get driveSignOutQuestion => 'Sign out?';

  @override
  String get driveSignOutBody =>
      'Backups will stop being uploaded to Google Drive. Copies already in Drive are kept.';

  @override
  String get driveSignedOut => 'Signed out';

  @override
  String driveUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes uploaded to Drive',
      one: '1 note uploaded to Drive',
      zero: 'No notebooks have sync enabled',
    );
    return '$_temp0';
  }

  @override
  String get driveRestoreBody =>
      'Notes on this device are only replaced if the Drive copy is newer. Notes missing here go back to their notebook (or to a new \"Recovered from Drive\" one).';

  @override
  String get backupSaveTitle => 'Save Inklus backup';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get driveSignInIncomplete => 'Sign-in did not complete';

  @override
  String get driveDetails => 'Details';

  @override
  String get driveSignInHelpTitle => 'Could not sign in';

  @override
  String driveSignInHelpBody(String details) {
    return 'If you just closed the account picker, nothing is wrong. If you chose an account and it did not connect, the app\'s signing key (SHA-1) is almost always not registered in Google Cloud for com.inklus.inklus.\n\nTechnical detail:\n$details';
  }

  @override
  String get driveNotebooksTitle => 'Notebooks that sync';

  @override
  String get driveNotebooksSubtitle =>
      'Each notebook is saved in Drive → Inklus → its own folder. Choose which ones.';

  @override
  String get driveNotebooksEmpty => 'No notebooks yet.';

  @override
  String get driveSyncMenu => 'Sync with Drive';

  @override
  String get driveSyncEnabled => 'Sync enabled';

  @override
  String get driveSyncDisabled => 'Sync disabled';

  @override
  String get textEditHint => 'Type here…';

  @override
  String get textEditMove => 'Move box';

  @override
  String get textEditWidth => 'Box width';

  @override
  String get textEditSmaller => 'Smaller';

  @override
  String get textEditLarger => 'Larger';

  @override
  String get textEditBold => 'Bold';

  @override
  String get textEditItalic => 'Italic';

  @override
  String get textEditUnderline => 'Underline';

  @override
  String get textEditStrike => 'Strikethrough';

  @override
  String get textEditColor => 'Text color';

  @override
  String get textEditHighlight => 'Highlight';

  @override
  String get textEditAlign => 'Alignment';

  @override
  String get textEditSpacing => 'Line spacing';

  @override
  String get textEditLinkActive => 'Page link (active)';

  @override
  String get textEditLink => 'Link to page';

  @override
  String get textEditDelete => 'Delete box';

  @override
  String get textEditDone => 'Done';

  @override
  String get textEditWholeBox => 'Whole box';

  @override
  String get textEditNoHighlight => 'No highlight';

  @override
  String get textEditUnlink => 'Remove link';

  @override
  String commonPageN(int n) {
    return 'Page $n';
  }

  @override
  String get marketWhereTemplate => 'in the page\'s Template menu';

  @override
  String get marketWherePalette => 'in each pen\'s colors';

  @override
  String get marketWhereStickers => 'in More tools → Insert sticker';

  @override
  String get marketHeroTitle => 'Discover and customize';

  @override
  String get marketHeroSubtitle =>
      'Community templates, palettes and stickers. Free and openly licensed.';

  @override
  String get marketSearch => 'Search packs';

  @override
  String get marketTitle => 'Marketplace';

  @override
  String get marketOfflineCache =>
      'Offline: showing the last downloaded catalog';

  @override
  String get marketOfflineBundled =>
      'Offline: showing packs bundled with the app';

  @override
  String get marketAll => 'All';

  @override
  String get marketTemplates => 'Templates';

  @override
  String get marketPalettes => 'Palettes';

  @override
  String get marketStickers => 'Stickers';

  @override
  String get marketPalette => 'Palette';

  @override
  String get marketNoResults => 'No matching packs';

  @override
  String get marketRemove => 'Remove';

  @override
  String get marketInstall => 'Install';

  @override
  String marketUninstalled(String name) {
    return '“$name” uninstalled';
  }

  @override
  String marketInstalled(String name, String where) {
    return '“$name” installed: $where';
  }

  @override
  String marketInstallFailed(String name, String error) {
    return 'Could not install “$name”: $error';
  }

  @override
  String get createTplBlank => 'Blank';

  @override
  String get createTplRuled => 'Ruled';

  @override
  String get createTplGrid => 'Grid';

  @override
  String get createTplDots => 'Dots';

  @override
  String get createTplMusic => 'Staff';

  @override
  String get createTplPlanner => 'Planner';

  @override
  String get createTplHabit => 'Habits';

  @override
  String get createTplSheet => 'A4 sheet';

  @override
  String get createTitle => 'New notebook';

  @override
  String get createName => 'Name';

  @override
  String get createNameHint => 'My notebook';

  @override
  String get createCover => 'Cover';

  @override
  String get createDesign => 'Design';

  @override
  String get createYourImage => 'Your image';

  @override
  String get createChangeImage => 'Change image';

  @override
  String get createColor => 'Color';

  @override
  String get createNext => 'Next';

  @override
  String get createStep2 => 'Step 2: choose a template';

  @override
  String get createBackToStep1 => 'Back to step 1';

  @override
  String get createTemplate => 'Template';

  @override
  String get createMoreTemplates => 'Show more templates';

  @override
  String get createFewer => 'Show fewer';

  @override
  String get createInfinite => 'Infinite canvas';

  @override
  String get createInfiniteOn => 'The canvas grows as you write';

  @override
  String get createInfiniteOff => 'Fixed-size sheet (A4)';

  @override
  String get createAction => 'Create notebook';

  @override
  String createDefaultName(int n) {
    return 'Notebook $n';
  }

  @override
  String createCoverSemantics(String name) {
    return 'Cover $name';
  }

  @override
  String get libRenameTitle => 'Rename notebook';

  @override
  String get libDeleteTitle => 'Delete notebook';

  @override
  String get libDelete => 'Delete';

  @override
  String get libCoverColor => 'Cover color';

  @override
  String get commonSave => 'Save';

  @override
  String get libSortTitle => 'Sort notebooks';

  @override
  String get libSortNewestFirst => 'Newest first';

  @override
  String get libSortOldestFirst => 'Oldest first';

  @override
  String get libSortTitleAZ => 'Title A → Z';

  @override
  String get libSortTitleZA => 'Title Z → A';

  @override
  String get libNavAll => 'All';

  @override
  String get libNavRecent => 'Recent';

  @override
  String get libNavFavorites => 'Favorites';

  @override
  String get libNavFolders => 'Folders';

  @override
  String get libImport => 'Import .inklus';

  @override
  String get libTrash => 'Trash';

  @override
  String get libLightMode => 'Light mode';

  @override
  String get libDarkMode => 'Dark mode';

  @override
  String get libMoreOptions => 'More options';

  @override
  String get libMyNotebooks => 'My notebooks';

  @override
  String get libClearFilter => 'Clear filter';

  @override
  String get libSearchHint => 'Search by name or tag';

  @override
  String get libSearchInNotes => 'Search inside notes (text and handwriting)';

  @override
  String get libSearchContent => 'In content';

  @override
  String get libSortNewest => 'Newest';

  @override
  String get libSortOldest => 'Oldest';

  @override
  String get libSortNameAZ => 'Name A–Z';

  @override
  String get libSortNameZA => 'Name Z–A';

  @override
  String get libGrid => 'Grid';

  @override
  String get libList => 'List';

  @override
  String get libNoResults => 'No notebooks found';

  @override
  String get libEmptyTitle => 'Start writing';

  @override
  String get libNoResultsHint => 'Try another name or tag.';

  @override
  String get libUnfavorite => 'Remove from favorites';

  @override
  String get libFavorite => 'Add to favorites';

  @override
  String get libRename => 'Rename';

  @override
  String get libDuplicate => 'Duplicate';

  @override
  String get libCoverAndColor => 'Cover and color';

  @override
  String get libTags => 'Tags';

  @override
  String get libSyncOff => 'Stop syncing with Drive';

  @override
  String get libMoveToTrash => 'Move to trash';

  @override
  String get libNotebookOptions => 'Notebook options';

  @override
  String libSyncWillSync(String title) {
    return '“$title” will sync with Drive';
  }

  @override
  String libSyncStopped(String title) {
    return '“$title” no longer syncs';
  }

  @override
  String libDeleteBody(String title) {
    return '\"$title\" will be moved to the trash. You can restore it from there.';
  }

  @override
  String libImportError(String error) {
    return 'Import error: $error';
  }

  @override
  String libCountAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total notebooks',
      one: '1 notebook',
    );
    return '$_temp0';
  }

  @override
  String libCountOf(int shown, int total) {
    return '$shown of $total notebooks';
  }

  @override
  String libNotebookSemantics(String title, String when) {
    return 'Notebook $title, $when';
  }

  @override
  String get libEmptyHint =>
      'Create a new notebook or import an existing one\\nto get started.';

  @override
  String get noteRenameTitle => 'Rename note';

  @override
  String get noteDeleteTitle => 'Delete note';

  @override
  String get noteNew => 'New note';

  @override
  String get noteNameHint => 'My note';

  @override
  String get noteCreate => 'Create';

  @override
  String get noteEmptyTitle => 'No notes';

  @override
  String get noteEmptyHint => 'Create your first note to start writing.';

  @override
  String get noteCreateAction => 'Create note';

  @override
  String get noteOptions => 'Options';

  @override
  String get timeNow => 'just now';

  @override
  String get noteTplInfinite => 'Infinite';

  @override
  String get noteTplSheet => 'Fixed sheet';

  @override
  String get noteTplPlanner => 'Planner';

  @override
  String get tplInfiniteHint => 'Infinite ones grow as you write';

  @override
  String get tplNormalSheet => 'Regular sheet';

  @override
  String get tplOwn => 'Your own template';

  @override
  String get tplFromMarket => 'From the marketplace';

  @override
  String get tplMine => 'My templates';

  @override
  String get tplSaveCurrent => 'Save current';

  @override
  String get tplCustomize => 'Customize';

  @override
  String get tplLineColor => 'Line color';

  @override
  String get tplSpacing => 'Spacing';

  @override
  String get tplFixedSheet => 'Fixed-size sheet';

  @override
  String get tplSheetSize => 'Sheet size';

  @override
  String get tplLetter => 'Letter';

  @override
  String get tplHowTitle => 'How should the template be used?';

  @override
  String get tplHowBody =>
      'The image will be used as a background to write on.';

  @override
  String get tplAsSheet => 'As a fixed sheet';

  @override
  String get tplAsFill => 'Infinite fill';

  @override
  String get tplOnlyImage => 'Only templates with an image can be saved';

  @override
  String get tplSaveTitle => 'Save template';

  @override
  String get tplDefaultName => 'My template';

  @override
  String get tplSaved => 'Template saved';

  @override
  String get tplDeleteTitle => 'Delete template';

  @override
  String get tplDeleteBody => 'Delete this saved template?';

  @override
  String get colorCustomTitle => 'Custom color';

  @override
  String get colorCurrent => 'Current';

  @override
  String get colorNew => 'New';

  @override
  String get colorWheel => 'Wheel';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Brightness';

  @override
  String get colorUse => 'Use';

  @override
  String timeMinAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get timeDeletedNow => 'deleted just now';

  @override
  String timeDeletedMin(int n) {
    return 'deleted $n min ago';
  }

  @override
  String timeDeletedHours(int n) {
    return 'deleted $n h ago';
  }

  @override
  String timeDeletedDays(int n) {
    return 'deleted $n days ago';
  }

  @override
  String timeDeletedOn(String date) {
    return 'deleted $date';
  }

  @override
  String noteDeleteBody(String title) {
    return '\"$title\" will be removed from this notebook.';
  }

  @override
  String noteDefaultName(int n) {
    return 'Note $n';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String notePageCount(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0 · $when';
  }

  @override
  String tplImageLoadFailed(String error) {
    return 'Could not load the image: $error';
  }

  @override
  String tplSaveFailed(String error) {
    return 'Save error: $error';
  }

  @override
  String get colorSliders => 'Sliders';

  @override
  String get selPaste => 'Paste';

  @override
  String get selCopy => 'Copy';

  @override
  String get selCopied => 'Copied';

  @override
  String get selThinner => 'Thinner';

  @override
  String get selThicker => 'Thicker';

  @override
  String get selToText => 'Convert to text';

  @override
  String get selDeselect => 'Deselect';

  @override
  String get selNoText => 'No text recognized in the selection';

  @override
  String get selConvert => 'Convert';

  @override
  String get popPenType => 'Pen type';

  @override
  String get popThickness => 'Thickness';

  @override
  String get popStraighten => 'Straighten shapes';

  @override
  String get popNo => 'No';

  @override
  String get popOnHold => 'On hold';

  @override
  String get popAlways => 'Always';

  @override
  String get popShapeOffHint => 'Strokes stay as drawn.';

  @override
  String get popShapeHoldHint =>
      'Hold the pen still for half a second after finishing a line, circle, triangle or rectangle.';

  @override
  String get popShapeAlwaysHint =>
      'Every recognizable shape is straightened when you lift the pen.';

  @override
  String get popAdvanced => 'Advanced stroke settings';

  @override
  String get popMode => 'Mode';

  @override
  String get popPartial => 'Partial';

  @override
  String get popStroke => 'Stroke';

  @override
  String get popHighlighter => 'Highlighter';

  @override
  String get popEraseOff => 'Erases only what you touch, like a rubber.';

  @override
  String get popEraseStroke => 'Erases the whole stroke when touched.';

  @override
  String get popEraseHighlighter =>
      'Only erases highlighter; ink is untouched.';

  @override
  String get popSize => 'Size';

  @override
  String get tbBackToLibrary => 'Back to library';

  @override
  String get tbHidePages => 'Hide pages';

  @override
  String get tbPages => 'Pages';

  @override
  String get tbHideLayers => 'Hide layers';

  @override
  String get tbLayers => 'Layers';

  @override
  String get tbInsertImage => 'Insert image';

  @override
  String get tbRuler => 'Ruler';

  @override
  String get tbRulerNext => 'Ruler (tap: protractor)';

  @override
  String get tbProtractorNext => 'Protractor (tap: hide)';

  @override
  String get tbMoveSelect => 'Move / select images and strokes';

  @override
  String get tbFill => 'Fill area';

  @override
  String get tbHideMagnifier => 'Hide magnifier';

  @override
  String get tbMagnifier => 'Magnifier';

  @override
  String get tbLaserOff => 'Turn off laser pointer';

  @override
  String get tbLaser => 'Laser pointer';

  @override
  String get tbInsertSticker => 'Insert sticker';

  @override
  String get tbPageTemplate => 'Page template';

  @override
  String get tbMoreTools => 'More tools';

  @override
  String get tbUndo => 'Undo';

  @override
  String get tbRedo => 'Redo';

  @override
  String get pgUnbookmark => 'Remove bookmark';

  @override
  String get pgBookmark => 'Bookmark page';

  @override
  String get pgShowAll => 'Show all';

  @override
  String get pgOnlyBookmarked => 'Bookmarked only';

  @override
  String get commonClose => 'Close';

  @override
  String get pgOptions => 'Page options';

  @override
  String get pgNew => 'New page';

  @override
  String get tagTitle => 'Notebook tags';

  @override
  String get tagSubtitle => 'To find it and group it in smart folders';

  @override
  String get tagActive => 'Active tags';

  @override
  String get tagOthers => 'Other tags';

  @override
  String get tagNew => 'New tag…';

  @override
  String get tagAdd => 'Add tag';

  @override
  String get tagSave => 'Save tags';

  @override
  String get trashDeleteForever => 'Delete permanently';

  @override
  String get trashEmptyTitle => 'Empty trash';

  @override
  String get trashEmpty => 'Empty';

  @override
  String get trashSubtitleEmpty => 'Anything you delete stays here for 30 days';

  @override
  String get trashEmptyState => 'Trash is empty';

  @override
  String get trashLegacy => 'Notebook (old format)';

  @override
  String get trashNote => 'Note';

  @override
  String get trashReturn => 'Return to its notebook';

  @override
  String get strokeSubtitle => 'Pressure, smoothing and stroke fluidity';

  @override
  String get strokeNone => 'The eraser and selection have no stroke options.';

  @override
  String get strokeQuickSize => 'Quick size';

  @override
  String get strokePressure => 'Pressure variation';

  @override
  String get strokePressureDesc => 'How much thickness changes when you press';

  @override
  String get strokeSmoothing => 'Smoothing';

  @override
  String get strokeSmoothingDesc => 'Rounds the stroke\'s curves';

  @override
  String get strokeStabilizer => 'Stabilizer';

  @override
  String get strokeStabilizerDesc => 'Reduces hand tremor';

  @override
  String get sizeThin => 'Thin';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeThick => 'Thick';

  @override
  String get sizeExtra => 'Extra';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeLarge => 'Large';

  @override
  String get toolPen => 'Ballpoint pen';

  @override
  String get toolPencil => 'Pencil';

  @override
  String get toolCalligraphy => 'Calligraphy pen';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolMarker => 'Marker';

  @override
  String get toolSpray => 'Spray';

  @override
  String get toolEraser => 'Eraser';

  @override
  String get toolSelect => 'Move / select';

  @override
  String get toolLasso => 'Lasso';

  @override
  String get toolFill => 'Fill';

  @override
  String get toolText => 'Text';

  @override
  String selRecognizeFailed(String error) {
    return 'Could not recognize: $error';
  }

  @override
  String tbPenSlot(String tool, int n) {
    return '$tool $n';
  }

  @override
  String tbPageOf(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String pgPagesCount(int n) {
    return 'Pages ($n)';
  }

  @override
  String strokeOptionsOf(String tool) {
    return '$tool options';
  }

  @override
  String trashRestoredMsg(String title) {
    return '\"$title\" restored';
  }

  @override
  String trashPurgeBody(String title) {
    return '\"$title\" will be permanently deleted. This cannot be undone.';
  }

  @override
  String trashEmptyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 will be permanently deleted. This cannot be undone.';
  }

  @override
  String trashSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · deleted automatically after 30 days';
  }

  @override
  String get trashEmptyStateBody =>
      'Notebooks and notes you delete are kept here for 30 days before being permanently removed.';

  @override
  String trashNotebookKind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Notebook · $_temp0';
  }

  @override
  String trashNoteOf(String title) {
    return 'Note from “$title”';
  }

  @override
  String get trashLeftTomorrow => 'deleted tomorrow';

  @override
  String trashLeftDays(int n) {
    return '$n days left';
  }

  @override
  String trashInfoLine(String what, String deleted, String left) {
    return '$what · $deleted · $left';
  }

  @override
  String get edLayerLocked => 'Layer locked — unlock it to edit';

  @override
  String get expTitle => 'Export options';

  @override
  String get expLow => 'Low (1024 px)';

  @override
  String get expMedium => 'Medium (2048 px)';

  @override
  String get expHigh => 'High (4096 px)';

  @override
  String get expMax => 'Maximum (8192 px)';

  @override
  String get expTransparent => 'Transparent background';

  @override
  String get expTransparentHint => 'No template or paper';

  @override
  String get expStrokesOnly => 'Strokes only';

  @override
  String get expStrokesOnlyHint => 'No images or template';

  @override
  String get expExport => 'Export';

  @override
  String get ocrUnsupported => 'OCR is only available on Android and iOS';

  @override
  String get ocrWorking => 'Recognizing text…';

  @override
  String get ocrNoText => 'No text recognized on this page';

  @override
  String get ocrResultTitle => 'Recognized text';

  @override
  String get ocrCopied => 'Text copied to the clipboard';

  @override
  String get edGoogleAccount => 'Google account';

  @override
  String get edSyncedCloud => 'Synced with the cloud';

  @override
  String get edRestoreCloud => 'Restore from the cloud';

  @override
  String get edRestoreCloudHint => 'Latest version (last-write-wins)';

  @override
  String get edDriveVersions => 'View versions in Drive';

  @override
  String get edUploadInklus => 'Upload .inklus file';

  @override
  String get edSyncOnForNotebook => 'Sync: on for this notebook';

  @override
  String get edSyncOffForNotebook => 'Sync: off for this notebook';

  @override
  String get edSyncDisabledMsg => 'Sync turned off for this notebook';

  @override
  String get edSyncEnabledMsg => 'Sync turned on for this notebook';

  @override
  String get edNoteSynced => 'Note synced with Google Drive';

  @override
  String get edPasswordHint => 'Password (leave empty if not encrypted)';

  @override
  String get edNoCloudCopy =>
      'There is no copy of this note in Google Drive yet';

  @override
  String get edNoteRestored => 'Note restored from Google Drive';

  @override
  String get edIsFullBackup =>
      'That file is a full backup, not a .inklus notebook';

  @override
  String get edNoPassword => 'No password';

  @override
  String get edNotebookTitle => 'Notebook title';

  @override
  String get pdfUnsupported =>
      'Importing PDFs is only available on Android/iOS for now';

  @override
  String get pdfReadFailed => 'Could not read the PDF';

  @override
  String get verRestoreTitle => 'Restore version';

  @override
  String get verRestored => 'Version restored';

  @override
  String get verEncrypted => 'Encrypted copy';

  @override
  String get verPasswordHint => 'Copy password';

  @override
  String get verDecrypt => 'Decrypt';

  @override
  String get inkUnsupported =>
      'Handwriting recognition is only available on Android and iOS';

  @override
  String get edDeleteImage => 'Delete image';

  @override
  String get edExitPresent => 'Exit presentation';

  @override
  String get edLaserOff => 'Turn off laser';

  @override
  String get edGoToPage => 'Go to page';

  @override
  String get edGo => 'Go';

  @override
  String get edNoStickers => 'You have no stickers installed yet.';

  @override
  String get edOpenMarket => 'Open the marketplace';

  @override
  String get edSyncing => 'Syncing…';

  @override
  String get edSyncToDrive => 'Sync with Google Drive';

  @override
  String get edSynced => 'Synced';

  @override
  String get edSyncError => 'Sync error';

  @override
  String get menuPagePng => 'Page as image (PNG)';

  @override
  String get menuPagePdf => 'Page as PDF';

  @override
  String get menuNotePdf => 'Whole note (PDF)';

  @override
  String get menuStrokesSvg => 'Strokes (SVG)';

  @override
  String get menuPptx => 'Presentation (PowerPoint)';

  @override
  String get menuInklusCopy => 'Copy as .inklus';

  @override
  String get menuShareImage => 'Share image';

  @override
  String get menuSharePdf => 'Share PDF';

  @override
  String get menuShareInklus => 'Share .inklus';

  @override
  String get menuExportShare => 'Export and share';

  @override
  String get menuTemplate => 'Template…';

  @override
  String get menuGoToPage => 'Go to page…';

  @override
  String get menuImportPdf => 'Import PDF to annotate';

  @override
  String get menuClearPage => 'Clear page';

  @override
  String get menuPage => 'Page';

  @override
  String get menuSearchNote => 'Search in note';

  @override
  String get menuIndexInk => 'Index handwriting (to search it)';

  @override
  String get menuIndexInkUnsupported => 'Index handwriting (Android/iOS only)';

  @override
  String get menuOcr => 'Recognize text (OCR)';

  @override
  String get menuOcrUnsupported => 'OCR (Android/iOS only)';

  @override
  String get menuVersions => 'Version history';

  @override
  String get menuReminder => 'Create reminder';

  @override
  String get menuNightOff => 'Turn off night mode';

  @override
  String get menuNightOn => 'Writing night mode';

  @override
  String get menuPresent => 'Presentation mode';

  @override
  String get menuHapticsOn => 'Writing vibration: on';

  @override
  String get menuHapticsOff => 'Writing vibration: off';

  @override
  String get menuContinuousScroll => 'Continuous scroll between sheets';

  @override
  String get menuView => 'View';

  @override
  String get menuBackup => 'Export full backup';

  @override
  String get menuRestoreBackup => 'Import .inklus or backup';

  @override
  String get menuData => 'Data';

  @override
  String get menuStats => 'Writing statistics';

  @override
  String get clearPageBody =>
      'All the page\'s content will be erased. You can undo it afterwards.';

  @override
  String get clearPageAction => 'Clear';

  @override
  String get pgPrev => 'Previous page';

  @override
  String get pgNext => 'Next page';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomFit => 'Fit to view';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get shareTextPage => 'Inklus page';

  @override
  String get shareTextNotebook => 'Inklus notebook';

  @override
  String edInsertImageFailed(String error) {
    return 'Could not insert the image: $error';
  }

  @override
  String expSvgFailed(String error) {
    return 'SVG export error: $error';
  }

  @override
  String ocrFailed(String error) {
    return 'Text recognition error: $error';
  }

  @override
  String expFailed(String error) {
    return 'Export error: $error';
  }

  @override
  String expPreview(String name) {
    return 'Preview: $name';
  }

  @override
  String expSaveDialog(String name) {
    return 'Save $name';
  }

  @override
  String expDone(String path) {
    return 'Exported: $path';
  }

  @override
  String expSaveFailed(String error) {
    return 'Could not save the file: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Share error: $error';
  }

  @override
  String edSignInIncomplete(String detail) {
    return 'Sign-in did not complete. Detail: $detail';
  }

  @override
  String uploadFailed(String error) {
    return 'Upload error: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore error: $error';
  }

  @override
  String edFileUploaded(String name) {
    return 'File \"$name\" uploaded to Google Drive';
  }

  @override
  String pdfImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'PDF imported: $_temp0 to annotate';
  }

  @override
  String pdfImportFailed(String error) {
    return 'PDF import error: $error';
  }

  @override
  String verRestoreBody(String date) {
    return 'The note will go back to how it was on $date.\\n\\nThe current state is saved first as a local version, so you can undo the restore from this same history.';
  }

  @override
  String verRestoreFailed(String error) {
    return 'Could not restore the version: $error';
  }

  @override
  String pptxFailed(String error) {
    return 'PowerPoint export error: $error';
  }

  @override
  String reminderCreated(String date, String time) {
    return 'Reminder created for $date at $time';
  }

  @override
  String inkIndexed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'Handwriting indexed on $_temp0: you can now search it';
  }

  @override
  String inkFailed(String error) {
    return 'Could not recognize the handwriting: $error';
  }

  @override
  String backupFailed(String error) {
    return 'Backup export error: $error';
  }

  @override
  String importDoneOpen(String message) {
    return '$message. Open it from the library.';
  }

  @override
  String noteHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'The note has $_temp0';
  }

  @override
  String stickerInsertFailed(String error) {
    return 'Could not insert the sticker: $error';
  }

  @override
  String get remNoNotebooks => 'No notebooks to link';

  @override
  String get remPickNotebook => 'Select notebook';

  @override
  String get remPickHint => 'The reminder will open this notebook';

  @override
  String get remCreated => 'Reminder created';

  @override
  String get remMessageTitle => 'Reminder message';

  @override
  String get remMessageHint => 'E.g. Review class notes';

  @override
  String get remNoMessage => 'No message';

  @override
  String get remTitle => 'Reminders';

  @override
  String get remSubtitle => 'Alerts linked to your notebooks';

  @override
  String get remEmptyTitle => 'No reminders';

  @override
  String get remPending => 'Pending';

  @override
  String get remDone => 'Completed';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsSubtitle => 'Your writing activity on this device';

  @override
  String get statsEmptyTitle => 'No data yet';

  @override
  String get statsStrokes => 'Strokes';

  @override
  String get statsMinutes => 'Minutes';

  @override
  String get statsActiveDays => 'Active days';

  @override
  String get statsStreaks => 'Streaks';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsRecord => 'Record';

  @override
  String get statsActivity => 'Activity — last 30 days';

  @override
  String get statsDaysWithPages => 'Days with new pages';

  @override
  String get smartTitle => 'Smart folders';

  @override
  String get smartSubtitle => 'Organize your notebooks automatically';

  @override
  String get smartByColor => 'By color';

  @override
  String get smartByTag => 'By tag';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbStart => 'Get started';

  @override
  String get onb1Title => 'Write with your pen';

  @override
  String get onb2Title => 'Move with your fingers';

  @override
  String get onb3Title => 'Tools on top';

  @override
  String get onb4Title => 'Your notes are yours';

  @override
  String get layerAdd => 'Add layer';

  @override
  String get layerRename => 'Rename layer';

  @override
  String get verSubtitle => 'When restoring, the current state is saved first';

  @override
  String get verOnDevice => 'On this device';

  @override
  String get verNoLocal => 'There are no local copies of this note yet.';

  @override
  String get verOnDrive => 'On Google Drive';

  @override
  String get verNotUploaded => 'This note has not been uploaded to Drive yet.';

  @override
  String get smartThisWeek => 'This week';

  @override
  String get smartNoTags => 'No tags';

  @override
  String get smartOther => 'Other';

  @override
  String get colorNone => 'No color';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorTurquoise => 'Turquoise';

  @override
  String get colorGray => 'Gray';

  @override
  String get onb1Body =>
      'Rest your hand without worry: Inklus recognizes the pen and ignores your palm. The pen\'s eraser end or side button erases.';

  @override
  String get onb2Body =>
      'With the pen, one finger scrolls the page and two fingers zoom. You can go back to drawing with your finger from the toolbar.';

  @override
  String get onb3Body =>
      'Tap a tool to use it and tap it again to see its options: thickness, color, partial eraser, shapes…';

  @override
  String get onb4Body =>
      'Everything is saved on this device, with no accounts or ads. If you want, you can back up to your Google Drive.';

  @override
  String get remEmptyBody =>
      'Create reminders linked to your notebooks so you never forget anything.';

  @override
  String get statsEmptyBody =>
      'Start writing in your notebooks and your statistics will appear here.';

  @override
  String get remOverdue => ' · overdue';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsDayTooltip(String date, int strokes, int pages) {
    return '$date: $strokes strokes, $pages pages';
  }

  @override
  String get searchInNote => 'Search in this note';

  @override
  String get searchInAll => 'Search in all notes';

  @override
  String get searchPrompt => 'Type to search';

  @override
  String searchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get searchInfo =>
      'Includes text boxes and handwriting that has already been recognized (Note menu → Index handwriting).';

  @override
  String get searchTitleMatch => 'Title';

  @override
  String get pgDuplicate => 'Duplicate page';

  @override
  String get pgDelete => 'Delete page';

  @override
  String verDriveFailed(String error) {
    return 'Could not query Drive: $error';
  }

  @override
  String colorSemantics(String hex) {
    return 'Color #$hex';
  }

  @override
  String get errNotInklus =>
      'The file is not an .inklus notebook or an Inklus backup.';

  @override
  String get errNotInklusFile => 'Not a valid .inklus notebook';

  @override
  String get errNotInklusV2 => 'Not a valid .inklus v2 notebook';

  @override
  String get errCatalogTooLarge => 'Catalog is too large';

  @override
  String errCatalogVersion(String version) {
    return 'Unsupported catalog version: $version';
  }

  @override
  String get errOcrUnsupported => 'OCR is only available on Android and iOS.';

  @override
  String get errNotSignedIn => 'Sign in with Google first.';

  @override
  String get errEncrypted => 'The copy is encrypted: a password is required';

  @override
  String driveConfigBody(String details) {
    return 'Google configuration error (clientConfigurationError).\\n\\nLikely cause: this app\'s signing SHA-1 is not registered in Google Cloud Console for the package com.inklus.inklus.\\n\\nFix:\\n1. Go to Google Cloud Console → APIs & Services → Credentials\\n2. Create or edit the Android OAuth client ID with package com.inklus.inklus and your signing SHA-1\\n3. Enable Google Sign-In on the consent screen\\n\\nOriginal error: $details';
  }

  @override
  String get noticeStylus =>
      'Pen detected: your finger now scrolls the page (turn it on in the toolbar if you want to draw with your finger)';

  @override
  String get noticePageDeleted => 'Page deleted';

  @override
  String get noticeFileUploaded => 'File uploaded to Google Drive';

  @override
  String importBackupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notebooks',
      one: '1 notebook',
    );
    return 'Backup restored: $_temp0';
  }

  @override
  String importNotebookDone(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Notebook \"$title\" imported ($_temp0)';
  }

  @override
  String importNotebookSimple(String title) {
    return 'Notebook \"$title\" imported';
  }

  @override
  String get driveRestoreNone =>
      'There are no Inklus copies in your Google Drive';

  @override
  String get driveRestoreUpToDate =>
      'Everything is up to date: nothing to restore';

  @override
  String driveRestoreUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes updated',
      one: '1 note updated',
    );
    return '$_temp0';
  }

  @override
  String driveRestoreAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recovered',
      one: '1 recovered',
    );
    return '$_temp0';
  }

  @override
  String get driveRecovered => 'Recovered from Drive';

  @override
  String get packClassicName => 'Classic notebooks';

  @override
  String get packClassicDesc =>
      'Wide and narrow ruling, 5 mm grid, dots and staff.';

  @override
  String get packTechName => 'Technical paper';

  @override
  String get packTechDesc =>
      'Fine graph-paper grid and column planner, in soft tones.';

  @override
  String get packStudyName => 'Study palette';

  @override
  String get packStudyDesc =>
      'Blue and black ink, correction red, green and orange for emphasis.';

  @override
  String get packPastelName => 'Pastel palette';

  @override
  String get packPastelDesc => 'Soft tones for pretty notes and diagrams.';

  @override
  String get packEarthName => 'Earth palette';

  @override
  String get packEarthDesc =>
      'Ochres, olive and terracotta, with good contrast on paper.';

  @override
  String get coverSimple => 'Gradient';

  @override
  String get coverClassic => 'Classic';

  @override
  String get coverAurora => 'Aurora';

  @override
  String get coverWaves => 'Waves';

  @override
  String get coverGeometric => 'Geometric';

  @override
  String get coverSun => 'Sun';

  @override
  String get coverDots => 'Dots';

  @override
  String get coverLines => 'Lines';

  @override
  String get untitled => 'Untitled';

  @override
  String get defaultNotebookTitle => 'My notebook';

  @override
  String get createFromFile => 'Or start from a file';

  @override
  String get createFromFileHint =>
      'Upload a PDF or photos and write on top of each page.';

  @override
  String get createFromPdf => 'From a PDF';

  @override
  String get createFromImages => 'From images';

  @override
  String get createFromFileRemove => 'Remove file';

  @override
  String createFromFilePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }
}
