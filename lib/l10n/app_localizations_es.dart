// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonRestore => 'Restaurar';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String settingsSubtitle(String version) {
    return 'Inklus $version · tus notas se guardan en este dispositivo';
  }

  @override
  String get settingsSectionDrive => 'Google Drive';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionFiles => 'Copias y archivos';

  @override
  String get settingsSectionTools => 'Herramientas';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsImportTitle => 'Importar .inklus o respaldo';

  @override
  String get settingsImportSubtitle =>
      'Un cuaderno (.inklus) o un respaldo completo (.zip); se reconoce solo';

  @override
  String get settingsExportTitle => 'Exportar respaldo completo';

  @override
  String get settingsExportSubtitle =>
      'Todos los cuadernos, imágenes y papelera en un .zip';

  @override
  String get settingsAutosaveTitle => 'Guardado automático';

  @override
  String get settingsAutosaveSubtitle =>
      'Cada cambio se guarda al instante en este dispositivo. Al abrir y cerrar una nota se guarda una versión (menú ⋮ → Historial de versiones).';

  @override
  String get settingsStatsTitle => 'Estadísticas de escritura';

  @override
  String get settingsStatsSubtitle => 'Trazos, páginas, rachas y actividad';

  @override
  String get settingsRemindersTitle => 'Recordatorios';

  @override
  String get settingsRemindersSubtitle => 'Avisos vinculados a tus cuadernos';

  @override
  String get settingsTrashTitle => 'Papelera';

  @override
  String get settingsTrashSubtitle => 'Recupera cuadernos y notas eliminados';

  @override
  String get settingsAppTagline => 'Escritura a mano para tablets con lápiz';

  @override
  String get settingsFreeTitle => 'Libre y gratuito';

  @override
  String get settingsFreeSubtitle =>
      'Código abierto (GPL-3.0). Sin funciones de pago, sin anuncios y sin analítica.';

  @override
  String get settingsPrivacyTitle => 'Política de privacidad';

  @override
  String get settingsPrivacySubtitle => 'Qué datos maneja la app y adónde van';

  @override
  String get settingsSourceTitle => 'Código fuente';

  @override
  String get settingsSourceSubtitle =>
      'Informa de un fallo o sugiere mejoras en GitHub';

  @override
  String get settingsErrorLogTitle => 'Registro de errores';

  @override
  String get settingsErrorLogSubtitle =>
      'Se guarda solo en este dispositivo; puedes compartirlo para ayudar a corregir un fallo';

  @override
  String get settingsErrorLogEmpty => 'No hay errores registrados';

  @override
  String settingsErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores registrados',
      one: '1 error registrado',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorLogShareSubtitle =>
      'Por correo o en un issue de GitHub';

  @override
  String get settingsErrorLogClear => 'Borrar registro';

  @override
  String get settingsErrorLogCleared => 'Registro borrado';

  @override
  String settingsErrorLogSubject(String version) {
    return 'Registro de errores de Inklus $version';
  }

  @override
  String settingsOpenFailed(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get driveConnected => 'Conectado';

  @override
  String get driveCloudCopy => 'Copia en la nube';

  @override
  String get driveGoogleAccount => 'Cuenta de Google';

  @override
  String get driveOptionalPitch =>
      'Opcional: guarda una copia de tus notas en tu Google Drive';

  @override
  String get driveConnect => 'Conectar';

  @override
  String get driveUploadNow => 'Subir ahora';

  @override
  String get driveUploadNowSubtitle =>
      'Sube las notas de los cuadernos con sincronización activa';

  @override
  String get driveRestore => 'Restaurar desde Drive';

  @override
  String get driveRestoreSubtitle =>
      'Trae las versiones más recientes y recupera las notas que no estén en este dispositivo';

  @override
  String get driveNoteVersions => 'Versiones de una nota';

  @override
  String get driveNoteVersionsSubtitle =>
      'En el editor: ⋮ → Historial de versiones';

  @override
  String get driveSwitchAccount => 'Cambiar de cuenta';

  @override
  String get driveSignOut => 'Cerrar sesión';

  @override
  String get driveAccount => 'Cuenta';

  @override
  String driveConnectedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get driveNotConfigured => 'Google no está configurado';

  @override
  String get driveSignOutQuestion => '¿Cerrar sesión?';

  @override
  String get driveSignOutBody =>
      'Dejarán de subirse copias a Google Drive. Las copias que ya están en Drive no se borran.';

  @override
  String get driveSignedOut => 'Sesión cerrada';

  @override
  String driveUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas subidas a Drive',
      one: '1 nota subida a Drive',
      zero: 'No hay cuadernos con sincronización activa',
    );
    return '$_temp0';
  }

  @override
  String get driveRestoreBody =>
      'Las notas de este dispositivo se reemplazan solo si la copia de Drive es más reciente. Las que no existan aquí se guardan en un cuaderno nuevo \"Recuperado de Drive\".';

  @override
  String get backupSaveTitle => 'Guardar respaldo de Inklus';

  @override
  String get backupSaved => 'Respaldo guardado';
}
