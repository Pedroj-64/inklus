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
  /// **'Las notas de este dispositivo se reemplazan solo si la copia de Drive es más reciente. Las que no existan aquí vuelven a su cuaderno (o a uno nuevo \"Recuperado de Drive\").'**
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

  /// No description provided for @driveSignInIncomplete.
  ///
  /// In es, this message translates to:
  /// **'No se completó el inicio de sesión'**
  String get driveSignInIncomplete;

  /// No description provided for @driveDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get driveDetails;

  /// No description provided for @driveSignInHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión'**
  String get driveSignInHelpTitle;

  /// No description provided for @driveSignInHelpBody.
  ///
  /// In es, this message translates to:
  /// **'Si cerraste el selector de cuentas, no pasa nada. Si elegiste una cuenta y no se conectó, casi siempre es que la firma de esta app (SHA-1) no está registrada en Google Cloud para com.inklus.inklus.\n\nDetalle técnico:\n{details}'**
  String driveSignInHelpBody(String details);

  /// No description provided for @driveNotebooksTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuadernos que se sincronizan'**
  String get driveNotebooksTitle;

  /// No description provided for @driveNotebooksSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cada cuaderno se guarda en Drive → Inklus → su carpeta. Elige cuáles.'**
  String get driveNotebooksSubtitle;

  /// No description provided for @driveNotebooksEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cuadernos.'**
  String get driveNotebooksEmpty;

  /// No description provided for @driveSyncMenu.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar con Drive'**
  String get driveSyncMenu;

  /// No description provided for @driveSyncEnabled.
  ///
  /// In es, this message translates to:
  /// **'Sincronización activada'**
  String get driveSyncEnabled;

  /// No description provided for @driveSyncDisabled.
  ///
  /// In es, this message translates to:
  /// **'Sincronización desactivada'**
  String get driveSyncDisabled;

  /// No description provided for @textEditHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe aquí…'**
  String get textEditHint;

  /// No description provided for @textEditMove.
  ///
  /// In es, this message translates to:
  /// **'Mover caja'**
  String get textEditMove;

  /// No description provided for @textEditWidth.
  ///
  /// In es, this message translates to:
  /// **'Ancho de la caja'**
  String get textEditWidth;

  /// No description provided for @textEditSmaller.
  ///
  /// In es, this message translates to:
  /// **'Más pequeño'**
  String get textEditSmaller;

  /// No description provided for @textEditLarger.
  ///
  /// In es, this message translates to:
  /// **'Más grande'**
  String get textEditLarger;

  /// No description provided for @textEditBold.
  ///
  /// In es, this message translates to:
  /// **'Negrita'**
  String get textEditBold;

  /// No description provided for @textEditItalic.
  ///
  /// In es, this message translates to:
  /// **'Cursiva'**
  String get textEditItalic;

  /// No description provided for @textEditUnderline.
  ///
  /// In es, this message translates to:
  /// **'Subrayado'**
  String get textEditUnderline;

  /// No description provided for @textEditStrike.
  ///
  /// In es, this message translates to:
  /// **'Tachado'**
  String get textEditStrike;

  /// No description provided for @textEditColor.
  ///
  /// In es, this message translates to:
  /// **'Color del texto'**
  String get textEditColor;

  /// No description provided for @textEditHighlight.
  ///
  /// In es, this message translates to:
  /// **'Resaltar'**
  String get textEditHighlight;

  /// No description provided for @textEditAlign.
  ///
  /// In es, this message translates to:
  /// **'Alineación'**
  String get textEditAlign;

  /// No description provided for @textEditSpacing.
  ///
  /// In es, this message translates to:
  /// **'Interlineado'**
  String get textEditSpacing;

  /// No description provided for @textEditLinkActive.
  ///
  /// In es, this message translates to:
  /// **'Enlace a página (activo)'**
  String get textEditLinkActive;

  /// No description provided for @textEditLink.
  ///
  /// In es, this message translates to:
  /// **'Vincular a página'**
  String get textEditLink;

  /// No description provided for @textEditDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar caja'**
  String get textEditDelete;

  /// No description provided for @textEditDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get textEditDone;

  /// No description provided for @textEditWholeBox.
  ///
  /// In es, this message translates to:
  /// **'Toda la caja'**
  String get textEditWholeBox;

  /// No description provided for @textEditNoHighlight.
  ///
  /// In es, this message translates to:
  /// **'Sin resaltado'**
  String get textEditNoHighlight;

  /// No description provided for @textEditUnlink.
  ///
  /// In es, this message translates to:
  /// **'Quitar enlace'**
  String get textEditUnlink;

  /// No description provided for @commonPageN.
  ///
  /// In es, this message translates to:
  /// **'Página {n}'**
  String commonPageN(int n);

  /// No description provided for @marketWhereTemplate.
  ///
  /// In es, this message translates to:
  /// **'en Plantilla de la página'**
  String get marketWhereTemplate;

  /// No description provided for @marketWherePalette.
  ///
  /// In es, this message translates to:
  /// **'en los colores de cada pluma'**
  String get marketWherePalette;

  /// No description provided for @marketWhereStickers.
  ///
  /// In es, this message translates to:
  /// **'en Más herramientas → Insertar sticker'**
  String get marketWhereStickers;

  /// No description provided for @marketHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Descubre y personaliza'**
  String get marketHeroTitle;

  /// No description provided for @marketHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Plantillas, paletas y stickers de la comunidad. Gratis y de licencia libre.'**
  String get marketHeroSubtitle;

  /// No description provided for @marketSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar paquetes'**
  String get marketSearch;

  /// No description provided for @marketTitle.
  ///
  /// In es, this message translates to:
  /// **'Marketplace'**
  String get marketTitle;

  /// No description provided for @marketOfflineCache.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: último catálogo descargado'**
  String get marketOfflineCache;

  /// No description provided for @marketOfflineBundled.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: paquetes incluidos en la app'**
  String get marketOfflineBundled;

  /// No description provided for @marketAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get marketAll;

  /// No description provided for @marketTemplates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas'**
  String get marketTemplates;

  /// No description provided for @marketPalettes.
  ///
  /// In es, this message translates to:
  /// **'Paletas'**
  String get marketPalettes;

  /// No description provided for @marketStickers.
  ///
  /// In es, this message translates to:
  /// **'Stickers'**
  String get marketStickers;

  /// No description provided for @marketPalette.
  ///
  /// In es, this message translates to:
  /// **'Paleta'**
  String get marketPalette;

  /// No description provided for @marketNoResults.
  ///
  /// In es, this message translates to:
  /// **'No hay paquetes que coincidan'**
  String get marketNoResults;

  /// No description provided for @marketRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get marketRemove;

  /// No description provided for @marketInstall.
  ///
  /// In es, this message translates to:
  /// **'Instalar'**
  String get marketInstall;

  /// No description provided for @marketUninstalled.
  ///
  /// In es, this message translates to:
  /// **'«{name}» desinstalado'**
  String marketUninstalled(String name);

  /// No description provided for @marketInstalled.
  ///
  /// In es, this message translates to:
  /// **'«{name}» instalado: {where}'**
  String marketInstalled(String name, String where);

  /// No description provided for @marketInstallFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo instalar «{name}»: {error}'**
  String marketInstallFailed(String name, String error);

  /// No description provided for @createTplBlank.
  ///
  /// In es, this message translates to:
  /// **'Blanco'**
  String get createTplBlank;

  /// No description provided for @createTplRuled.
  ///
  /// In es, this message translates to:
  /// **'Rayas'**
  String get createTplRuled;

  /// No description provided for @createTplGrid.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula'**
  String get createTplGrid;

  /// No description provided for @createTplDots.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get createTplDots;

  /// No description provided for @createTplMusic.
  ///
  /// In es, this message translates to:
  /// **'Pentagrama'**
  String get createTplMusic;

  /// No description provided for @createTplPlanner.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get createTplPlanner;

  /// No description provided for @createTplHabit.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get createTplHabit;

  /// No description provided for @createTplSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja A4'**
  String get createTplSheet;

  /// No description provided for @createTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cuaderno'**
  String get createTitle;

  /// No description provided for @createName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get createName;

  /// No description provided for @createNameHint.
  ///
  /// In es, this message translates to:
  /// **'Mi cuaderno'**
  String get createNameHint;

  /// No description provided for @createCover.
  ///
  /// In es, this message translates to:
  /// **'Portada'**
  String get createCover;

  /// No description provided for @createDesign.
  ///
  /// In es, this message translates to:
  /// **'Diseño'**
  String get createDesign;

  /// No description provided for @createYourImage.
  ///
  /// In es, this message translates to:
  /// **'Tu imagen'**
  String get createYourImage;

  /// No description provided for @createChangeImage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get createChangeImage;

  /// No description provided for @createColor.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get createColor;

  /// No description provided for @createNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get createNext;

  /// No description provided for @createStep2.
  ///
  /// In es, this message translates to:
  /// **'Paso 2: Elige una plantilla'**
  String get createStep2;

  /// No description provided for @createBackToStep1.
  ///
  /// In es, this message translates to:
  /// **'Volver al paso 1'**
  String get createBackToStep1;

  /// No description provided for @createTemplate.
  ///
  /// In es, this message translates to:
  /// **'Plantilla'**
  String get createTemplate;

  /// No description provided for @createMoreTemplates.
  ///
  /// In es, this message translates to:
  /// **'Ver más plantillas'**
  String get createMoreTemplates;

  /// No description provided for @createFewer.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get createFewer;

  /// No description provided for @createInfinite.
  ///
  /// In es, this message translates to:
  /// **'Lienzo infinito'**
  String get createInfinite;

  /// No description provided for @createInfiniteOn.
  ///
  /// In es, this message translates to:
  /// **'El lienzo se alarga al escribir'**
  String get createInfiniteOn;

  /// No description provided for @createInfiniteOff.
  ///
  /// In es, this message translates to:
  /// **'Hoja de tamaño fijo (A4)'**
  String get createInfiniteOff;

  /// No description provided for @createAction.
  ///
  /// In es, this message translates to:
  /// **'Crear cuaderno'**
  String get createAction;

  /// No description provided for @createDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno {n}'**
  String createDefaultName(int n);

  /// No description provided for @createCoverSemantics.
  ///
  /// In es, this message translates to:
  /// **'Portada {name}'**
  String createCoverSemantics(String name);

  /// No description provided for @libRenameTitle.
  ///
  /// In es, this message translates to:
  /// **'Renombrar cuaderno'**
  String get libRenameTitle;

  /// No description provided for @libDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuaderno'**
  String get libDeleteTitle;

  /// No description provided for @libDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get libDelete;

  /// No description provided for @libCoverColor.
  ///
  /// In es, this message translates to:
  /// **'Color de portada'**
  String get libCoverColor;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @libSortTitle.
  ///
  /// In es, this message translates to:
  /// **'Ordenar cuadernos'**
  String get libSortTitle;

  /// No description provided for @libSortNewestFirst.
  ///
  /// In es, this message translates to:
  /// **'Más recientes primero'**
  String get libSortNewestFirst;

  /// No description provided for @libSortOldestFirst.
  ///
  /// In es, this message translates to:
  /// **'Más antiguos primero'**
  String get libSortOldestFirst;

  /// No description provided for @libSortTitleAZ.
  ///
  /// In es, this message translates to:
  /// **'Título A → Z'**
  String get libSortTitleAZ;

  /// No description provided for @libSortTitleZA.
  ///
  /// In es, this message translates to:
  /// **'Título Z → A'**
  String get libSortTitleZA;

  /// No description provided for @libNavAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get libNavAll;

  /// No description provided for @libNavRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get libNavRecent;

  /// No description provided for @libNavFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get libNavFavorites;

  /// No description provided for @libNavFolders.
  ///
  /// In es, this message translates to:
  /// **'Carpetas'**
  String get libNavFolders;

  /// No description provided for @libImport.
  ///
  /// In es, this message translates to:
  /// **'Importar .inklus'**
  String get libImport;

  /// No description provided for @libTrash.
  ///
  /// In es, this message translates to:
  /// **'Papelera'**
  String get libTrash;

  /// No description provided for @libLightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo claro'**
  String get libLightMode;

  /// No description provided for @libDarkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get libDarkMode;

  /// No description provided for @libMoreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get libMoreOptions;

  /// No description provided for @libMyNotebooks.
  ///
  /// In es, this message translates to:
  /// **'Mis cuadernos'**
  String get libMyNotebooks;

  /// No description provided for @libClearFilter.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtro'**
  String get libClearFilter;

  /// No description provided for @libSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o etiqueta'**
  String get libSearchHint;

  /// No description provided for @libSearchInNotes.
  ///
  /// In es, this message translates to:
  /// **'Buscar dentro de las notas (texto y escritura)'**
  String get libSearchInNotes;

  /// No description provided for @libSearchContent.
  ///
  /// In es, this message translates to:
  /// **'En el contenido'**
  String get libSearchContent;

  /// No description provided for @libSortNewest.
  ///
  /// In es, this message translates to:
  /// **'Más recientes'**
  String get libSortNewest;

  /// No description provided for @libSortOldest.
  ///
  /// In es, this message translates to:
  /// **'Más antiguos'**
  String get libSortOldest;

  /// No description provided for @libSortNameAZ.
  ///
  /// In es, this message translates to:
  /// **'Nombre A–Z'**
  String get libSortNameAZ;

  /// No description provided for @libSortNameZA.
  ///
  /// In es, this message translates to:
  /// **'Nombre Z–A'**
  String get libSortNameZA;

  /// No description provided for @libGrid.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula'**
  String get libGrid;

  /// No description provided for @libList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get libList;

  /// No description provided for @libNoResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cuadernos'**
  String get libNoResults;

  /// No description provided for @libEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza a escribir'**
  String get libEmptyTitle;

  /// No description provided for @libNoResultsHint.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre o etiqueta.'**
  String get libNoResultsHint;

  /// No description provided for @libUnfavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get libUnfavorite;

  /// No description provided for @libFavorite.
  ///
  /// In es, this message translates to:
  /// **'Añadir a favoritos'**
  String get libFavorite;

  /// No description provided for @libRename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get libRename;

  /// No description provided for @libDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar'**
  String get libDuplicate;

  /// No description provided for @libCoverAndColor.
  ///
  /// In es, this message translates to:
  /// **'Portada y color'**
  String get libCoverAndColor;

  /// No description provided for @libTags.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get libTags;

  /// No description provided for @libSyncOff.
  ///
  /// In es, this message translates to:
  /// **'Dejar de sincronizar con Drive'**
  String get libSyncOff;

  /// No description provided for @libMoveToTrash.
  ///
  /// In es, this message translates to:
  /// **'Mover a la papelera'**
  String get libMoveToTrash;

  /// No description provided for @libNotebookOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones del cuaderno'**
  String get libNotebookOptions;

  /// No description provided for @libSyncWillSync.
  ///
  /// In es, this message translates to:
  /// **'«{title}» se sincronizará con Drive'**
  String libSyncWillSync(String title);

  /// No description provided for @libSyncStopped.
  ///
  /// In es, this message translates to:
  /// **'«{title}» ya no se sincroniza'**
  String libSyncStopped(String title);

  /// No description provided for @libDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se enviará \"{title}\" a la papelera. Podrás recuperarlo desde ahí.'**
  String libDeleteBody(String title);

  /// No description provided for @libImportError.
  ///
  /// In es, this message translates to:
  /// **'Error al importar: {error}'**
  String libImportError(String error);

  /// No description provided for @libCountAll.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{1 cuaderno} other{{total} cuadernos}}'**
  String libCountAll(int total);

  /// No description provided for @libCountOf.
  ///
  /// In es, this message translates to:
  /// **'{shown} de {total} cuadernos'**
  String libCountOf(int shown, int total);

  /// No description provided for @libNotebookSemantics.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno {title}, {when}'**
  String libNotebookSemantics(String title, String when);

  /// No description provided for @libEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Crea un cuaderno nuevo o importa uno existente\\npara comenzar.'**
  String get libEmptyHint;

  /// No description provided for @noteRenameTitle.
  ///
  /// In es, this message translates to:
  /// **'Renombrar nota'**
  String get noteRenameTitle;

  /// No description provided for @noteDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar nota'**
  String get noteDeleteTitle;

  /// No description provided for @noteNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get noteNew;

  /// No description provided for @noteNameHint.
  ///
  /// In es, this message translates to:
  /// **'Mi nota'**
  String get noteNameHint;

  /// No description provided for @noteCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get noteCreate;

  /// No description provided for @noteEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get noteEmptyTitle;

  /// No description provided for @noteEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera nota para empezar a escribir.'**
  String get noteEmptyHint;

  /// No description provided for @noteCreateAction.
  ///
  /// In es, this message translates to:
  /// **'Crear nota'**
  String get noteCreateAction;

  /// No description provided for @noteOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get noteOptions;

  /// No description provided for @timeNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get timeNow;

  /// No description provided for @noteTplInfinite.
  ///
  /// In es, this message translates to:
  /// **'Infinito'**
  String get noteTplInfinite;

  /// No description provided for @noteTplSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja fija'**
  String get noteTplSheet;

  /// No description provided for @noteTplPlanner.
  ///
  /// In es, this message translates to:
  /// **'Planificador'**
  String get noteTplPlanner;

  /// No description provided for @tplInfiniteHint.
  ///
  /// In es, this message translates to:
  /// **'Infinitas se alargan al escribir'**
  String get tplInfiniteHint;

  /// No description provided for @tplNormalSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja normal'**
  String get tplNormalSheet;

  /// No description provided for @tplOwn.
  ///
  /// In es, this message translates to:
  /// **'Plantilla propia'**
  String get tplOwn;

  /// No description provided for @tplFromMarket.
  ///
  /// In es, this message translates to:
  /// **'Del marketplace'**
  String get tplFromMarket;

  /// No description provided for @tplMine.
  ///
  /// In es, this message translates to:
  /// **'Mis plantillas'**
  String get tplMine;

  /// No description provided for @tplSaveCurrent.
  ///
  /// In es, this message translates to:
  /// **'Guardar actual'**
  String get tplSaveCurrent;

  /// No description provided for @tplCustomize.
  ///
  /// In es, this message translates to:
  /// **'Personalizar'**
  String get tplCustomize;

  /// No description provided for @tplLineColor.
  ///
  /// In es, this message translates to:
  /// **'Color de línea'**
  String get tplLineColor;

  /// No description provided for @tplSpacing.
  ///
  /// In es, this message translates to:
  /// **'Separación'**
  String get tplSpacing;

  /// No description provided for @tplFixedSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja de tamaño fijo'**
  String get tplFixedSheet;

  /// No description provided for @tplSheetSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de hoja'**
  String get tplSheetSize;

  /// No description provided for @tplLetter.
  ///
  /// In es, this message translates to:
  /// **'Carta'**
  String get tplLetter;

  /// No description provided for @tplHowTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo usar la plantilla?'**
  String get tplHowTitle;

  /// No description provided for @tplHowBody.
  ///
  /// In es, this message translates to:
  /// **'La imagen se usará como fondo para escribir encima.'**
  String get tplHowBody;

  /// No description provided for @tplAsSheet.
  ///
  /// In es, this message translates to:
  /// **'Como hoja fija'**
  String get tplAsSheet;

  /// No description provided for @tplAsFill.
  ///
  /// In es, this message translates to:
  /// **'Relleno infinito'**
  String get tplAsFill;

  /// No description provided for @tplOnlyImage.
  ///
  /// In es, this message translates to:
  /// **'Solo se pueden guardar plantillas con imagen'**
  String get tplOnlyImage;

  /// No description provided for @tplSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar plantilla'**
  String get tplSaveTitle;

  /// No description provided for @tplDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Mi plantilla'**
  String get tplDefaultName;

  /// No description provided for @tplSaved.
  ///
  /// In es, this message translates to:
  /// **'Plantilla guardada'**
  String get tplSaved;

  /// No description provided for @tplDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar plantilla'**
  String get tplDeleteTitle;

  /// No description provided for @tplDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta plantilla guardada?'**
  String get tplDeleteBody;

  /// No description provided for @colorCustomTitle.
  ///
  /// In es, this message translates to:
  /// **'Color personalizado'**
  String get colorCustomTitle;

  /// No description provided for @colorCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get colorCurrent;

  /// No description provided for @colorNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get colorNew;

  /// No description provided for @colorWheel.
  ///
  /// In es, this message translates to:
  /// **'Rueda'**
  String get colorWheel;

  /// No description provided for @colorHue.
  ///
  /// In es, this message translates to:
  /// **'Matiz'**
  String get colorHue;

  /// No description provided for @colorSaturation.
  ///
  /// In es, this message translates to:
  /// **'Saturación'**
  String get colorSaturation;

  /// No description provided for @colorBrightness.
  ///
  /// In es, this message translates to:
  /// **'Brillo'**
  String get colorBrightness;

  /// No description provided for @colorUse.
  ///
  /// In es, this message translates to:
  /// **'Usar'**
  String get colorUse;

  /// No description provided for @timeMinAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {n} min'**
  String timeMinAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {n} h'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {n} d'**
  String timeDaysAgo(int n);

  /// No description provided for @timeDeletedNow.
  ///
  /// In es, this message translates to:
  /// **'eliminado ahora'**
  String get timeDeletedNow;

  /// No description provided for @timeDeletedMin.
  ///
  /// In es, this message translates to:
  /// **'eliminado hace {n} min'**
  String timeDeletedMin(int n);

  /// No description provided for @timeDeletedHours.
  ///
  /// In es, this message translates to:
  /// **'eliminado hace {n} h'**
  String timeDeletedHours(int n);

  /// No description provided for @timeDeletedDays.
  ///
  /// In es, this message translates to:
  /// **'eliminado hace {n} días'**
  String timeDeletedDays(int n);

  /// No description provided for @timeDeletedOn.
  ///
  /// In es, this message translates to:
  /// **'eliminado {date}'**
  String timeDeletedOn(String date);

  /// No description provided for @noteDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{title}\" de este cuaderno.'**
  String noteDeleteBody(String title);

  /// No description provided for @noteDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Nota {n}'**
  String noteDefaultName(int n);

  /// No description provided for @noteCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota} other{{count} notas}}'**
  String noteCount(int count);

  /// No description provided for @notePageCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 página} other{{count} páginas}} · {when}'**
  String notePageCount(int count, String when);

  /// No description provided for @tplImageLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen: {error}'**
  String tplImageLoadFailed(String error);

  /// No description provided for @tplSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String tplSaveFailed(String error);

  /// No description provided for @colorSliders.
  ///
  /// In es, this message translates to:
  /// **'Sliders'**
  String get colorSliders;

  /// No description provided for @selPaste.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get selPaste;

  /// No description provided for @selCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get selCopy;

  /// No description provided for @selCopied.
  ///
  /// In es, this message translates to:
  /// **'Copiado'**
  String get selCopied;

  /// No description provided for @selThinner.
  ///
  /// In es, this message translates to:
  /// **'Más fino'**
  String get selThinner;

  /// No description provided for @selThicker.
  ///
  /// In es, this message translates to:
  /// **'Más grueso'**
  String get selThicker;

  /// No description provided for @selToText.
  ///
  /// In es, this message translates to:
  /// **'Convertir a texto'**
  String get selToText;

  /// No description provided for @selDeselect.
  ///
  /// In es, this message translates to:
  /// **'Deseleccionar'**
  String get selDeselect;

  /// No description provided for @selNoText.
  ///
  /// In es, this message translates to:
  /// **'No se reconoció texto en la selección'**
  String get selNoText;

  /// No description provided for @selConvert.
  ///
  /// In es, this message translates to:
  /// **'Convertir'**
  String get selConvert;

  /// No description provided for @popPenType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de pluma'**
  String get popPenType;

  /// No description provided for @popThickness.
  ///
  /// In es, this message translates to:
  /// **'Grosor'**
  String get popThickness;

  /// No description provided for @popStraighten.
  ///
  /// In es, this message translates to:
  /// **'Enderezar figuras'**
  String get popStraighten;

  /// No description provided for @popNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get popNo;

  /// No description provided for @popOnHold.
  ///
  /// In es, this message translates to:
  /// **'Al mantener'**
  String get popOnHold;

  /// No description provided for @popAlways.
  ///
  /// In es, this message translates to:
  /// **'Siempre'**
  String get popAlways;

  /// No description provided for @popShapeOffHint.
  ///
  /// In es, this message translates to:
  /// **'Los trazos quedan tal cual.'**
  String get popShapeOffHint;

  /// No description provided for @popShapeHoldHint.
  ///
  /// In es, this message translates to:
  /// **'Deja el lápiz quieto medio segundo al terminar una línea, círculo, triángulo o rectángulo.'**
  String get popShapeHoldHint;

  /// No description provided for @popShapeAlwaysHint.
  ///
  /// In es, this message translates to:
  /// **'Toda figura reconocible se endereza al soltar.'**
  String get popShapeAlwaysHint;

  /// No description provided for @popAdvanced.
  ///
  /// In es, this message translates to:
  /// **'Ajustes avanzados del trazo'**
  String get popAdvanced;

  /// No description provided for @popMode.
  ///
  /// In es, this message translates to:
  /// **'Modo'**
  String get popMode;

  /// No description provided for @popPartial.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get popPartial;

  /// No description provided for @popStroke.
  ///
  /// In es, this message translates to:
  /// **'Trazo'**
  String get popStroke;

  /// No description provided for @popHighlighter.
  ///
  /// In es, this message translates to:
  /// **'Resaltador'**
  String get popHighlighter;

  /// No description provided for @popEraseOff.
  ///
  /// In es, this message translates to:
  /// **'Borra solo lo que tocas, como una goma.'**
  String get popEraseOff;

  /// No description provided for @popEraseStroke.
  ///
  /// In es, this message translates to:
  /// **'Borra el trazo entero al tocarlo.'**
  String get popEraseStroke;

  /// No description provided for @popEraseHighlighter.
  ///
  /// In es, this message translates to:
  /// **'Solo borra resaltador; la tinta no se toca.'**
  String get popEraseHighlighter;

  /// No description provided for @popSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get popSize;

  /// No description provided for @tbBackToLibrary.
  ///
  /// In es, this message translates to:
  /// **'Volver a la biblioteca'**
  String get tbBackToLibrary;

  /// No description provided for @tbHidePages.
  ///
  /// In es, this message translates to:
  /// **'Ocultar páginas'**
  String get tbHidePages;

  /// No description provided for @tbPages.
  ///
  /// In es, this message translates to:
  /// **'Páginas'**
  String get tbPages;

  /// No description provided for @tbHideLayers.
  ///
  /// In es, this message translates to:
  /// **'Ocultar capas'**
  String get tbHideLayers;

  /// No description provided for @tbLayers.
  ///
  /// In es, this message translates to:
  /// **'Capas'**
  String get tbLayers;

  /// No description provided for @tbInsertImage.
  ///
  /// In es, this message translates to:
  /// **'Insertar imagen'**
  String get tbInsertImage;

  /// No description provided for @tbRuler.
  ///
  /// In es, this message translates to:
  /// **'Regla'**
  String get tbRuler;

  /// No description provided for @tbRulerNext.
  ///
  /// In es, this message translates to:
  /// **'Regla (toca: transportador)'**
  String get tbRulerNext;

  /// No description provided for @tbProtractorNext.
  ///
  /// In es, this message translates to:
  /// **'Transportador (toca: ocultar)'**
  String get tbProtractorNext;

  /// No description provided for @tbMoveSelect.
  ///
  /// In es, this message translates to:
  /// **'Mover / seleccionar imágenes y trazos'**
  String get tbMoveSelect;

  /// No description provided for @tbFill.
  ///
  /// In es, this message translates to:
  /// **'Rellenar área'**
  String get tbFill;

  /// No description provided for @tbHideMagnifier.
  ///
  /// In es, this message translates to:
  /// **'Ocultar lupa'**
  String get tbHideMagnifier;

  /// No description provided for @tbMagnifier.
  ///
  /// In es, this message translates to:
  /// **'Lupa'**
  String get tbMagnifier;

  /// No description provided for @tbLaserOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivar puntero láser'**
  String get tbLaserOff;

  /// No description provided for @tbLaser.
  ///
  /// In es, this message translates to:
  /// **'Puntero láser'**
  String get tbLaser;

  /// No description provided for @tbInsertSticker.
  ///
  /// In es, this message translates to:
  /// **'Insertar sticker'**
  String get tbInsertSticker;

  /// No description provided for @tbPageTemplate.
  ///
  /// In es, this message translates to:
  /// **'Plantilla de la página'**
  String get tbPageTemplate;

  /// No description provided for @tbMoreTools.
  ///
  /// In es, this message translates to:
  /// **'Más herramientas'**
  String get tbMoreTools;

  /// No description provided for @tbUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get tbUndo;

  /// No description provided for @tbRedo.
  ///
  /// In es, this message translates to:
  /// **'Rehacer'**
  String get tbRedo;

  /// No description provided for @pgUnbookmark.
  ///
  /// In es, this message translates to:
  /// **'Quitar marcador'**
  String get pgUnbookmark;

  /// No description provided for @pgBookmark.
  ///
  /// In es, this message translates to:
  /// **'Marcar página'**
  String get pgBookmark;

  /// No description provided for @pgShowAll.
  ///
  /// In es, this message translates to:
  /// **'Mostrar todas'**
  String get pgShowAll;

  /// No description provided for @pgOnlyBookmarked.
  ///
  /// In es, this message translates to:
  /// **'Solo marcadas'**
  String get pgOnlyBookmarked;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @pgOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de la página'**
  String get pgOptions;

  /// No description provided for @pgNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva página'**
  String get pgNew;

  /// No description provided for @tagTitle.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas del cuaderno'**
  String get tagTitle;

  /// No description provided for @tagSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para encontrarlo y agruparlo en carpetas inteligentes'**
  String get tagSubtitle;

  /// No description provided for @tagActive.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas activas'**
  String get tagActive;

  /// No description provided for @tagOthers.
  ///
  /// In es, this message translates to:
  /// **'Otras etiquetas'**
  String get tagOthers;

  /// No description provided for @tagNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva etiqueta…'**
  String get tagNew;

  /// No description provided for @tagAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir etiqueta'**
  String get tagAdd;

  /// No description provided for @tagSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar etiquetas'**
  String get tagSave;

  /// No description provided for @trashDeleteForever.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get trashDeleteForever;

  /// No description provided for @trashEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Vaciar papelera'**
  String get trashEmptyTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In es, this message translates to:
  /// **'Vaciar'**
  String get trashEmpty;

  /// No description provided for @trashSubtitleEmpty.
  ///
  /// In es, this message translates to:
  /// **'Lo que elimines se guarda aquí 30 días'**
  String get trashSubtitleEmpty;

  /// No description provided for @trashEmptyState.
  ///
  /// In es, this message translates to:
  /// **'Papelera vacía'**
  String get trashEmptyState;

  /// No description provided for @trashLegacy.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno (formato antiguo)'**
  String get trashLegacy;

  /// No description provided for @trashNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get trashNote;

  /// No description provided for @trashReturn.
  ///
  /// In es, this message translates to:
  /// **'Devolver a su cuaderno'**
  String get trashReturn;

  /// No description provided for @strokeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Presión, suavizado y fluidez del trazo'**
  String get strokeSubtitle;

  /// No description provided for @strokeNone.
  ///
  /// In es, this message translates to:
  /// **'El borrador y la selección no tienen opciones de trazo.'**
  String get strokeNone;

  /// No description provided for @strokeQuickSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño rápido'**
  String get strokeQuickSize;

  /// No description provided for @strokePressure.
  ///
  /// In es, this message translates to:
  /// **'Variación con la presión'**
  String get strokePressure;

  /// No description provided for @strokePressureDesc.
  ///
  /// In es, this message translates to:
  /// **'Cuánto cambia el grosor al apretar'**
  String get strokePressureDesc;

  /// No description provided for @strokeSmoothing.
  ///
  /// In es, this message translates to:
  /// **'Suavizado'**
  String get strokeSmoothing;

  /// No description provided for @strokeSmoothingDesc.
  ///
  /// In es, this message translates to:
  /// **'Redondea las curvas del trazo'**
  String get strokeSmoothingDesc;

  /// No description provided for @strokeStabilizer.
  ///
  /// In es, this message translates to:
  /// **'Estabilizador'**
  String get strokeStabilizer;

  /// No description provided for @strokeStabilizerDesc.
  ///
  /// In es, this message translates to:
  /// **'Reduce el temblor del pulso'**
  String get strokeStabilizerDesc;

  /// No description provided for @sizeThin.
  ///
  /// In es, this message translates to:
  /// **'Fino'**
  String get sizeThin;

  /// No description provided for @sizeMedium.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get sizeMedium;

  /// No description provided for @sizeThick.
  ///
  /// In es, this message translates to:
  /// **'Grueso'**
  String get sizeThick;

  /// No description provided for @sizeExtra.
  ///
  /// In es, this message translates to:
  /// **'Extra'**
  String get sizeExtra;

  /// No description provided for @sizeSmall.
  ///
  /// In es, this message translates to:
  /// **'Pequeño'**
  String get sizeSmall;

  /// No description provided for @sizeLarge.
  ///
  /// In es, this message translates to:
  /// **'Grande'**
  String get sizeLarge;

  /// No description provided for @toolPen.
  ///
  /// In es, this message translates to:
  /// **'Bolígrafo'**
  String get toolPen;

  /// No description provided for @toolPencil.
  ///
  /// In es, this message translates to:
  /// **'Lápiz'**
  String get toolPencil;

  /// No description provided for @toolCalligraphy.
  ///
  /// In es, this message translates to:
  /// **'Pluma caligráfica'**
  String get toolCalligraphy;

  /// No description provided for @toolBrush.
  ///
  /// In es, this message translates to:
  /// **'Pincel'**
  String get toolBrush;

  /// No description provided for @toolMarker.
  ///
  /// In es, this message translates to:
  /// **'Marcador'**
  String get toolMarker;

  /// No description provided for @toolSpray.
  ///
  /// In es, this message translates to:
  /// **'Aerosol'**
  String get toolSpray;

  /// No description provided for @toolEraser.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get toolEraser;

  /// No description provided for @toolSelect.
  ///
  /// In es, this message translates to:
  /// **'Mover / seleccionar'**
  String get toolSelect;

  /// No description provided for @toolLasso.
  ///
  /// In es, this message translates to:
  /// **'Lazo'**
  String get toolLasso;

  /// No description provided for @toolFill.
  ///
  /// In es, this message translates to:
  /// **'Rellenar'**
  String get toolFill;

  /// No description provided for @toolText.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get toolText;

  /// No description provided for @selRecognizeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reconocer: {error}'**
  String selRecognizeFailed(String error);

  /// No description provided for @tbPenSlot.
  ///
  /// In es, this message translates to:
  /// **'{tool} {n}'**
  String tbPenSlot(String tool, int n);

  /// No description provided for @tbPageOf.
  ///
  /// In es, this message translates to:
  /// **'Pág. {n} de {total}'**
  String tbPageOf(int n, int total);

  /// No description provided for @pgPagesCount.
  ///
  /// In es, this message translates to:
  /// **'Páginas ({n})'**
  String pgPagesCount(int n);

  /// No description provided for @strokeOptionsOf.
  ///
  /// In es, this message translates to:
  /// **'Opciones de {tool}'**
  String strokeOptionsOf(String tool);

  /// No description provided for @trashRestoredMsg.
  ///
  /// In es, this message translates to:
  /// **'\"{title}\" restaurado'**
  String trashRestoredMsg(String title);

  /// No description provided for @trashPurgeBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{title}\" permanentemente. Esta acción no se puede deshacer.'**
  String trashPurgeBody(String title);

  /// No description provided for @trashEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán permanentemente {count, plural, =1{1 elemento} other{{count} elementos}}. Esta acción no se puede deshacer.'**
  String trashEmptyBody(int count);

  /// No description provided for @trashSubtitleCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 elemento} other{{count} elementos}} · se borran solos a los 30 días'**
  String trashSubtitleCount(int count);

  /// No description provided for @trashEmptyStateBody.
  ///
  /// In es, this message translates to:
  /// **'Los cuadernos y notas que elimines se guardarán aquí durante 30 días antes de borrarse definitivamente.'**
  String get trashEmptyStateBody;

  /// No description provided for @trashNotebookKind.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno · {count, plural, =1{1 nota} other{{count} notas}}'**
  String trashNotebookKind(int count);

  /// No description provided for @trashNoteOf.
  ///
  /// In es, this message translates to:
  /// **'Nota de «{title}»'**
  String trashNoteOf(String title);

  /// No description provided for @trashLeftTomorrow.
  ///
  /// In es, this message translates to:
  /// **'se borra mañana'**
  String get trashLeftTomorrow;

  /// No description provided for @trashLeftDays.
  ///
  /// In es, this message translates to:
  /// **'quedan {n} días'**
  String trashLeftDays(int n);

  /// No description provided for @trashInfoLine.
  ///
  /// In es, this message translates to:
  /// **'{what} · {deleted} · {left}'**
  String trashInfoLine(String what, String deleted, String left);

  /// No description provided for @edLayerLocked.
  ///
  /// In es, this message translates to:
  /// **'Capa bloqueada — desbloquea para editar'**
  String get edLayerLocked;

  /// No description provided for @expTitle.
  ///
  /// In es, this message translates to:
  /// **'Opciones de exportación'**
  String get expTitle;

  /// No description provided for @expLow.
  ///
  /// In es, this message translates to:
  /// **'Baja (1024 px)'**
  String get expLow;

  /// No description provided for @expMedium.
  ///
  /// In es, this message translates to:
  /// **'Media (2048 px)'**
  String get expMedium;

  /// No description provided for @expHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta (4096 px)'**
  String get expHigh;

  /// No description provided for @expMax.
  ///
  /// In es, this message translates to:
  /// **'Máxima (8192 px)'**
  String get expMax;

  /// No description provided for @expTransparent.
  ///
  /// In es, this message translates to:
  /// **'Fondo transparente'**
  String get expTransparent;

  /// No description provided for @expTransparentHint.
  ///
  /// In es, this message translates to:
  /// **'Sin plantilla ni papel'**
  String get expTransparentHint;

  /// No description provided for @expStrokesOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo trazos'**
  String get expStrokesOnly;

  /// No description provided for @expStrokesOnlyHint.
  ///
  /// In es, this message translates to:
  /// **'Sin imágenes ni plantilla'**
  String get expStrokesOnlyHint;

  /// No description provided for @expExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get expExport;

  /// No description provided for @ocrUnsupported.
  ///
  /// In es, this message translates to:
  /// **'OCR solo está disponible en Android e iOS'**
  String get ocrUnsupported;

  /// No description provided for @ocrWorking.
  ///
  /// In es, this message translates to:
  /// **'Reconociendo texto…'**
  String get ocrWorking;

  /// No description provided for @ocrNoText.
  ///
  /// In es, this message translates to:
  /// **'No se reconoció texto en esta página'**
  String get ocrNoText;

  /// No description provided for @ocrResultTitle.
  ///
  /// In es, this message translates to:
  /// **'Texto reconocido'**
  String get ocrResultTitle;

  /// No description provided for @ocrCopied.
  ///
  /// In es, this message translates to:
  /// **'Texto copiado al portapapeles'**
  String get ocrCopied;

  /// No description provided for @edGoogleAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Google'**
  String get edGoogleAccount;

  /// No description provided for @edSyncedCloud.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado con la nube'**
  String get edSyncedCloud;

  /// No description provided for @edRestoreCloud.
  ///
  /// In es, this message translates to:
  /// **'Restaurar desde la nube'**
  String get edRestoreCloud;

  /// No description provided for @edRestoreCloudHint.
  ///
  /// In es, this message translates to:
  /// **'Última versión (last-write-wins)'**
  String get edRestoreCloudHint;

  /// No description provided for @edDriveVersions.
  ///
  /// In es, this message translates to:
  /// **'Ver versiones en Drive'**
  String get edDriveVersions;

  /// No description provided for @edUploadInklus.
  ///
  /// In es, this message translates to:
  /// **'Subir archivo .inklus'**
  String get edUploadInklus;

  /// No description provided for @edSyncOnForNotebook.
  ///
  /// In es, this message translates to:
  /// **'Sync: activada para este cuaderno'**
  String get edSyncOnForNotebook;

  /// No description provided for @edSyncOffForNotebook.
  ///
  /// In es, this message translates to:
  /// **'Sync: desactivada para este cuaderno'**
  String get edSyncOffForNotebook;

  /// No description provided for @edSyncDisabledMsg.
  ///
  /// In es, this message translates to:
  /// **'Sync desactivada para este cuaderno'**
  String get edSyncDisabledMsg;

  /// No description provided for @edSyncEnabledMsg.
  ///
  /// In es, this message translates to:
  /// **'Sync activada para este cuaderno'**
  String get edSyncEnabledMsg;

  /// No description provided for @edNoteSynced.
  ///
  /// In es, this message translates to:
  /// **'Nota sincronizada con Google Drive'**
  String get edNoteSynced;

  /// No description provided for @edPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña (dejar vacío si no está cifrado)'**
  String get edPasswordHint;

  /// No description provided for @edNoCloudCopy.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ninguna copia de esta nota en Google Drive'**
  String get edNoCloudCopy;

  /// No description provided for @edNoteRestored.
  ///
  /// In es, this message translates to:
  /// **'Nota restaurada desde Google Drive'**
  String get edNoteRestored;

  /// No description provided for @edIsFullBackup.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo es un respaldo completo, no un cuaderno .inklus'**
  String get edIsFullBackup;

  /// No description provided for @edNoPassword.
  ///
  /// In es, this message translates to:
  /// **'Sin contraseña'**
  String get edNoPassword;

  /// No description provided for @edNotebookTitle.
  ///
  /// In es, this message translates to:
  /// **'Título del cuaderno'**
  String get edNotebookTitle;

  /// No description provided for @pdfUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Importar PDF por ahora solo está disponible en Android/iOS'**
  String get pdfUnsupported;

  /// No description provided for @pdfReadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el PDF'**
  String get pdfReadFailed;

  /// No description provided for @verRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar versión'**
  String get verRestoreTitle;

  /// No description provided for @verRestored.
  ///
  /// In es, this message translates to:
  /// **'Versión restaurada'**
  String get verRestored;

  /// No description provided for @verEncrypted.
  ///
  /// In es, this message translates to:
  /// **'Copia cifrada'**
  String get verEncrypted;

  /// No description provided for @verPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña de la copia'**
  String get verPasswordHint;

  /// No description provided for @verDecrypt.
  ///
  /// In es, this message translates to:
  /// **'Descifrar'**
  String get verDecrypt;

  /// No description provided for @inkUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Reconocer escritura solo está disponible en Android e iOS'**
  String get inkUnsupported;

  /// No description provided for @edDeleteImage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get edDeleteImage;

  /// No description provided for @edExitPresent.
  ///
  /// In es, this message translates to:
  /// **'Salir de presentación'**
  String get edExitPresent;

  /// No description provided for @edLaserOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivar láser'**
  String get edLaserOff;

  /// No description provided for @edGoToPage.
  ///
  /// In es, this message translates to:
  /// **'Ir a página'**
  String get edGoToPage;

  /// No description provided for @edGo.
  ///
  /// In es, this message translates to:
  /// **'Ir'**
  String get edGo;

  /// No description provided for @edNoStickers.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes stickers instalados.'**
  String get edNoStickers;

  /// No description provided for @edOpenMarket.
  ///
  /// In es, this message translates to:
  /// **'Abrir el marketplace'**
  String get edOpenMarket;

  /// No description provided for @edSyncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get edSyncing;

  /// No description provided for @edSyncToDrive.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar con Google Drive'**
  String get edSyncToDrive;

  /// No description provided for @edSynced.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado'**
  String get edSynced;

  /// No description provided for @edSyncError.
  ///
  /// In es, this message translates to:
  /// **'Error de sincronización'**
  String get edSyncError;

  /// No description provided for @menuPagePng.
  ///
  /// In es, this message translates to:
  /// **'Página como imagen (PNG)'**
  String get menuPagePng;

  /// No description provided for @menuPagePdf.
  ///
  /// In es, this message translates to:
  /// **'Página como PDF'**
  String get menuPagePdf;

  /// No description provided for @menuNotePdf.
  ///
  /// In es, this message translates to:
  /// **'Nota completa (PDF)'**
  String get menuNotePdf;

  /// No description provided for @menuStrokesSvg.
  ///
  /// In es, this message translates to:
  /// **'Trazos (SVG)'**
  String get menuStrokesSvg;

  /// No description provided for @menuPptx.
  ///
  /// In es, this message translates to:
  /// **'Presentación (PowerPoint)'**
  String get menuPptx;

  /// No description provided for @menuInklusCopy.
  ///
  /// In es, this message translates to:
  /// **'Copia .inklus'**
  String get menuInklusCopy;

  /// No description provided for @menuShareImage.
  ///
  /// In es, this message translates to:
  /// **'Compartir imagen'**
  String get menuShareImage;

  /// No description provided for @menuSharePdf.
  ///
  /// In es, this message translates to:
  /// **'Compartir PDF'**
  String get menuSharePdf;

  /// No description provided for @menuShareInklus.
  ///
  /// In es, this message translates to:
  /// **'Compartir .inklus'**
  String get menuShareInklus;

  /// No description provided for @menuExportShare.
  ///
  /// In es, this message translates to:
  /// **'Exportar y compartir'**
  String get menuExportShare;

  /// No description provided for @menuTemplate.
  ///
  /// In es, this message translates to:
  /// **'Plantilla…'**
  String get menuTemplate;

  /// No description provided for @menuGoToPage.
  ///
  /// In es, this message translates to:
  /// **'Ir a página…'**
  String get menuGoToPage;

  /// No description provided for @menuImportPdf.
  ///
  /// In es, this message translates to:
  /// **'Importar PDF para anotar'**
  String get menuImportPdf;

  /// No description provided for @menuClearPage.
  ///
  /// In es, this message translates to:
  /// **'Limpiar página'**
  String get menuClearPage;

  /// No description provided for @menuPage.
  ///
  /// In es, this message translates to:
  /// **'Página'**
  String get menuPage;

  /// No description provided for @menuSearchNote.
  ///
  /// In es, this message translates to:
  /// **'Buscar en la nota'**
  String get menuSearchNote;

  /// No description provided for @menuIndexInk.
  ///
  /// In es, this message translates to:
  /// **'Indexar escritura (para buscarla)'**
  String get menuIndexInk;

  /// No description provided for @menuIndexInkUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Indexar escritura (solo Android/iOS)'**
  String get menuIndexInkUnsupported;

  /// No description provided for @menuOcr.
  ///
  /// In es, this message translates to:
  /// **'Reconocer texto (OCR)'**
  String get menuOcr;

  /// No description provided for @menuOcrUnsupported.
  ///
  /// In es, this message translates to:
  /// **'OCR (solo Android/iOS)'**
  String get menuOcrUnsupported;

  /// No description provided for @menuVersions.
  ///
  /// In es, this message translates to:
  /// **'Historial de versiones'**
  String get menuVersions;

  /// No description provided for @menuReminder.
  ///
  /// In es, this message translates to:
  /// **'Crear recordatorio'**
  String get menuReminder;

  /// No description provided for @menuNightOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivar modo nocturno'**
  String get menuNightOff;

  /// No description provided for @menuNightOn.
  ///
  /// In es, this message translates to:
  /// **'Modo nocturno de escritura'**
  String get menuNightOn;

  /// No description provided for @menuPresent.
  ///
  /// In es, this message translates to:
  /// **'Modo presentación'**
  String get menuPresent;

  /// No description provided for @menuHapticsOn.
  ///
  /// In es, this message translates to:
  /// **'Vibración al escribir: sí'**
  String get menuHapticsOn;

  /// No description provided for @menuHapticsOff.
  ///
  /// In es, this message translates to:
  /// **'Vibración al escribir: no'**
  String get menuHapticsOff;

  /// No description provided for @menuContinuousScroll.
  ///
  /// In es, this message translates to:
  /// **'Desplazamiento continuo entre hojas'**
  String get menuContinuousScroll;

  /// No description provided for @menuView.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get menuView;

  /// No description provided for @menuBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo completo'**
  String get menuBackup;

  /// No description provided for @menuRestoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Importar .inklus o respaldo'**
  String get menuRestoreBackup;

  /// No description provided for @menuData.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get menuData;

  /// No description provided for @menuStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de escritura'**
  String get menuStats;

  /// No description provided for @clearPageBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará todo el contenido de la página. Puedes deshacerlo después.'**
  String get clearPageBody;

  /// No description provided for @clearPageAction.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clearPageAction;

  /// No description provided for @pgPrev.
  ///
  /// In es, this message translates to:
  /// **'Página anterior'**
  String get pgPrev;

  /// No description provided for @pgNext.
  ///
  /// In es, this message translates to:
  /// **'Página siguiente'**
  String get pgNext;

  /// No description provided for @zoomOut.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get zoomOut;

  /// No description provided for @zoomFit.
  ///
  /// In es, this message translates to:
  /// **'Ajustar a la vista'**
  String get zoomFit;

  /// No description provided for @zoomIn.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get zoomIn;

  /// No description provided for @shareTextPage.
  ///
  /// In es, this message translates to:
  /// **'Página de Inklus'**
  String get shareTextPage;

  /// No description provided for @shareTextNotebook.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno de Inklus'**
  String get shareTextNotebook;

  /// No description provided for @edInsertImageFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo insertar la imagen: {error}'**
  String edInsertImageFailed(String error);

  /// No description provided for @expSvgFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar SVG: {error}'**
  String expSvgFailed(String error);

  /// No description provided for @ocrFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al reconocer texto: {error}'**
  String ocrFailed(String error);

  /// No description provided for @expFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar: {error}'**
  String expFailed(String error);

  /// No description provided for @expPreview.
  ///
  /// In es, this message translates to:
  /// **'Previsualización: {name}'**
  String expPreview(String name);

  /// No description provided for @expSaveDialog.
  ///
  /// In es, this message translates to:
  /// **'Guardar {name}'**
  String expSaveDialog(String name);

  /// No description provided for @expDone.
  ///
  /// In es, this message translates to:
  /// **'Exportado: {path}'**
  String expDone(String path);

  /// No description provided for @expSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el archivo: {error}'**
  String expSaveFailed(String error);

  /// No description provided for @shareFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al compartir: {error}'**
  String shareFailed(String error);

  /// No description provided for @edSignInIncomplete.
  ///
  /// In es, this message translates to:
  /// **'No se completó el inicio de sesión. Detalle: {detail}'**
  String edSignInIncomplete(String detail);

  /// No description provided for @uploadFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al subir: {error}'**
  String uploadFailed(String error);

  /// No description provided for @restoreFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar: {error}'**
  String restoreFailed(String error);

  /// No description provided for @edFileUploaded.
  ///
  /// In es, this message translates to:
  /// **'Archivo \"{name}\" subido a Google Drive'**
  String edFileUploaded(String name);

  /// No description provided for @pdfImported.
  ///
  /// In es, this message translates to:
  /// **'PDF importado: {count, plural, =1{1 página} other{{count} páginas}} para anotar'**
  String pdfImported(int count);

  /// No description provided for @pdfImportFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al importar PDF: {error}'**
  String pdfImportFailed(String error);

  /// No description provided for @verRestoreBody.
  ///
  /// In es, this message translates to:
  /// **'La nota volverá a como estaba el {date}.\\n\\nEl estado actual se guarda antes como una versión local, así que puedes deshacer la restauración desde este mismo historial.'**
  String verRestoreBody(String date);

  /// No description provided for @verRestoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar la versión: {error}'**
  String verRestoreFailed(String error);

  /// No description provided for @pptxFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar PowerPoint: {error}'**
  String pptxFailed(String error);

  /// No description provided for @reminderCreated.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio creado para {date} a las {time}'**
  String reminderCreated(String date, String time);

  /// No description provided for @inkIndexed.
  ///
  /// In es, this message translates to:
  /// **'Escritura indexada en {count, plural, =1{1 página} other{{count} páginas}}: ya puedes buscarla'**
  String inkIndexed(int count);

  /// No description provided for @inkFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reconocer la escritura: {error}'**
  String inkFailed(String error);

  /// No description provided for @backupFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar respaldo: {error}'**
  String backupFailed(String error);

  /// No description provided for @importDoneOpen.
  ///
  /// In es, this message translates to:
  /// **'{message}. Ábrelo desde la biblioteca.'**
  String importDoneOpen(String message);

  /// No description provided for @noteHasPages.
  ///
  /// In es, this message translates to:
  /// **'La nota tiene {count, plural, =1{1 página} other{{count} páginas}}'**
  String noteHasPages(int count);

  /// No description provided for @stickerInsertFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo insertar el sticker: {error}'**
  String stickerInsertFailed(String error);

  /// No description provided for @remNoNotebooks.
  ///
  /// In es, this message translates to:
  /// **'No hay cuadernos para vincular'**
  String get remNoNotebooks;

  /// No description provided for @remPickNotebook.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar cuaderno'**
  String get remPickNotebook;

  /// No description provided for @remPickHint.
  ///
  /// In es, this message translates to:
  /// **'El recordatorio abrirá este cuaderno'**
  String get remPickHint;

  /// No description provided for @remCreated.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio creado'**
  String get remCreated;

  /// No description provided for @remMessageTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensaje del recordatorio'**
  String get remMessageTitle;

  /// No description provided for @remMessageHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Revisar apuntes de clase'**
  String get remMessageHint;

  /// No description provided for @remNoMessage.
  ///
  /// In es, this message translates to:
  /// **'Sin mensaje'**
  String get remNoMessage;

  /// No description provided for @remTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get remTitle;

  /// No description provided for @remSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos vinculados a tus cuadernos'**
  String get remSubtitle;

  /// No description provided for @remEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorios'**
  String get remEmptyTitle;

  /// No description provided for @remPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get remPending;

  /// No description provided for @remDone.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get remDone;

  /// No description provided for @statsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statsTitle;

  /// No description provided for @statsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu actividad de escritura en este dispositivo'**
  String get statsSubtitle;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin datos todavía'**
  String get statsEmptyTitle;

  /// No description provided for @statsStrokes.
  ///
  /// In es, this message translates to:
  /// **'Trazos'**
  String get statsStrokes;

  /// No description provided for @statsMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get statsMinutes;

  /// No description provided for @statsActiveDays.
  ///
  /// In es, this message translates to:
  /// **'Días activos'**
  String get statsActiveDays;

  /// No description provided for @statsStreaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get statsStreaks;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get statsCurrentStreak;

  /// No description provided for @statsRecord.
  ///
  /// In es, this message translates to:
  /// **'Récord'**
  String get statsRecord;

  /// No description provided for @statsActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad — últimos 30 días'**
  String get statsActivity;

  /// No description provided for @statsDaysWithPages.
  ///
  /// In es, this message translates to:
  /// **'Días con páginas nuevas'**
  String get statsDaysWithPages;

  /// No description provided for @smartTitle.
  ///
  /// In es, this message translates to:
  /// **'Carpetas inteligentes'**
  String get smartTitle;

  /// No description provided for @smartSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Organiza tus cuadernos automáticamente'**
  String get smartSubtitle;

  /// No description provided for @smartByColor.
  ///
  /// In es, this message translates to:
  /// **'Por color'**
  String get smartByColor;

  /// No description provided for @smartByTag.
  ///
  /// In es, this message translates to:
  /// **'Por etiqueta'**
  String get smartByTag;

  /// No description provided for @onbSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onbSkip;

  /// No description provided for @onbStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get onbStart;

  /// No description provided for @onb1Title.
  ///
  /// In es, this message translates to:
  /// **'Escribe con tu lápiz'**
  String get onb1Title;

  /// No description provided for @onb2Title.
  ///
  /// In es, this message translates to:
  /// **'Muévete con los dedos'**
  String get onb2Title;

  /// No description provided for @onb3Title.
  ///
  /// In es, this message translates to:
  /// **'Herramientas arriba'**
  String get onb3Title;

  /// No description provided for @onb4Title.
  ///
  /// In es, this message translates to:
  /// **'Tus notas son tuyas'**
  String get onb4Title;

  /// No description provided for @layerAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir capa'**
  String get layerAdd;

  /// No description provided for @layerRename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar capa'**
  String get layerRename;

  /// No description provided for @verSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Al restaurar, el estado actual se guarda antes'**
  String get verSubtitle;

  /// No description provided for @verOnDevice.
  ///
  /// In es, this message translates to:
  /// **'En este dispositivo'**
  String get verOnDevice;

  /// No description provided for @verNoLocal.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay copias locales de esta nota.'**
  String get verNoLocal;

  /// No description provided for @verOnDrive.
  ///
  /// In es, this message translates to:
  /// **'En Google Drive'**
  String get verOnDrive;

  /// No description provided for @verNotUploaded.
  ///
  /// In es, this message translates to:
  /// **'Esta nota aún no se ha subido a Drive.'**
  String get verNotUploaded;

  /// No description provided for @smartThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get smartThisWeek;

  /// No description provided for @smartNoTags.
  ///
  /// In es, this message translates to:
  /// **'Sin etiquetas'**
  String get smartNoTags;

  /// No description provided for @smartOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get smartOther;

  /// No description provided for @colorNone.
  ///
  /// In es, this message translates to:
  /// **'Sin color'**
  String get colorNone;

  /// No description provided for @colorBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get colorGreen;

  /// No description provided for @colorRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In es, this message translates to:
  /// **'Naranja'**
  String get colorOrange;

  /// No description provided for @colorPurple.
  ///
  /// In es, this message translates to:
  /// **'Morado'**
  String get colorPurple;

  /// No description provided for @colorPink.
  ///
  /// In es, this message translates to:
  /// **'Rosa'**
  String get colorPink;

  /// No description provided for @colorTurquoise.
  ///
  /// In es, this message translates to:
  /// **'Turquesa'**
  String get colorTurquoise;

  /// No description provided for @colorGray.
  ///
  /// In es, this message translates to:
  /// **'Gris'**
  String get colorGray;

  /// No description provided for @onb1Body.
  ///
  /// In es, this message translates to:
  /// **'Apoya la mano sin miedo: Inklus reconoce el lápiz y descarta la palma. La goma del lápiz o el botón lateral borran.'**
  String get onb1Body;

  /// No description provided for @onb2Body.
  ///
  /// In es, this message translates to:
  /// **'Con el lápiz, un dedo desplaza la página y dos dedos acercan o alejan. Puedes volver a dibujar con el dedo desde la barra.'**
  String get onb2Body;

  /// No description provided for @onb3Body.
  ///
  /// In es, this message translates to:
  /// **'Toca una herramienta para usarla y tócala otra vez para ver sus opciones: grosor, color, borrador parcial, figuras…'**
  String get onb3Body;

  /// No description provided for @onb4Body.
  ///
  /// In es, this message translates to:
  /// **'Todo se guarda en este dispositivo, sin cuentas ni anuncios. Si quieres, puedes hacer copia en tu Google Drive.'**
  String get onb4Body;

  /// No description provided for @remEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Crea recordatorios vinculados a tus cuadernos para no olvidar nada.'**
  String get remEmptyBody;

  /// No description provided for @statsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Empieza a escribir en tus cuadernos y tus estadísticas aparecerán aquí.'**
  String get statsEmptyBody;

  /// No description provided for @remOverdue.
  ///
  /// In es, this message translates to:
  /// **' · vencido'**
  String get remOverdue;

  /// No description provided for @statsDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String statsDays(int count);

  /// No description provided for @statsDayTooltip.
  ///
  /// In es, this message translates to:
  /// **'{date}: {strokes} trazos, {pages} páginas'**
  String statsDayTooltip(String date, int strokes, int pages);

  /// No description provided for @searchInNote.
  ///
  /// In es, this message translates to:
  /// **'Buscar en esta nota'**
  String get searchInNote;

  /// No description provided for @searchInAll.
  ///
  /// In es, this message translates to:
  /// **'Buscar en todas las notas'**
  String get searchInAll;

  /// No description provided for @searchPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar'**
  String get searchPrompt;

  /// No description provided for @searchMatches.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 coincidencia} other{{count} coincidencias}}'**
  String searchMatches(int count);

  /// No description provided for @searchInfo.
  ///
  /// In es, this message translates to:
  /// **'Incluye cajas de texto y la escritura a mano ya reconocida (menú Nota → Indexar escritura).'**
  String get searchInfo;

  /// No description provided for @searchTitleMatch.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get searchTitleMatch;

  /// No description provided for @pgDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar página'**
  String get pgDuplicate;

  /// No description provided for @pgDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar página'**
  String get pgDelete;

  /// No description provided for @verDriveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo consultar Drive: {error}'**
  String verDriveFailed(String error);

  /// No description provided for @colorSemantics.
  ///
  /// In es, this message translates to:
  /// **'Color #{hex}'**
  String colorSemantics(String hex);

  /// No description provided for @errNotInklus.
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un cuaderno .inklus ni un respaldo de Inklus.'**
  String get errNotInklus;

  /// No description provided for @errNotInklusFile.
  ///
  /// In es, this message translates to:
  /// **'No es un cuaderno .inklus válido'**
  String get errNotInklusFile;

  /// No description provided for @errNotInklusV2.
  ///
  /// In es, this message translates to:
  /// **'No es un cuaderno .inklus v2 válido'**
  String get errNotInklusV2;

  /// No description provided for @errCatalogTooLarge.
  ///
  /// In es, this message translates to:
  /// **'Catálogo demasiado grande'**
  String get errCatalogTooLarge;

  /// No description provided for @errCatalogVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de catálogo no soportada: {version}'**
  String errCatalogVersion(String version);

  /// No description provided for @errOcrUnsupported.
  ///
  /// In es, this message translates to:
  /// **'OCR solo está disponible en Android e iOS.'**
  String get errOcrUnsupported;

  /// No description provided for @errNotSignedIn.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con Google primero.'**
  String get errNotSignedIn;

  /// No description provided for @errEncrypted.
  ///
  /// In es, this message translates to:
  /// **'La copia está cifrada: hace falta la contraseña'**
  String get errEncrypted;

  /// No description provided for @driveConfigBody.
  ///
  /// In es, this message translates to:
  /// **'Error de configuración de Google (clientConfigurationError).\\n\\nCausa probable: la SHA-1 de la firma de esta app no está registrada en Google Cloud Console para el paquete com.inklus.inklus.\\n\\nSolución:\\n1. Ve a Google Cloud Console → APIs y servicios → Credenciales\\n2. Crea o edita el ID de cliente OAuth de Android con el paquete com.inklus.inklus y la SHA-1 de tu firma\\n3. Habilita Google Sign-In en la pantalla de consentimiento\\n\\nError original: {details}'**
  String driveConfigBody(String details);

  /// No description provided for @noticeStylus.
  ///
  /// In es, this message translates to:
  /// **'Lápiz detectado: ahora el dedo desplaza la página (actívalo en la barra si quieres dibujar con el dedo)'**
  String get noticeStylus;

  /// No description provided for @noticePageDeleted.
  ///
  /// In es, this message translates to:
  /// **'Página eliminada'**
  String get noticePageDeleted;

  /// No description provided for @noticeFileUploaded.
  ///
  /// In es, this message translates to:
  /// **'Archivo subido a Google Drive'**
  String get noticeFileUploaded;

  /// No description provided for @importBackupRestored.
  ///
  /// In es, this message translates to:
  /// **'Respaldo restaurado: {count, plural, =1{1 cuaderno} other{{count} cuadernos}}'**
  String importBackupRestored(int count);

  /// No description provided for @importNotebookDone.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno \"{title}\" importado ({count, plural, =1{1 nota} other{{count} notas}})'**
  String importNotebookDone(String title, int count);

  /// No description provided for @importNotebookSimple.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno \"{title}\" importado'**
  String importNotebookSimple(String title);

  /// No description provided for @driveRestoreNone.
  ///
  /// In es, this message translates to:
  /// **'No hay copias de Inklus en tu Google Drive'**
  String get driveRestoreNone;

  /// No description provided for @driveRestoreUpToDate.
  ///
  /// In es, this message translates to:
  /// **'Todo está al día: nada que restaurar'**
  String get driveRestoreUpToDate;

  /// No description provided for @driveRestoreUpdated.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota actualizada} other{{count} notas actualizadas}}'**
  String driveRestoreUpdated(int count);

  /// No description provided for @driveRestoreAdded.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 recuperada} other{{count} recuperadas}}'**
  String driveRestoreAdded(int count);

  /// No description provided for @driveRecovered.
  ///
  /// In es, this message translates to:
  /// **'Recuperado de Drive'**
  String get driveRecovered;

  /// No description provided for @packClassicName.
  ///
  /// In es, this message translates to:
  /// **'Cuadernos clásicos'**
  String get packClassicName;

  /// No description provided for @packClassicDesc.
  ///
  /// In es, this message translates to:
  /// **'Rayado ancho y estrecho, cuadrícula de 5 mm, puntos y pentagrama.'**
  String get packClassicDesc;

  /// No description provided for @packTechName.
  ///
  /// In es, this message translates to:
  /// **'Papel técnico'**
  String get packTechName;

  /// No description provided for @packTechDesc.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula fina tipo milimetrado y agenda por columnas, en tonos suaves.'**
  String get packTechDesc;

  /// No description provided for @packStudyName.
  ///
  /// In es, this message translates to:
  /// **'Paleta Estudio'**
  String get packStudyName;

  /// No description provided for @packStudyDesc.
  ///
  /// In es, this message translates to:
  /// **'Tinta azul y negra, rojo de corrección, verde y naranja para destacar.'**
  String get packStudyDesc;

  /// No description provided for @packPastelName.
  ///
  /// In es, this message translates to:
  /// **'Paleta Pastel'**
  String get packPastelName;

  /// No description provided for @packPastelDesc.
  ///
  /// In es, this message translates to:
  /// **'Tonos suaves para apuntes bonitos y diagramas.'**
  String get packPastelDesc;

  /// No description provided for @packEarthName.
  ///
  /// In es, this message translates to:
  /// **'Paleta Tierra'**
  String get packEarthName;

  /// No description provided for @packEarthDesc.
  ///
  /// In es, this message translates to:
  /// **'Ocres, oliva y terracota, con buen contraste sobre papel.'**
  String get packEarthDesc;

  /// No description provided for @coverSimple.
  ///
  /// In es, this message translates to:
  /// **'Degradado'**
  String get coverSimple;

  /// No description provided for @coverClassic.
  ///
  /// In es, this message translates to:
  /// **'Clásico'**
  String get coverClassic;

  /// No description provided for @coverAurora.
  ///
  /// In es, this message translates to:
  /// **'Aurora'**
  String get coverAurora;

  /// No description provided for @coverWaves.
  ///
  /// In es, this message translates to:
  /// **'Olas'**
  String get coverWaves;

  /// No description provided for @coverGeometric.
  ///
  /// In es, this message translates to:
  /// **'Geométrico'**
  String get coverGeometric;

  /// No description provided for @coverSun.
  ///
  /// In es, this message translates to:
  /// **'Sol'**
  String get coverSun;

  /// No description provided for @coverDots.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get coverDots;

  /// No description provided for @coverLines.
  ///
  /// In es, this message translates to:
  /// **'Rayas'**
  String get coverLines;

  /// No description provided for @untitled.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get untitled;

  /// No description provided for @defaultNotebookTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi cuaderno'**
  String get defaultNotebookTitle;

  /// No description provided for @createFromFile.
  ///
  /// In es, this message translates to:
  /// **'O empieza desde un archivo'**
  String get createFromFile;

  /// No description provided for @createFromFileHint.
  ///
  /// In es, this message translates to:
  /// **'Sube un PDF o fotos y escribe encima de cada página.'**
  String get createFromFileHint;

  /// No description provided for @createFromPdf.
  ///
  /// In es, this message translates to:
  /// **'Desde un PDF'**
  String get createFromPdf;

  /// No description provided for @createFromImages.
  ///
  /// In es, this message translates to:
  /// **'Desde imágenes'**
  String get createFromImages;

  /// No description provided for @createFromFileRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar archivo'**
  String get createFromFileRemove;

  /// No description provided for @createFromFilePages.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 página} other{{count} páginas}}'**
  String createFromFilePages(int count);
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
