import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonOk;

  /// No description provided for @commonRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get commonRestore;

  /// No description provided for @commonShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get commonShare;

  /// No description provided for @commonGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonGotIt;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inklus {version} · tus notas se guardan en este dispositivo'**
  String settingsSubtitle(String version);

  /// No description provided for @settingsSectionDrive.
  ///
  /// In es, this message translates to:
  /// **'Google Drive'**
  String get settingsSectionDrive;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionFiles.
  ///
  /// In es, this message translates to:
  /// **'Copias y archivos'**
  String get settingsSectionFiles;

  /// No description provided for @settingsSectionTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get settingsSectionTools;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsSectionAbout;

  /// No description provided for @settingsImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar .inklus o respaldo'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un cuaderno (.inklus) o un respaldo completo (.zip); se reconoce solo'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo completo'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todos los cuadernos, imágenes y papelera en un .zip'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsAutosaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardado automático'**
  String get settingsAutosaveTitle;

  /// No description provided for @settingsAutosaveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cada cambio se guarda al instante en este dispositivo. Al abrir y cerrar una nota se guarda una versión (menú ⋮ → Historial de versiones).'**
  String get settingsAutosaveSubtitle;

  /// No description provided for @settingsStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de escritura'**
  String get settingsStatsTitle;

  /// No description provided for @settingsStatsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Trazos, páginas, rachas y actividad'**
  String get settingsStatsSubtitle;

  /// No description provided for @settingsRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get settingsRemindersTitle;

  /// No description provided for @settingsRemindersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos vinculados a tus cuadernos'**
  String get settingsRemindersSubtitle;

  /// No description provided for @settingsTrashTitle.
  ///
  /// In es, this message translates to:
  /// **'Papelera'**
  String get settingsTrashTitle;

  /// No description provided for @settingsTrashSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recupera cuadernos y notas eliminados'**
  String get settingsTrashSubtitle;

  /// No description provided for @settingsAppTagline.
  ///
  /// In es, this message translates to:
  /// **'Escritura a mano para tablets con lápiz'**
  String get settingsAppTagline;

  /// No description provided for @settingsFreeTitle.
  ///
  /// In es, this message translates to:
  /// **'Libre y gratuito'**
  String get settingsFreeTitle;

  /// No description provided for @settingsFreeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Código abierto (GPL-3.0). Sin funciones de pago, sin anuncios y sin analítica.'**
  String get settingsFreeSubtitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Qué datos maneja la app y adónde van'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsSourceTitle.
  ///
  /// In es, this message translates to:
  /// **'Código fuente'**
  String get settingsSourceTitle;

  /// No description provided for @settingsSourceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Informa de un fallo o sugiere mejoras en GitHub'**
  String get settingsSourceSubtitle;

  /// No description provided for @settingsErrorLogTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro de errores'**
  String get settingsErrorLogTitle;

  /// No description provided for @settingsErrorLogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se guarda solo en este dispositivo; puedes compartirlo para ayudar a corregir un fallo'**
  String get settingsErrorLogSubtitle;

  /// No description provided for @settingsErrorLogEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay errores registrados'**
  String get settingsErrorLogEmpty;

  /// No description provided for @settingsErrorLogCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 error registrado} other{{count} errores registrados}}'**
  String settingsErrorLogCount(int count);

  /// No description provided for @settingsErrorLogShareSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por correo o en un issue de GitHub'**
  String get settingsErrorLogShareSubtitle;

  /// No description provided for @settingsErrorLogClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar registro'**
  String get settingsErrorLogClear;

  /// No description provided for @settingsErrorLogCleared.
  ///
  /// In es, this message translates to:
  /// **'Registro borrado'**
  String get settingsErrorLogCleared;

  /// No description provided for @settingsErrorLogSubject.
  ///
  /// In es, this message translates to:
  /// **'Registro de errores de Inklus {version}'**
  String settingsErrorLogSubject(String version);

  /// No description provided for @settingsOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir {url}'**
  String settingsOpenFailed(String url);

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @driveConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get driveConnected;

  /// No description provided for @driveCloudCopy.
  ///
  /// In es, this message translates to:
  /// **'Copia en la nube'**
  String get driveCloudCopy;

  /// No description provided for @driveGoogleAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de Google'**
  String get driveGoogleAccount;

  /// No description provided for @driveOptionalPitch.
  ///
  /// In es, this message translates to:
  /// **'Opcional: guarda una copia de tus notas en tu Google Drive'**
  String get driveOptionalPitch;

  /// No description provided for @driveConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get driveConnect;

  /// No description provided for @driveUploadNow.
  ///
  /// In es, this message translates to:
  /// **'Subir ahora'**
  String get driveUploadNow;

  /// No description provided for @driveUploadNowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sube las notas de los cuadernos con sincronización activa'**
  String get driveUploadNowSubtitle;

  /// No description provided for @driveRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar desde Drive'**
  String get driveRestore;

  /// No description provided for @driveRestoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Trae las versiones más recientes y recupera las notas que no estén en este dispositivo'**
  String get driveRestoreSubtitle;

  /// No description provided for @driveNoteVersions.
  ///
  /// In es, this message translates to:
  /// **'Versiones de una nota'**
  String get driveNoteVersions;

  /// No description provided for @driveNoteVersionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'En el editor: ⋮ → Historial de versiones'**
  String get driveNoteVersionsSubtitle;

  /// No description provided for @driveSwitchAccount.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de cuenta'**
  String get driveSwitchAccount;

  /// No description provided for @driveSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get driveSignOut;

  /// No description provided for @driveAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get driveAccount;

  /// No description provided for @driveConnectedAs.
  ///
  /// In es, this message translates to:
  /// **'Conectado como {email}'**
  String driveConnectedAs(String email);

  /// No description provided for @driveNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Google no está configurado'**
  String get driveNotConfigured;

  /// No description provided for @driveSignOutQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get driveSignOutQuestion;

  /// No description provided for @driveSignOutBody.
  ///
  /// In es, this message translates to:
  /// **'Dejarán de subirse copias a Google Drive. Las copias que ya están en Drive no se borran.'**
  String get driveSignOutBody;

  /// No description provided for @driveSignedOut.
  ///
  /// In es, this message translates to:
  /// **'Sesión cerrada'**
  String get driveSignedOut;

  /// No description provided for @driveUploaded.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No hay cuadernos con sincronización activa} =1{1 nota subida a Drive} other{{count} notas subidas a Drive}}'**
  String driveUploaded(int count);

  /// No description provided for @driveRestoreBody.
  ///
  /// In es, this message translates to:
  /// **'Las notas de este dispositivo se reemplazan solo si la copia de Drive es más reciente. Las que no existan aquí se guardan en un cuaderno nuevo \"Recuperado de Drive\".'**
  String get driveRestoreBody;

  /// No description provided for @backupSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar respaldo de Inklus'**
  String get backupSaveTitle;

  /// No description provided for @backupSaved.
  ///
  /// In es, this message translates to:
  /// **'Respaldo guardado'**
  String get backupSaved;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
