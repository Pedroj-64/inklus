// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRestore => 'Wiederherstellen';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonGotIt => 'Verstanden';

  @override
  String commonError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String settingsSubtitle(String version) {
    return 'Inklus $version · Deine Notizen liegen auf diesem Gerät';
  }

  @override
  String get settingsSectionDrive => 'Google Drive';

  @override
  String get settingsSectionAppearance => 'Darstellung';

  @override
  String get settingsSectionFiles => 'Backups und Dateien';

  @override
  String get settingsSectionTools => 'Werkzeuge';

  @override
  String get settingsSectionAbout => 'Info';

  @override
  String get settingsImportTitle => '.inklus oder Backup importieren';

  @override
  String get settingsImportSubtitle =>
      'Ein Notizbuch (.inklus) oder ein vollständiges Backup (.zip); wird automatisch erkannt';

  @override
  String get settingsExportTitle => 'Vollständiges Backup exportieren';

  @override
  String get settingsExportSubtitle =>
      'Alle Notizbücher, Bilder und der Papierkorb in einer .zip';

  @override
  String get settingsAutosaveTitle => 'Automatisches Speichern';

  @override
  String get settingsAutosaveSubtitle =>
      'Jede Änderung wird sofort auf diesem Gerät gespeichert. Beim Öffnen und Schließen einer Notiz wird eine Version aufbewahrt (Menü ⋮ → Versionsverlauf).';

  @override
  String get settingsStatsTitle => 'Schreibstatistik';

  @override
  String get settingsStatsSubtitle => 'Striche, Seiten, Serien und Aktivität';

  @override
  String get settingsRemindersTitle => 'Erinnerungen';

  @override
  String get settingsRemindersSubtitle => 'Hinweise zu deinen Notizbüchern';

  @override
  String get settingsTrashTitle => 'Papierkorb';

  @override
  String get settingsTrashSubtitle =>
      'Gelöschte Notizbücher und Notizen wiederherstellen';

  @override
  String get settingsAppTagline => 'Handschrift für Tablets mit Stift';

  @override
  String get settingsFreeTitle => 'Frei und offen';

  @override
  String get settingsFreeSubtitle =>
      'Open Source (GPL-3.0). Keine Bezahlfunktionen, keine Werbung, keine Analyse.';

  @override
  String get settingsPrivacyTitle => 'Datenschutzerklärung';

  @override
  String get settingsPrivacySubtitle =>
      'Welche Daten die App verarbeitet und wohin sie gehen';

  @override
  String get settingsSourceTitle => 'Quellcode';

  @override
  String get settingsSourceSubtitle =>
      'Melde einen Fehler oder schlage Verbesserungen auf GitHub vor';

  @override
  String get settingsErrorLogTitle => 'Fehlerprotokoll';

  @override
  String get settingsErrorLogSubtitle =>
      'Nur auf diesem Gerät gespeichert; du kannst es teilen, um bei der Fehlerbehebung zu helfen';

  @override
  String get settingsErrorLogEmpty => 'Keine Fehler aufgezeichnet';

  @override
  String settingsErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fehler aufgezeichnet',
      one: '1 Fehler aufgezeichnet',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorLogShareSubtitle =>
      'Per E-Mail oder in einem GitHub-Issue';

  @override
  String get settingsErrorLogClear => 'Protokoll löschen';

  @override
  String get settingsErrorLogCleared => 'Protokoll gelöscht';

  @override
  String settingsErrorLogSubject(String version) {
    return 'Inklus $version Fehlerprotokoll';
  }

  @override
  String settingsOpenFailed(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsLowPowerTitle => 'Sparmodus';

  @override
  String get settingsLowPowerSubtitle =>
      'Weniger Speicher auf einfachen Tablets und Handys: leichtere Bilder. Gilt beim Öffnen der nächsten Notiz.';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get driveConnected => 'Verbunden';

  @override
  String get driveCloudCopy => 'Cloud-Backup';

  @override
  String get driveGoogleAccount => 'Google-Konto';

  @override
  String get driveOptionalPitch =>
      'Optional: Bewahre eine Kopie deiner Notizen in deinem Google Drive auf';

  @override
  String get driveConnect => 'Verbinden';

  @override
  String get driveUploadNow => 'Jetzt hochladen';

  @override
  String get driveUploadNowSubtitle =>
      'Lädt die Notizen der Notizbücher mit aktivierter Synchronisierung hoch';

  @override
  String get driveRestore => 'Aus Drive wiederherstellen';

  @override
  String get driveRestoreSubtitle =>
      'Holt die neuesten Versionen und stellt auf diesem Gerät fehlende Notizen wieder her';

  @override
  String get driveNoteVersions => 'Versionen einer Notiz';

  @override
  String get driveNoteVersionsSubtitle => 'Im Editor: ⋮ → Versionsverlauf';

  @override
  String get driveSwitchAccount => 'Konto wechseln';

  @override
  String get driveSignOut => 'Abmelden';

  @override
  String get driveAccount => 'Konto';

  @override
  String driveConnectedAs(String email) {
    return 'Verbunden als $email';
  }

  @override
  String get driveNotConfigured => 'Google ist nicht konfiguriert';

  @override
  String get driveSignOutQuestion => 'Abmelden?';

  @override
  String get driveSignOutBody =>
      'Backups werden nicht mehr zu Google Drive hochgeladen. Bereits in Drive vorhandene Kopien bleiben erhalten.';

  @override
  String get driveSignedOut => 'Abgemeldet';

  @override
  String driveUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen zu Drive hochgeladen',
      one: '1 Notiz zu Drive hochgeladen',
      zero: 'Bei keinem Notizbuch ist die Synchronisierung aktiviert',
    );
    return '$_temp0';
  }

  @override
  String get driveRestoreBody =>
      'Notizen auf diesem Gerät werden nur ersetzt, wenn die Drive-Kopie neuer ist. Hier fehlende Notizen kehren in ihr Notizbuch zurück (oder in ein neues Notizbuch „Aus Drive wiederhergestellt“).';

  @override
  String get backupSaveTitle => 'Inklus-Backup speichern';

  @override
  String get backupSaved => 'Backup gespeichert';

  @override
  String get driveSignInIncomplete => 'Die Anmeldung wurde nicht abgeschlossen';

  @override
  String get driveDetails => 'Details';

  @override
  String get driveSignInHelpTitle => 'Anmeldung nicht möglich';

  @override
  String driveSignInHelpBody(String details) {
    return 'Wenn du die Kontoauswahl gerade nur geschlossen hast, ist alles in Ordnung. Wenn du ein Konto gewählt hast und es sich nicht verbindet, ist fast immer der Signaturschlüssel der App (SHA-1) in Google Cloud nicht für com.inklus.inklus registriert.\n\nTechnisches Detail:\n$details';
  }

  @override
  String get driveNotebooksTitle => 'Synchronisierte Notizbücher';

  @override
  String get driveNotebooksSubtitle =>
      'Jedes Notizbuch wird in Drive → Inklus → einem eigenen Ordner gespeichert. Wähle, welche.';

  @override
  String get driveNotebooksEmpty => 'Noch keine Notizbücher.';

  @override
  String get driveSyncMenu => 'Mit Drive synchronisieren';

  @override
  String get driveSyncEnabled => 'Synchronisierung aktiviert';

  @override
  String get driveSyncDisabled => 'Synchronisierung deaktiviert';

  @override
  String get textEditHint => 'Hier schreiben…';

  @override
  String get textEditMove => 'Feld verschieben';

  @override
  String get textEditWidth => 'Feldbreite';

  @override
  String get textEditSmaller => 'Kleiner';

  @override
  String get textEditLarger => 'Größer';

  @override
  String get textEditBold => 'Fett';

  @override
  String get textEditItalic => 'Kursiv';

  @override
  String get textEditUnderline => 'Unterstrichen';

  @override
  String get textEditStrike => 'Durchgestrichen';

  @override
  String get textEditColor => 'Textfarbe';

  @override
  String get textEditHighlight => 'Hervorhebung';

  @override
  String get textEditAlign => 'Ausrichtung';

  @override
  String get textEditSpacing => 'Zeilenabstand';

  @override
  String get textEditLinkActive => 'Seitenlink (aktiv)';

  @override
  String get textEditLink => 'Link zu einer Seite';

  @override
  String get textEditDelete => 'Feld löschen';

  @override
  String get textEditDone => 'Fertig';

  @override
  String get textEditWholeBox => 'Ganzes Feld';

  @override
  String get textEditNoHighlight => 'Keine Hervorhebung';

  @override
  String get textEditUnlink => 'Link entfernen';

  @override
  String commonPageN(int n) {
    return 'Seite $n';
  }

  @override
  String get marketWhereTemplate => 'im Vorlagen-Menü der Seite';

  @override
  String get marketWherePalette => 'in den Farben jedes Stifts';

  @override
  String get marketWhereStickers => 'unter Mehr Werkzeuge → Sticker einfügen';

  @override
  String get marketHeroTitle => 'Entdecken und anpassen';

  @override
  String get marketHeroSubtitle =>
      'Vorlagen, Paletten und Sticker aus der Community. Kostenlos und offen lizenziert.';

  @override
  String get marketSearch => 'Pakete suchen';

  @override
  String get marketTitle => 'Marktplatz';

  @override
  String get marketOfflineCache =>
      'Offline: Zuletzt geladener Katalog wird angezeigt';

  @override
  String get marketOfflineBundled =>
      'Offline: In der App enthaltene Pakete werden angezeigt';

  @override
  String get marketAll => 'Alle';

  @override
  String get marketTemplates => 'Vorlagen';

  @override
  String get marketPalettes => 'Paletten';

  @override
  String get marketStickers => 'Sticker';

  @override
  String get marketPalette => 'Palette';

  @override
  String get marketNoResults => 'Keine passenden Pakete';

  @override
  String get marketRemove => 'Entfernen';

  @override
  String get marketInstall => 'Installieren';

  @override
  String marketUninstalled(String name) {
    return '„$name“ deinstalliert';
  }

  @override
  String marketInstalled(String name, String where) {
    return '„$name“ installiert: $where';
  }

  @override
  String marketInstallFailed(String name, String error) {
    return '„$name“ konnte nicht installiert werden: $error';
  }

  @override
  String get createTplBlank => 'Leer';

  @override
  String get createTplRuled => 'Liniert';

  @override
  String get createTplGrid => 'Kariert';

  @override
  String get createTplDots => 'Gepunktet';

  @override
  String get createTplMusic => 'Notenlinien';

  @override
  String get createTplPlanner => 'Planer';

  @override
  String get createTplHabit => 'Gewohnheiten';

  @override
  String get createTplCornell => 'Cornell';

  @override
  String get createTplWeekly => 'Woche';

  @override
  String get createTplMonthly => 'Monat';

  @override
  String get createTplTodo => 'Aufgaben';

  @override
  String get createTplStoryboard => 'Storyboard';

  @override
  String get createTplMillimeter => 'Millimeterpapier';

  @override
  String get createTplSheet => 'A4-Blatt';

  @override
  String get createTitle => 'Neues Notizbuch';

  @override
  String get createName => 'Name';

  @override
  String get createNameHint => 'Mein Notizbuch';

  @override
  String get createCover => 'Einband';

  @override
  String get createDesign => 'Muster';

  @override
  String get createYourImage => 'Dein Bild';

  @override
  String get createChangeImage => 'Bild ändern';

  @override
  String get createColor => 'Farbe';

  @override
  String get createNext => 'Weiter';

  @override
  String get createStep2 => 'Schritt 2: Vorlage wählen';

  @override
  String get createBackToStep1 => 'Zurück zu Schritt 1';

  @override
  String get createTemplate => 'Vorlage';

  @override
  String get createMoreTemplates => 'Mehr Vorlagen zeigen';

  @override
  String get createFewer => 'Weniger zeigen';

  @override
  String get createInfinite => 'Unendliche Fläche';

  @override
  String get createInfiniteOn => 'Die Fläche wächst mit deinem Text';

  @override
  String get createInfiniteOff => 'Blatt mit fester Größe (A4)';

  @override
  String get createAction => 'Notizbuch erstellen';

  @override
  String createDefaultName(int n) {
    return 'Notizbuch $n';
  }

  @override
  String createCoverSemantics(String name) {
    return 'Einband $name';
  }

  @override
  String get libRenameTitle => 'Notizbuch umbenennen';

  @override
  String get libDeleteTitle => 'Notizbuch löschen';

  @override
  String get libDelete => 'Löschen';

  @override
  String get libCoverColor => 'Einbandfarbe';

  @override
  String get commonSave => 'Speichern';

  @override
  String get libSortTitle => 'Notizbücher sortieren';

  @override
  String get libSortNewestFirst => 'Neueste zuerst';

  @override
  String get libSortOldestFirst => 'Älteste zuerst';

  @override
  String get libSortTitleAZ => 'Titel A → Z';

  @override
  String get libSortTitleZA => 'Titel Z → A';

  @override
  String get libNavAll => 'Alle';

  @override
  String get libNavRecent => 'Zuletzt';

  @override
  String get libNavFavorites => 'Favoriten';

  @override
  String get libNavFolders => 'Ordner';

  @override
  String get libImport => '.inklus importieren';

  @override
  String get libTrash => 'Papierkorb';

  @override
  String get libLightMode => 'Heller Modus';

  @override
  String get libDarkMode => 'Dunkler Modus';

  @override
  String get libMoreOptions => 'Weitere Optionen';

  @override
  String get libMyNotebooks => 'Meine Notizbücher';

  @override
  String get libClearFilter => 'Filter zurücksetzen';

  @override
  String get libSearchHint => 'Nach Name oder Tag suchen';

  @override
  String get libSearchInNotes => 'In Notizen suchen (Text und Handschrift)';

  @override
  String get libSearchContent => 'Im Inhalt';

  @override
  String get libSortNewest => 'Neueste';

  @override
  String get libSortOldest => 'Älteste';

  @override
  String get libSortNameAZ => 'Name A–Z';

  @override
  String get libSortNameZA => 'Name Z–A';

  @override
  String get libGrid => 'Raster';

  @override
  String get libList => 'Liste';

  @override
  String get libNoResults => 'Keine Notizbücher gefunden';

  @override
  String get libEmptyTitle => 'Fang an zu schreiben';

  @override
  String get libNoResultsHint => 'Versuche einen anderen Namen oder Tag.';

  @override
  String get libUnfavorite => 'Aus Favoriten entfernen';

  @override
  String get libFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get libRename => 'Umbenennen';

  @override
  String get libDuplicate => 'Duplizieren';

  @override
  String get libCoverAndColor => 'Einband und Farbe';

  @override
  String get libTags => 'Tags';

  @override
  String get libSyncOff => 'Synchronisierung mit Drive beenden';

  @override
  String get libMoveToTrash => 'In den Papierkorb';

  @override
  String get libNotebookOptions => 'Notizbuch-Optionen';

  @override
  String libSyncWillSync(String title) {
    return '„$title“ wird mit Drive synchronisiert';
  }

  @override
  String libSyncStopped(String title) {
    return '„$title“ wird nicht mehr synchronisiert';
  }

  @override
  String libDeleteBody(String title) {
    return '„$title“ wird in den Papierkorb verschoben. Von dort kannst du es wiederherstellen.';
  }

  @override
  String libImportError(String error) {
    return 'Importfehler: $error';
  }

  @override
  String libCountAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Notizbücher',
      one: '1 Notizbuch',
    );
    return '$_temp0';
  }

  @override
  String libCountOf(int shown, int total) {
    return '$shown von $total Notizbüchern';
  }

  @override
  String libNotebookSemantics(String title, String when) {
    return 'Notizbuch $title, $when';
  }

  @override
  String get libEmptyHint =>
      'Erstelle ein neues Notizbuch oder importiere ein vorhandenes,\\num loszulegen.';

  @override
  String get noteRenameTitle => 'Notiz umbenennen';

  @override
  String get noteDeleteTitle => 'Notiz löschen';

  @override
  String get noteNew => 'Neue Notiz';

  @override
  String get noteNameHint => 'Meine Notiz';

  @override
  String get noteCreate => 'Erstellen';

  @override
  String get noteEmptyTitle => 'Keine Notizen';

  @override
  String get noteEmptyHint =>
      'Erstelle deine erste Notiz, um mit dem Schreiben zu beginnen.';

  @override
  String get noteCreateAction => 'Notiz erstellen';

  @override
  String get noteOptions => 'Optionen';

  @override
  String get timeNow => 'gerade eben';

  @override
  String get noteTplInfinite => 'Unendlich';

  @override
  String get noteTplSheet => 'Festes Blatt';

  @override
  String get noteTplPlanner => 'Planer';

  @override
  String get tplInfiniteHint => 'Unendliche Vorlagen wachsen mit deinem Text';

  @override
  String get tplNormalSheet => 'Normales Blatt';

  @override
  String get tplOwn => 'Deine eigene Vorlage';

  @override
  String get tplFromMarket => 'Aus dem Marktplatz';

  @override
  String get tplMine => 'Meine Vorlagen';

  @override
  String get tplSaveCurrent => 'Aktuelle speichern';

  @override
  String get tplCustomize => 'Anpassen';

  @override
  String get tplLineColor => 'Linienfarbe';

  @override
  String get tplSpacing => 'Abstand';

  @override
  String get tplFixedSheet => 'Blatt mit fester Größe';

  @override
  String get tplSheetSize => 'Blattgröße';

  @override
  String get tplLetter => 'Letter';

  @override
  String get tplHowTitle => 'Wie soll die Vorlage verwendet werden?';

  @override
  String get tplHowBody => 'Das Bild dient als Hintergrund zum Schreiben.';

  @override
  String get tplAsSheet => 'Als festes Blatt';

  @override
  String get tplAsFill => 'Unendliche Füllung';

  @override
  String get tplOnlyImage => 'Nur Vorlagen mit Bild können gespeichert werden';

  @override
  String get tplSaveTitle => 'Vorlage speichern';

  @override
  String get tplDefaultName => 'Meine Vorlage';

  @override
  String get tplSaved => 'Vorlage gespeichert';

  @override
  String get tplDeleteTitle => 'Vorlage löschen';

  @override
  String get tplDeleteBody => 'Diese gespeicherte Vorlage löschen?';

  @override
  String get colorCustomTitle => 'Eigene Farbe';

  @override
  String get colorCurrent => 'Aktuell';

  @override
  String get colorNew => 'Neu';

  @override
  String get colorWheel => 'Farbrad';

  @override
  String get colorHue => 'Farbton';

  @override
  String get colorSaturation => 'Sättigung';

  @override
  String get colorBrightness => 'Helligkeit';

  @override
  String get colorUse => 'Verwenden';

  @override
  String timeMinAgo(int n) {
    return 'vor $n Min.';
  }

  @override
  String timeHoursAgo(int n) {
    return 'vor $n Std.';
  }

  @override
  String timeDaysAgo(int n) {
    return 'vor $n T.';
  }

  @override
  String get timeDeletedNow => 'gerade eben gelöscht';

  @override
  String timeDeletedMin(int n) {
    return 'vor $n Min. gelöscht';
  }

  @override
  String timeDeletedHours(int n) {
    return 'vor $n Std. gelöscht';
  }

  @override
  String timeDeletedDays(int n) {
    return 'vor $n Tagen gelöscht';
  }

  @override
  String timeDeletedOn(String date) {
    return 'gelöscht am $date';
  }

  @override
  String noteDeleteBody(String title) {
    return '„$title“ wird aus diesem Notizbuch entfernt.';
  }

  @override
  String noteDefaultName(int n) {
    return 'Notiz $n';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen',
      one: '1 Notiz',
    );
    return '$_temp0';
  }

  @override
  String notePageCount(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0 · $when';
  }

  @override
  String tplImageLoadFailed(String error) {
    return 'Das Bild konnte nicht geladen werden: $error';
  }

  @override
  String tplSaveFailed(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get colorSliders => 'Regler';

  @override
  String get selPaste => 'Einfügen';

  @override
  String get selCopy => 'Kopieren';

  @override
  String get selCopied => 'Kopiert';

  @override
  String get selThinner => 'Dünner';

  @override
  String get selThicker => 'Dicker';

  @override
  String get selToText => 'In Text umwandeln';

  @override
  String get selDeselect => 'Auswahl aufheben';

  @override
  String get selNoText => 'In der Auswahl wurde kein Text erkannt';

  @override
  String get selConvert => 'Umwandeln';

  @override
  String get popPenType => 'Stiftart';

  @override
  String get popThickness => 'Strichstärke';

  @override
  String get popStraighten => 'Formen begradigen';

  @override
  String get popNo => 'Nein';

  @override
  String get popOnHold => 'Beim Halten';

  @override
  String get popAlways => 'Immer';

  @override
  String get popShapeOffHint => 'Striche bleiben wie gezeichnet.';

  @override
  String get popShapeHoldHint =>
      'Halte den Stift nach einer Linie, einem Kreis, Dreieck oder Rechteck fast eine Sekunde still.';

  @override
  String get popShapeAlwaysHint =>
      'Jede erkennbare Form wird beim Abheben des Stifts begradigt.';

  @override
  String get popAdvanced => 'Erweiterte Strichoptionen';

  @override
  String get popMode => 'Modus';

  @override
  String get popPartial => 'Teilweise';

  @override
  String get popStroke => 'Strich';

  @override
  String get popHighlighter => 'Textmarker';

  @override
  String get popEraseOff => 'Löscht nur, was du berührst, wie ein Radiergummi.';

  @override
  String get popEraseStroke => 'Löscht beim Berühren den ganzen Strich.';

  @override
  String get popEraseHighlighter =>
      'Löscht nur Textmarker; Tinte bleibt unberührt.';

  @override
  String get popSize => 'Größe';

  @override
  String get tbBackToLibrary => 'Zurück zur Bibliothek';

  @override
  String get tbHidePages => 'Seiten ausblenden';

  @override
  String get tbPages => 'Seiten';

  @override
  String get tbHideLayers => 'Ebenen ausblenden';

  @override
  String get tbLayers => 'Ebenen';

  @override
  String get tbInsertImage => 'Bild einfügen';

  @override
  String get tbRuler => 'Lineal';

  @override
  String get tbRulerNext => 'Lineal (Tippen: Winkelmesser)';

  @override
  String get tbProtractorNext => 'Winkelmesser (Tippen: ausblenden)';

  @override
  String get tbMoveSelect => 'Bilder und Striche verschieben / auswählen';

  @override
  String get tbFill => 'Fläche füllen';

  @override
  String get tbHideMagnifier => 'Lupe ausblenden';

  @override
  String get tbMagnifier => 'Lupe';

  @override
  String get tbLaserOff => 'Laserpointer ausschalten';

  @override
  String get tbLaser => 'Laserpointer';

  @override
  String get tbInsertSticker => 'Sticker einfügen';

  @override
  String get tbPageTemplate => 'Seitenvorlage';

  @override
  String get tbMoreTools => 'Mehr Werkzeuge';

  @override
  String get tbUndo => 'Rückgängig';

  @override
  String get tbRedo => 'Wiederholen';

  @override
  String get pgUnbookmark => 'Lesezeichen entfernen';

  @override
  String get pgBookmark => 'Seite markieren';

  @override
  String get pgShowAll => 'Alle anzeigen';

  @override
  String get pgOnlyBookmarked => 'Nur markierte';

  @override
  String get commonClose => 'Schließen';

  @override
  String get pgOptions => 'Seitenoptionen';

  @override
  String get pgNew => 'Neue Seite';

  @override
  String get tagTitle => 'Tags des Notizbuchs';

  @override
  String get tagSubtitle =>
      'Zum Wiederfinden und Gruppieren in intelligenten Ordnern';

  @override
  String get tagActive => 'Aktive Tags';

  @override
  String get tagOthers => 'Weitere Tags';

  @override
  String get tagNew => 'Neuer Tag…';

  @override
  String get tagAdd => 'Tag hinzufügen';

  @override
  String get tagSave => 'Tags speichern';

  @override
  String get trashDeleteForever => 'Endgültig löschen';

  @override
  String get trashEmptyTitle => 'Papierkorb leeren';

  @override
  String get trashEmpty => 'Leeren';

  @override
  String get trashSubtitleEmpty => 'Gelöschtes bleibt hier 30 Tage';

  @override
  String get trashEmptyState => 'Der Papierkorb ist leer';

  @override
  String get trashLegacy => 'Notizbuch (altes Format)';

  @override
  String get trashNote => 'Notiz';

  @override
  String get trashReturn => 'In sein Notizbuch zurücklegen';

  @override
  String get strokeSubtitle => 'Druck, Glättung und Flüssigkeit des Strichs';

  @override
  String get strokeNone => 'Radierer und Auswahl haben keine Strichoptionen.';

  @override
  String get strokeQuickSize => 'Schnellgröße';

  @override
  String get strokePressure => 'Druckvariation';

  @override
  String get strokePressureDesc =>
      'Wie stark sich die Strichstärke beim Drücken ändert';

  @override
  String get strokeSmoothing => 'Glättung';

  @override
  String get strokeSmoothingDesc => 'Rundet die Kurven des Strichs ab';

  @override
  String get strokeStabilizer => 'Stabilisator';

  @override
  String get strokeStabilizerDesc => 'Verringert das Zittern der Hand';

  @override
  String get sizeThin => 'Dünn';

  @override
  String get sizeMedium => 'Mittel';

  @override
  String get sizeThick => 'Dick';

  @override
  String get sizeExtra => 'Extra';

  @override
  String get sizeSmall => 'Klein';

  @override
  String get sizeLarge => 'Groß';

  @override
  String get toolPen => 'Kugelschreiber';

  @override
  String get toolPencil => 'Bleistift';

  @override
  String get toolCalligraphy => 'Kalligrafiefeder';

  @override
  String get toolBrush => 'Pinsel';

  @override
  String get toolMarker => 'Marker';

  @override
  String get toolSpray => 'Spray';

  @override
  String get toolEraser => 'Radierer';

  @override
  String get toolSelect => 'Verschieben / auswählen';

  @override
  String get toolLasso => 'Lasso';

  @override
  String get toolFill => 'Füllen';

  @override
  String get toolText => 'Text';

  @override
  String selRecognizeFailed(String error) {
    return 'Erkennung nicht möglich: $error';
  }

  @override
  String tbPenSlot(String tool, int n) {
    return '$tool $n';
  }

  @override
  String get canvasSemantics => 'Zeichenfläche';

  @override
  String tbPageOf(int n, int total) {
    return 'Seite $n von $total';
  }

  @override
  String pgPagesCount(int n) {
    return 'Seiten ($n)';
  }

  @override
  String strokeOptionsOf(String tool) {
    return 'Optionen für $tool';
  }

  @override
  String trashRestoredMsg(String title) {
    return '„$title“ wiederhergestellt';
  }

  @override
  String trashPurgeBody(String title) {
    return '„$title“ wird endgültig gelöscht. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String trashEmptyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente werden endgültig gelöscht',
      one: '1 Element wird endgültig gelöscht',
    );
    return '$_temp0. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String trashSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0 · werden nach 30 Tagen automatisch gelöscht';
  }

  @override
  String get trashEmptyStateBody =>
      'Gelöschte Notizbücher und Notizen bleiben hier 30 Tage, bevor sie endgültig entfernt werden.';

  @override
  String trashNotebookKind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen',
      one: '1 Notiz',
    );
    return 'Notizbuch · $_temp0';
  }

  @override
  String trashNoteOf(String title) {
    return 'Notiz aus „$title“';
  }

  @override
  String get trashLeftTomorrow => 'wird morgen gelöscht';

  @override
  String trashLeftDays(int n) {
    return 'noch $n Tage';
  }

  @override
  String trashInfoLine(String what, String deleted, String left) {
    return '$what · $deleted · $left';
  }

  @override
  String get edLayerLocked => 'Ebene gesperrt — entsperre sie zum Bearbeiten';

  @override
  String get expTitle => 'Exportoptionen';

  @override
  String get expLow => 'Niedrig (1024 px)';

  @override
  String get expMedium => 'Mittel (2048 px)';

  @override
  String get expHigh => 'Hoch (4096 px)';

  @override
  String get expMax => 'Maximal (8192 px)';

  @override
  String get expTransparent => 'Transparenter Hintergrund';

  @override
  String get expTransparentHint => 'Ohne Vorlage und Papier';

  @override
  String get expStrokesOnly => 'Nur Striche';

  @override
  String get expStrokesOnlyHint => 'Ohne Bilder und Vorlage';

  @override
  String get expExport => 'Exportieren';

  @override
  String get ocrUnsupported => 'OCR ist nur auf Android und iOS verfügbar';

  @override
  String get ocrWorking => 'Text wird erkannt…';

  @override
  String get ocrNoText => 'Auf dieser Seite wurde kein Text erkannt';

  @override
  String get ocrResultTitle => 'Erkannter Text';

  @override
  String get ocrCopied => 'Text in die Zwischenablage kopiert';

  @override
  String get edGoogleAccount => 'Google-Konto';

  @override
  String get edSyncedCloud => 'Mit der Cloud synchronisiert';

  @override
  String get edRestoreCloud => 'Aus der Cloud wiederherstellen';

  @override
  String get edRestoreCloudHint => 'Neueste Version (letzte Änderung gewinnt)';

  @override
  String get edDriveVersions => 'Versionen in Drive ansehen';

  @override
  String get edUploadInklus => '.inklus-Datei hochladen';

  @override
  String get edSyncOnForNotebook =>
      'Synchronisierung: für dieses Notizbuch aktiv';

  @override
  String get edSyncOffForNotebook =>
      'Synchronisierung: für dieses Notizbuch aus';

  @override
  String get edSyncDisabledMsg =>
      'Synchronisierung für dieses Notizbuch ausgeschaltet';

  @override
  String get edSyncEnabledMsg =>
      'Synchronisierung für dieses Notizbuch eingeschaltet';

  @override
  String get edNoteSynced => 'Notiz mit Google Drive synchronisiert';

  @override
  String get edPasswordHint =>
      'Passwort (leer lassen, wenn nicht verschlüsselt)';

  @override
  String get edNoCloudCopy =>
      'Von dieser Notiz gibt es noch keine Kopie in Google Drive';

  @override
  String get edNoteRestored => 'Notiz aus Google Drive wiederhergestellt';

  @override
  String get edIsFullBackup =>
      'Diese Datei ist ein vollständiges Backup, kein .inklus-Notizbuch';

  @override
  String get edNoPassword => 'Kein Passwort';

  @override
  String get edNotebookTitle => 'Titel des Notizbuchs';

  @override
  String get pdfUnsupported =>
      'Der PDF-Import ist vorerst nur auf Android/iOS verfügbar';

  @override
  String get pdfReadFailed => 'Das PDF konnte nicht gelesen werden';

  @override
  String get verRestoreTitle => 'Version wiederherstellen';

  @override
  String get verRestored => 'Version wiederhergestellt';

  @override
  String get verEncrypted => 'Verschlüsselte Kopie';

  @override
  String get verPasswordHint => 'Passwort der Kopie';

  @override
  String get verDecrypt => 'Entschlüsseln';

  @override
  String get inkUnsupported =>
      'Die Handschrifterkennung ist nur auf Android und iOS verfügbar';

  @override
  String get edDeleteImage => 'Bild löschen';

  @override
  String get edExitPresent => 'Präsentation beenden';

  @override
  String get edLaserOff => 'Laser ausschalten';

  @override
  String get edGoToPage => 'Zu Seite springen';

  @override
  String get edGo => 'Los';

  @override
  String get edNoStickers => 'Du hast noch keine Sticker installiert.';

  @override
  String get edOpenMarket => 'Marktplatz öffnen';

  @override
  String get edSyncing => 'Synchronisiere…';

  @override
  String get edSyncToDrive => 'Mit Google Drive synchronisieren';

  @override
  String get edSynced => 'Synchronisiert';

  @override
  String get edSyncError => 'Synchronisierungsfehler';

  @override
  String get menuPagePng => 'Seite als Bild (PNG)';

  @override
  String get menuPagePdf => 'Seite als PDF';

  @override
  String get menuNotePdf => 'Ganze Notiz (PDF)';

  @override
  String get menuStrokesSvg => 'Striche (SVG)';

  @override
  String get menuPptx => 'Präsentation (PowerPoint)';

  @override
  String get menuInklusCopy => 'Als .inklus kopieren';

  @override
  String get menuShareImage => 'Bild teilen';

  @override
  String get menuSharePdf => 'PDF teilen';

  @override
  String get menuShareInklus => '.inklus teilen';

  @override
  String get menuExportShare => 'Exportieren und teilen';

  @override
  String get menuTemplate => 'Vorlage…';

  @override
  String get menuGoToPage => 'Zu Seite springen…';

  @override
  String get menuImportPdf => 'PDF zum Beschriften importieren';

  @override
  String get menuClearPage => 'Seite leeren';

  @override
  String get menuPage => 'Seite';

  @override
  String get menuSearchNote => 'In Notiz suchen';

  @override
  String get menuIndexInk => 'Handschrift indizieren (zum Durchsuchen)';

  @override
  String get menuIndexInkUnsupported =>
      'Handschrift indizieren (nur Android/iOS)';

  @override
  String get menuOcr => 'Text erkennen (OCR)';

  @override
  String get menuOcrUnsupported => 'OCR (nur Android/iOS)';

  @override
  String get menuVersions => 'Versionsverlauf';

  @override
  String get menuReminder => 'Erinnerung erstellen';

  @override
  String get menuNightOff => 'Nachtmodus ausschalten';

  @override
  String get menuNightOn => 'Nachtmodus zum Schreiben';

  @override
  String get menuPresent => 'Präsentationsmodus';

  @override
  String get menuHapticsOn => 'Vibration beim Schreiben: an';

  @override
  String get menuHapticsOff => 'Vibration beim Schreiben: aus';

  @override
  String get menuContinuousScroll => 'Fortlaufendes Scrollen zwischen Blättern';

  @override
  String get menuView => 'Ansicht';

  @override
  String get menuBackup => 'Vollständiges Backup exportieren';

  @override
  String get menuRestoreBackup => '.inklus oder Backup importieren';

  @override
  String get menuData => 'Daten';

  @override
  String get menuStats => 'Schreibstatistik';

  @override
  String get clearPageBody =>
      'Der gesamte Inhalt der Seite wird gelöscht. Du kannst das danach rückgängig machen.';

  @override
  String get clearPageAction => 'Leeren';

  @override
  String get pgPrev => 'Vorherige Seite';

  @override
  String get pgNext => 'Nächste Seite';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get zoomFit => 'An Ansicht anpassen';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get shareTextPage => 'Inklus-Seite';

  @override
  String get shareTextNotebook => 'Inklus-Notizbuch';

  @override
  String edInsertImageFailed(String error) {
    return 'Das Bild konnte nicht eingefügt werden: $error';
  }

  @override
  String expSvgFailed(String error) {
    return 'SVG-Exportfehler: $error';
  }

  @override
  String ocrFailed(String error) {
    return 'Fehler bei der Texterkennung: $error';
  }

  @override
  String expFailed(String error) {
    return 'Exportfehler: $error';
  }

  @override
  String expPreview(String name) {
    return 'Vorschau: $name';
  }

  @override
  String expSaveDialog(String name) {
    return '$name speichern';
  }

  @override
  String expDone(String path) {
    return 'Exportiert: $path';
  }

  @override
  String expSaveFailed(String error) {
    return 'Die Datei konnte nicht gespeichert werden: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Fehler beim Teilen: $error';
  }

  @override
  String edSignInIncomplete(String detail) {
    return 'Die Anmeldung wurde nicht abgeschlossen. Detail: $detail';
  }

  @override
  String uploadFailed(String error) {
    return 'Fehler beim Hochladen: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Fehler bei der Wiederherstellung: $error';
  }

  @override
  String edFileUploaded(String name) {
    return 'Datei „$name“ zu Google Drive hochgeladen';
  }

  @override
  String pdfImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return 'PDF importiert: $_temp0 zum Beschriften';
  }

  @override
  String pdfImportFailed(String error) {
    return 'Fehler beim PDF-Import: $error';
  }

  @override
  String verRestoreBody(String date) {
    return 'Die Notiz kehrt zum Stand vom $date zurück.\\n\\nDer aktuelle Stand wird zuvor als lokale Version gespeichert, sodass du die Wiederherstellung in diesem Verlauf rückgängig machen kannst.';
  }

  @override
  String verRestoreFailed(String error) {
    return 'Die Version konnte nicht wiederhergestellt werden: $error';
  }

  @override
  String pptxFailed(String error) {
    return 'Fehler beim PowerPoint-Export: $error';
  }

  @override
  String reminderCreated(String date, String time) {
    return 'Erinnerung für $date um $time erstellt';
  }

  @override
  String inkIndexed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return 'Handschrift auf $_temp0 indiziert: Du kannst sie jetzt durchsuchen';
  }

  @override
  String inkFailed(String error) {
    return 'Die Handschrift konnte nicht erkannt werden: $error';
  }

  @override
  String backupFailed(String error) {
    return 'Fehler beim Exportieren des Backups: $error';
  }

  @override
  String importDoneOpen(String message) {
    return '$message. Öffne es in der Bibliothek.';
  }

  @override
  String noteHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return 'Die Notiz hat $_temp0';
  }

  @override
  String stickerInsertFailed(String error) {
    return 'Der Sticker konnte nicht eingefügt werden: $error';
  }

  @override
  String get remNoNotebooks => 'Keine Notizbücher zum Verknüpfen';

  @override
  String get remPickNotebook => 'Notizbuch auswählen';

  @override
  String get remPickHint => 'Die Erinnerung öffnet dieses Notizbuch';

  @override
  String get remCreated => 'Erinnerung erstellt';

  @override
  String get remMessageTitle => 'Text der Erinnerung';

  @override
  String get remMessageHint => 'z. B. Vorlesungsnotizen wiederholen';

  @override
  String get remNoMessage => 'Ohne Text';

  @override
  String get remTitle => 'Erinnerungen';

  @override
  String get remSubtitle => 'Hinweise zu deinen Notizbüchern';

  @override
  String get remEmptyTitle => 'Keine Erinnerungen';

  @override
  String get remPending => 'Ausstehend';

  @override
  String get remDone => 'Erledigt';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsSubtitle => 'Deine Schreibaktivität auf diesem Gerät';

  @override
  String get statsEmptyTitle => 'Noch keine Daten';

  @override
  String get statsStrokes => 'Striche';

  @override
  String get statsMinutes => 'Minuten';

  @override
  String get statsActiveDays => 'Aktive Tage';

  @override
  String get statsStreaks => 'Serien';

  @override
  String get statsCurrentStreak => 'Aktuelle Serie';

  @override
  String get statsRecord => 'Rekord';

  @override
  String get statsActivity => 'Aktivität — letzte 30 Tage';

  @override
  String get statsDaysWithPages => 'Tage mit neuen Seiten';

  @override
  String get smartTitle => 'Intelligente Ordner';

  @override
  String get smartSubtitle => 'Ordne deine Notizbücher automatisch';

  @override
  String get smartByColor => 'Nach Farbe';

  @override
  String get smartByTag => 'Nach Tag';

  @override
  String get onbSkip => 'Überspringen';

  @override
  String get onbStart => 'Los geht’s';

  @override
  String get onb1Title => 'Schreibe mit dem Stift';

  @override
  String get onb2Title => 'Bewege dich mit den Fingern';

  @override
  String get onb3Title => 'Werkzeuge oben';

  @override
  String get onb4Title => 'Deine Notizen gehören dir';

  @override
  String get layerAdd => 'Ebene hinzufügen';

  @override
  String get layerRename => 'Ebene umbenennen';

  @override
  String get verSubtitle =>
      'Beim Wiederherstellen wird zuerst der aktuelle Stand gesichert';

  @override
  String get verOnDevice => 'Auf diesem Gerät';

  @override
  String get verNoLocal =>
      'Von dieser Notiz gibt es noch keine lokalen Kopien.';

  @override
  String get verOnDrive => 'In Google Drive';

  @override
  String get verNotUploaded =>
      'Diese Notiz wurde noch nicht zu Drive hochgeladen.';

  @override
  String get smartThisWeek => 'Diese Woche';

  @override
  String get smartNoTags => 'Ohne Tags';

  @override
  String get smartOther => 'Sonstige';

  @override
  String get colorNone => 'Keine Farbe';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Lila';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorTurquoise => 'Türkis';

  @override
  String get colorGray => 'Grau';

  @override
  String get onb1Body =>
      'Leg die Hand unbesorgt auf: Inklus erkennt den Stift und ignoriert deine Handfläche. Das Radiererende oder die Seitentaste des Stifts löscht.';

  @override
  String get onb2Body =>
      'Mit dem Stift scrollt ein Finger die Seite und zwei Finger zoomen. In der Werkzeugleiste kannst du wieder mit dem Finger zeichnen.';

  @override
  String get onb3Body =>
      'Tippe auf ein Werkzeug, um es zu benutzen, und tippe erneut darauf, um seine Optionen zu sehen: Strichstärke, Farbe, teilweiser Radierer, Formen…';

  @override
  String get onb4Body =>
      'Alles wird auf diesem Gerät gespeichert, ohne Konten und ohne Werbung. Wenn du möchtest, kannst du in dein Google Drive sichern.';

  @override
  String get remEmptyBody =>
      'Erstelle mit deinen Notizbüchern verknüpfte Erinnerungen, damit du nie etwas vergisst.';

  @override
  String get statsEmptyBody =>
      'Fang an, in deinen Notizbüchern zu schreiben, und deine Statistik erscheint hier.';

  @override
  String get remOverdue => ' · überfällig';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String statsDayTooltip(String date, int strokes, int pages) {
    return '$date: $strokes Striche, $pages Seiten';
  }

  @override
  String get searchInNote => 'In dieser Notiz suchen';

  @override
  String get searchInAll => 'In allen Notizen suchen';

  @override
  String get searchPrompt => 'Zum Suchen tippen';

  @override
  String searchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
    );
    return '$_temp0';
  }

  @override
  String get searchInfo =>
      'Umfasst Textfelder und bereits erkannte Handschrift (Menü Notiz → Handschrift indizieren).';

  @override
  String get searchTitleMatch => 'Titel';

  @override
  String get pgDuplicate => 'Seite duplizieren';

  @override
  String get pgDelete => 'Seite löschen';

  @override
  String verDriveFailed(String error) {
    return 'Drive konnte nicht abgefragt werden: $error';
  }

  @override
  String colorSemantics(String hex) {
    return 'Farbe #$hex';
  }

  @override
  String get errNotInklus =>
      'Die Datei ist weder ein .inklus-Notizbuch noch ein Inklus-Backup.';

  @override
  String get errNotInklusFile => 'Kein gültiges .inklus-Notizbuch';

  @override
  String get errNotInklusV2 => 'Kein gültiges .inklus-v2-Notizbuch';

  @override
  String get errCatalogTooLarge => 'Der Katalog ist zu groß';

  @override
  String errCatalogVersion(String version) {
    return 'Nicht unterstützte Katalogversion: $version';
  }

  @override
  String get errOcrUnsupported => 'OCR ist nur auf Android und iOS verfügbar.';

  @override
  String get errNotSignedIn => 'Melde dich zuerst bei Google an.';

  @override
  String get errEncrypted =>
      'Die Kopie ist verschlüsselt: Ein Passwort ist erforderlich';

  @override
  String driveConfigBody(String details) {
    return 'Google-Konfigurationsfehler (clientConfigurationError).\\n\\nWahrscheinliche Ursache: Der Signatur-SHA-1 dieser App ist in der Google Cloud Console nicht für das Paket com.inklus.inklus registriert.\\n\\nLösung:\\n1. Öffne Google Cloud Console → APIs & Dienste → Anmeldedaten\\n2. Erstelle oder bearbeite die Android-OAuth-Client-ID mit dem Paket com.inklus.inklus und deinem Signatur-SHA-1\\n3. Aktiviere Google Sign-In auf dem Zustimmungsbildschirm\\n\\nUrsprünglicher Fehler: $details';
  }

  @override
  String get noticeStylus =>
      'Stift erkannt: Der Finger scrollt jetzt die Seite (in der Werkzeugleiste kannst du das Zeichnen mit dem Finger wieder einschalten)';

  @override
  String get noticePageDeleted => 'Seite gelöscht';

  @override
  String get noticeFileUploaded => 'Datei zu Google Drive hochgeladen';

  @override
  String importBackupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizbücher',
      one: '1 Notizbuch',
    );
    return 'Backup wiederhergestellt: $_temp0';
  }

  @override
  String importNotebookDone(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen',
      one: '1 Notiz',
    );
    return 'Notizbuch „$title“ importiert ($_temp0)';
  }

  @override
  String importNotebookSimple(String title) {
    return 'Notizbuch „$title“ importiert';
  }

  @override
  String get driveRestoreNone =>
      'In deinem Google Drive gibt es keine Inklus-Kopien';

  @override
  String get driveRestoreUpToDate => 'Alles aktuell: nichts wiederherzustellen';

  @override
  String driveRestoreUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen aktualisiert',
      one: '1 Notiz aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String driveRestoreAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wiederhergestellt',
      one: '1 wiederhergestellt',
    );
    return '$_temp0';
  }

  @override
  String get driveRecovered => 'Aus Drive wiederhergestellt';

  @override
  String get packClassicName => 'Klassische Notizbücher';

  @override
  String get packClassicDesc =>
      'Weite und enge Linierung, 5-mm-Karo, Punkte und Notenlinien.';

  @override
  String get packTechName => 'Technisches Papier';

  @override
  String get packTechDesc =>
      'Feines Millimeterpapier-Raster und Spaltenplaner in sanften Tönen.';

  @override
  String get packStudyName => 'Lernpalette';

  @override
  String get packStudyDesc =>
      'Blaue und schwarze Tinte, Korrekturrot, Grün und Orange zum Hervorheben.';

  @override
  String get packPastelName => 'Pastellpalette';

  @override
  String get packPastelDesc => 'Sanfte Töne für schöne Notizen und Diagramme.';

  @override
  String get packEarthName => 'Erdpalette';

  @override
  String get packEarthDesc =>
      'Ocker, Oliv und Terrakotta, mit gutem Kontrast auf Papier.';

  @override
  String get coverSimple => 'Verlauf';

  @override
  String get coverClassic => 'Klassisch';

  @override
  String get coverAurora => 'Aurora';

  @override
  String get coverWaves => 'Wellen';

  @override
  String get coverGeometric => 'Geometrisch';

  @override
  String get coverSun => 'Sonne';

  @override
  String get coverDots => 'Punkte';

  @override
  String get coverLines => 'Linien';

  @override
  String get untitled => 'Ohne Titel';

  @override
  String get defaultNotebookTitle => 'Mein Notizbuch';

  @override
  String get createFromFile => 'Oder mit einer Datei beginnen';

  @override
  String get createFromFileHint =>
      'Lade ein PDF oder Fotos hoch und schreibe auf jede Seite.';

  @override
  String get createFromPdf => 'Aus einem PDF';

  @override
  String get createFromImages => 'Aus Bildern';

  @override
  String get createFromFileRemove => 'Datei entfernen';

  @override
  String createFromFilePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0';
  }

  @override
  String get menuTwoFingerUndo => 'Rückgängig mit Zwei-Finger-Tipp';

  @override
  String get popEraserAutoRevert =>
      'Nach dem Radieren zum vorherigen Werkzeug zurückkehren';

  @override
  String get saveFailed =>
      'Die Notiz konnte nicht gespeichert werden. Gib Speicherplatz frei: Es wird automatisch erneut versucht.';

  @override
  String get tplHalfLetter => 'Half Letter';
}
