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
      'Notes on this device are only replaced if the Drive copy is newer. Notes missing here are saved in a new notebook \"Recovered from Drive\".';

  @override
  String get backupSaveTitle => 'Save Inklus backup';

  @override
  String get backupSaved => 'Backup saved';
}
