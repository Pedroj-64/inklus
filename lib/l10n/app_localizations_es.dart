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
      'Las notas de este dispositivo se reemplazan solo si la copia de Drive es más reciente. Las que no existan aquí vuelven a su cuaderno (o a uno nuevo \"Recuperado de Drive\").';

  @override
  String get backupSaveTitle => 'Guardar respaldo de Inklus';

  @override
  String get backupSaved => 'Respaldo guardado';

  @override
  String get driveSignInIncomplete => 'No se completó el inicio de sesión';

  @override
  String get driveDetails => 'Detalles';

  @override
  String get driveSignInHelpTitle => 'No se pudo iniciar sesión';

  @override
  String driveSignInHelpBody(String details) {
    return 'Si cerraste el selector de cuentas, no pasa nada. Si elegiste una cuenta y no se conectó, casi siempre es que la firma de esta app (SHA-1) no está registrada en Google Cloud para com.inklus.inklus.\n\nDetalle técnico:\n$details';
  }

  @override
  String get driveNotebooksTitle => 'Cuadernos que se sincronizan';

  @override
  String get driveNotebooksSubtitle =>
      'Cada cuaderno se guarda en Drive → Inklus → su carpeta. Elige cuáles.';

  @override
  String get driveNotebooksEmpty => 'Aún no hay cuadernos.';

  @override
  String get driveSyncMenu => 'Sincronizar con Drive';

  @override
  String get driveSyncEnabled => 'Sincronización activada';

  @override
  String get driveSyncDisabled => 'Sincronización desactivada';

  @override
  String get textEditHint => 'Escribe aquí…';

  @override
  String get textEditMove => 'Mover caja';

  @override
  String get textEditWidth => 'Ancho de la caja';

  @override
  String get textEditSmaller => 'Más pequeño';

  @override
  String get textEditLarger => 'Más grande';

  @override
  String get textEditBold => 'Negrita';

  @override
  String get textEditItalic => 'Cursiva';

  @override
  String get textEditUnderline => 'Subrayado';

  @override
  String get textEditStrike => 'Tachado';

  @override
  String get textEditColor => 'Color del texto';

  @override
  String get textEditHighlight => 'Resaltar';

  @override
  String get textEditAlign => 'Alineación';

  @override
  String get textEditSpacing => 'Interlineado';

  @override
  String get textEditLinkActive => 'Enlace a página (activo)';

  @override
  String get textEditLink => 'Vincular a página';

  @override
  String get textEditDelete => 'Eliminar caja';

  @override
  String get textEditDone => 'Listo';

  @override
  String get textEditWholeBox => 'Toda la caja';

  @override
  String get textEditNoHighlight => 'Sin resaltado';

  @override
  String get textEditUnlink => 'Quitar enlace';

  @override
  String commonPageN(int n) {
    return 'Página $n';
  }

  @override
  String get marketWhereTemplate => 'en Plantilla de la página';

  @override
  String get marketWherePalette => 'en los colores de cada pluma';

  @override
  String get marketWhereStickers => 'en Más herramientas → Insertar sticker';

  @override
  String get marketHeroTitle => 'Descubre y personaliza';

  @override
  String get marketHeroSubtitle =>
      'Plantillas, paletas y stickers de la comunidad. Gratis y de licencia libre.';

  @override
  String get marketSearch => 'Buscar paquetes';

  @override
  String get marketTitle => 'Marketplace';

  @override
  String get marketOfflineCache => 'Sin conexión: último catálogo descargado';

  @override
  String get marketOfflineBundled =>
      'Sin conexión: paquetes incluidos en la app';

  @override
  String get marketAll => 'Todo';

  @override
  String get marketTemplates => 'Plantillas';

  @override
  String get marketPalettes => 'Paletas';

  @override
  String get marketStickers => 'Stickers';

  @override
  String get marketPalette => 'Paleta';

  @override
  String get marketNoResults => 'No hay paquetes que coincidan';

  @override
  String get marketRemove => 'Quitar';

  @override
  String get marketInstall => 'Instalar';

  @override
  String marketUninstalled(String name) {
    return '«$name» desinstalado';
  }

  @override
  String marketInstalled(String name, String where) {
    return '«$name» instalado: $where';
  }

  @override
  String marketInstallFailed(String name, String error) {
    return 'No se pudo instalar «$name»: $error';
  }

  @override
  String get createTplBlank => 'Blanco';

  @override
  String get createTplRuled => 'Rayas';

  @override
  String get createTplGrid => 'Cuadrícula';

  @override
  String get createTplDots => 'Puntos';

  @override
  String get createTplMusic => 'Pentagrama';

  @override
  String get createTplPlanner => 'Agenda';

  @override
  String get createTplHabit => 'Hábitos';

  @override
  String get createTplSheet => 'Hoja A4';

  @override
  String get createTitle => 'Nuevo cuaderno';

  @override
  String get createName => 'Nombre';

  @override
  String get createNameHint => 'Mi cuaderno';

  @override
  String get createCover => 'Portada';

  @override
  String get createDesign => 'Diseño';

  @override
  String get createYourImage => 'Tu imagen';

  @override
  String get createChangeImage => 'Cambiar imagen';

  @override
  String get createColor => 'Color';

  @override
  String get createNext => 'Siguiente';

  @override
  String get createStep2 => 'Paso 2: Elige una plantilla';

  @override
  String get createBackToStep1 => 'Volver al paso 1';

  @override
  String get createTemplate => 'Plantilla';

  @override
  String get createMoreTemplates => 'Ver más plantillas';

  @override
  String get createFewer => 'Ver menos';

  @override
  String get createInfinite => 'Lienzo infinito';

  @override
  String get createInfiniteOn => 'El lienzo se alarga al escribir';

  @override
  String get createInfiniteOff => 'Hoja de tamaño fijo (A4)';

  @override
  String get createAction => 'Crear cuaderno';

  @override
  String createDefaultName(int n) {
    return 'Cuaderno $n';
  }

  @override
  String createCoverSemantics(String name) {
    return 'Portada $name';
  }

  @override
  String get libRenameTitle => 'Renombrar cuaderno';

  @override
  String get libDeleteTitle => 'Eliminar cuaderno';

  @override
  String get libDelete => 'Eliminar';

  @override
  String get libCoverColor => 'Color de portada';

  @override
  String get commonSave => 'Guardar';

  @override
  String get libSortTitle => 'Ordenar cuadernos';

  @override
  String get libSortNewestFirst => 'Más recientes primero';

  @override
  String get libSortOldestFirst => 'Más antiguos primero';

  @override
  String get libSortTitleAZ => 'Título A → Z';

  @override
  String get libSortTitleZA => 'Título Z → A';

  @override
  String get libNavAll => 'Todos';

  @override
  String get libNavRecent => 'Recientes';

  @override
  String get libNavFavorites => 'Favoritos';

  @override
  String get libNavFolders => 'Carpetas';

  @override
  String get libImport => 'Importar .inklus';

  @override
  String get libTrash => 'Papelera';

  @override
  String get libLightMode => 'Modo claro';

  @override
  String get libDarkMode => 'Modo oscuro';

  @override
  String get libMoreOptions => 'Más opciones';

  @override
  String get libMyNotebooks => 'Mis cuadernos';

  @override
  String get libClearFilter => 'Quitar filtro';

  @override
  String get libSearchHint => 'Buscar por nombre o etiqueta';

  @override
  String get libSearchInNotes =>
      'Buscar dentro de las notas (texto y escritura)';

  @override
  String get libSearchContent => 'En el contenido';

  @override
  String get libSortNewest => 'Más recientes';

  @override
  String get libSortOldest => 'Más antiguos';

  @override
  String get libSortNameAZ => 'Nombre A–Z';

  @override
  String get libSortNameZA => 'Nombre Z–A';

  @override
  String get libGrid => 'Cuadrícula';

  @override
  String get libList => 'Lista';

  @override
  String get libNoResults => 'No se encontraron cuadernos';

  @override
  String get libEmptyTitle => 'Empieza a escribir';

  @override
  String get libNoResultsHint => 'Prueba con otro nombre o etiqueta.';

  @override
  String get libUnfavorite => 'Quitar de favoritos';

  @override
  String get libFavorite => 'Añadir a favoritos';

  @override
  String get libRename => 'Renombrar';

  @override
  String get libDuplicate => 'Duplicar';

  @override
  String get libCoverAndColor => 'Portada y color';

  @override
  String get libTags => 'Etiquetas';

  @override
  String get libSyncOff => 'Dejar de sincronizar con Drive';

  @override
  String get libMoveToTrash => 'Mover a la papelera';

  @override
  String get libNotebookOptions => 'Opciones del cuaderno';

  @override
  String libSyncWillSync(String title) {
    return '«$title» se sincronizará con Drive';
  }

  @override
  String libSyncStopped(String title) {
    return '«$title» ya no se sincroniza';
  }

  @override
  String libDeleteBody(String title) {
    return 'Se enviará \"$title\" a la papelera. Podrás recuperarlo desde ahí.';
  }

  @override
  String libImportError(String error) {
    return 'Error al importar: $error';
  }

  @override
  String libCountAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total cuadernos',
      one: '1 cuaderno',
    );
    return '$_temp0';
  }

  @override
  String libCountOf(int shown, int total) {
    return '$shown de $total cuadernos';
  }

  @override
  String libNotebookSemantics(String title, String when) {
    return 'Cuaderno $title, $when';
  }

  @override
  String get libEmptyHint =>
      'Crea un cuaderno nuevo o importa uno existente\\npara comenzar.';

  @override
  String get noteRenameTitle => 'Renombrar nota';

  @override
  String get noteDeleteTitle => 'Eliminar nota';

  @override
  String get noteNew => 'Nueva nota';

  @override
  String get noteNameHint => 'Mi nota';

  @override
  String get noteCreate => 'Crear';

  @override
  String get noteEmptyTitle => 'Sin notas';

  @override
  String get noteEmptyHint => 'Crea tu primera nota para empezar a escribir.';

  @override
  String get noteCreateAction => 'Crear nota';

  @override
  String get noteOptions => 'Opciones';

  @override
  String get timeNow => 'ahora';

  @override
  String get noteTplInfinite => 'Infinito';

  @override
  String get noteTplSheet => 'Hoja fija';

  @override
  String get noteTplPlanner => 'Planificador';

  @override
  String get tplInfiniteHint => 'Infinitas se alargan al escribir';

  @override
  String get tplNormalSheet => 'Hoja normal';

  @override
  String get tplOwn => 'Plantilla propia';

  @override
  String get tplFromMarket => 'Del marketplace';

  @override
  String get tplMine => 'Mis plantillas';

  @override
  String get tplSaveCurrent => 'Guardar actual';

  @override
  String get tplCustomize => 'Personalizar';

  @override
  String get tplLineColor => 'Color de línea';

  @override
  String get tplSpacing => 'Separación';

  @override
  String get tplFixedSheet => 'Hoja de tamaño fijo';

  @override
  String get tplSheetSize => 'Tamaño de hoja';

  @override
  String get tplLetter => 'Carta';

  @override
  String get tplHowTitle => '¿Cómo usar la plantilla?';

  @override
  String get tplHowBody =>
      'La imagen se usará como fondo para escribir encima.';

  @override
  String get tplAsSheet => 'Como hoja fija';

  @override
  String get tplAsFill => 'Relleno infinito';

  @override
  String get tplOnlyImage => 'Solo se pueden guardar plantillas con imagen';

  @override
  String get tplSaveTitle => 'Guardar plantilla';

  @override
  String get tplDefaultName => 'Mi plantilla';

  @override
  String get tplSaved => 'Plantilla guardada';

  @override
  String get tplDeleteTitle => 'Eliminar plantilla';

  @override
  String get tplDeleteBody => '¿Eliminar esta plantilla guardada?';

  @override
  String get colorCustomTitle => 'Color personalizado';

  @override
  String get colorCurrent => 'Actual';

  @override
  String get colorNew => 'Nuevo';

  @override
  String get colorWheel => 'Rueda';

  @override
  String get colorHue => 'Matiz';

  @override
  String get colorSaturation => 'Saturación';

  @override
  String get colorBrightness => 'Brillo';

  @override
  String get colorUse => 'Usar';

  @override
  String timeMinAgo(int n) {
    return 'hace $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'hace $n d';
  }

  @override
  String get timeDeletedNow => 'eliminado ahora';

  @override
  String timeDeletedMin(int n) {
    return 'eliminado hace $n min';
  }

  @override
  String timeDeletedHours(int n) {
    return 'eliminado hace $n h';
  }

  @override
  String timeDeletedDays(int n) {
    return 'eliminado hace $n días';
  }

  @override
  String timeDeletedOn(String date) {
    return 'eliminado $date';
  }

  @override
  String noteDeleteBody(String title) {
    return 'Se eliminará \"$title\" de este cuaderno.';
  }

  @override
  String noteDefaultName(int n) {
    return 'Nota $n';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String notePageCount(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0 · $when';
  }

  @override
  String tplImageLoadFailed(String error) {
    return 'No se pudo cargar la imagen: $error';
  }

  @override
  String tplSaveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get colorSliders => 'Sliders';

  @override
  String get selPaste => 'Pegar';

  @override
  String get selCopy => 'Copiar';

  @override
  String get selCopied => 'Copiado';

  @override
  String get selThinner => 'Más fino';

  @override
  String get selThicker => 'Más grueso';

  @override
  String get selToText => 'Convertir a texto';

  @override
  String get selDeselect => 'Deseleccionar';

  @override
  String get selNoText => 'No se reconoció texto en la selección';

  @override
  String get selConvert => 'Convertir';

  @override
  String get popPenType => 'Tipo de pluma';

  @override
  String get popThickness => 'Grosor';

  @override
  String get popStraighten => 'Enderezar figuras';

  @override
  String get popNo => 'No';

  @override
  String get popOnHold => 'Al mantener';

  @override
  String get popAlways => 'Siempre';

  @override
  String get popShapeOffHint => 'Los trazos quedan tal cual.';

  @override
  String get popShapeHoldHint =>
      'Deja el lápiz quieto medio segundo al terminar una línea, círculo, triángulo o rectángulo.';

  @override
  String get popShapeAlwaysHint =>
      'Toda figura reconocible se endereza al soltar.';

  @override
  String get popAdvanced => 'Ajustes avanzados del trazo';

  @override
  String get popMode => 'Modo';

  @override
  String get popPartial => 'Parcial';

  @override
  String get popStroke => 'Trazo';

  @override
  String get popHighlighter => 'Resaltador';

  @override
  String get popEraseOff => 'Borra solo lo que tocas, como una goma.';

  @override
  String get popEraseStroke => 'Borra el trazo entero al tocarlo.';

  @override
  String get popEraseHighlighter =>
      'Solo borra resaltador; la tinta no se toca.';

  @override
  String get popSize => 'Tamaño';

  @override
  String get tbBackToLibrary => 'Volver a la biblioteca';

  @override
  String get tbHidePages => 'Ocultar páginas';

  @override
  String get tbPages => 'Páginas';

  @override
  String get tbHideLayers => 'Ocultar capas';

  @override
  String get tbLayers => 'Capas';

  @override
  String get tbInsertImage => 'Insertar imagen';

  @override
  String get tbRuler => 'Regla';

  @override
  String get tbRulerNext => 'Regla (toca: transportador)';

  @override
  String get tbProtractorNext => 'Transportador (toca: ocultar)';

  @override
  String get tbMoveSelect => 'Mover / seleccionar imágenes y trazos';

  @override
  String get tbFill => 'Rellenar área';

  @override
  String get tbHideMagnifier => 'Ocultar lupa';

  @override
  String get tbMagnifier => 'Lupa';

  @override
  String get tbLaserOff => 'Desactivar puntero láser';

  @override
  String get tbLaser => 'Puntero láser';

  @override
  String get tbInsertSticker => 'Insertar sticker';

  @override
  String get tbPageTemplate => 'Plantilla de la página';

  @override
  String get tbMoreTools => 'Más herramientas';

  @override
  String get tbUndo => 'Deshacer';

  @override
  String get tbRedo => 'Rehacer';

  @override
  String get pgUnbookmark => 'Quitar marcador';

  @override
  String get pgBookmark => 'Marcar página';

  @override
  String get pgShowAll => 'Mostrar todas';

  @override
  String get pgOnlyBookmarked => 'Solo marcadas';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get pgOptions => 'Opciones de la página';

  @override
  String get pgNew => 'Nueva página';

  @override
  String get tagTitle => 'Etiquetas del cuaderno';

  @override
  String get tagSubtitle =>
      'Para encontrarlo y agruparlo en carpetas inteligentes';

  @override
  String get tagActive => 'Etiquetas activas';

  @override
  String get tagOthers => 'Otras etiquetas';

  @override
  String get tagNew => 'Nueva etiqueta…';

  @override
  String get tagAdd => 'Añadir etiqueta';

  @override
  String get tagSave => 'Guardar etiquetas';

  @override
  String get trashDeleteForever => 'Eliminar definitivamente';

  @override
  String get trashEmptyTitle => 'Vaciar papelera';

  @override
  String get trashEmpty => 'Vaciar';

  @override
  String get trashSubtitleEmpty => 'Lo que elimines se guarda aquí 30 días';

  @override
  String get trashEmptyState => 'Papelera vacía';

  @override
  String get trashLegacy => 'Cuaderno (formato antiguo)';

  @override
  String get trashNote => 'Nota';

  @override
  String get trashReturn => 'Devolver a su cuaderno';

  @override
  String get strokeSubtitle => 'Presión, suavizado y fluidez del trazo';

  @override
  String get strokeNone =>
      'El borrador y la selección no tienen opciones de trazo.';

  @override
  String get strokeQuickSize => 'Tamaño rápido';

  @override
  String get strokePressure => 'Variación con la presión';

  @override
  String get strokePressureDesc => 'Cuánto cambia el grosor al apretar';

  @override
  String get strokeSmoothing => 'Suavizado';

  @override
  String get strokeSmoothingDesc => 'Redondea las curvas del trazo';

  @override
  String get strokeStabilizer => 'Estabilizador';

  @override
  String get strokeStabilizerDesc => 'Reduce el temblor del pulso';

  @override
  String get sizeThin => 'Fino';

  @override
  String get sizeMedium => 'Medio';

  @override
  String get sizeThick => 'Grueso';

  @override
  String get sizeExtra => 'Extra';

  @override
  String get sizeSmall => 'Pequeño';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get toolPen => 'Bolígrafo';

  @override
  String get toolPencil => 'Lápiz';

  @override
  String get toolCalligraphy => 'Pluma caligráfica';

  @override
  String get toolBrush => 'Pincel';

  @override
  String get toolMarker => 'Marcador';

  @override
  String get toolSpray => 'Aerosol';

  @override
  String get toolEraser => 'Borrador';

  @override
  String get toolSelect => 'Mover / seleccionar';

  @override
  String get toolLasso => 'Lazo';

  @override
  String get toolFill => 'Rellenar';

  @override
  String get toolText => 'Texto';

  @override
  String selRecognizeFailed(String error) {
    return 'No se pudo reconocer: $error';
  }

  @override
  String tbPenSlot(String tool, int n) {
    return '$tool $n';
  }

  @override
  String tbPageOf(int n, int total) {
    return 'Pág. $n de $total';
  }

  @override
  String pgPagesCount(int n) {
    return 'Páginas ($n)';
  }

  @override
  String strokeOptionsOf(String tool) {
    return 'Opciones de $tool';
  }

  @override
  String trashRestoredMsg(String title) {
    return '\"$title\" restaurado';
  }

  @override
  String trashPurgeBody(String title) {
    return 'Se eliminará \"$title\" permanentemente. Esta acción no se puede deshacer.';
  }

  @override
  String trashEmptyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return 'Se eliminarán permanentemente $_temp0. Esta acción no se puede deshacer.';
  }

  @override
  String trashSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0 · se borran solos a los 30 días';
  }

  @override
  String get trashEmptyStateBody =>
      'Los cuadernos y notas que elimines se guardarán aquí durante 30 días antes de borrarse definitivamente.';

  @override
  String trashNotebookKind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return 'Cuaderno · $_temp0';
  }

  @override
  String trashNoteOf(String title) {
    return 'Nota de «$title»';
  }

  @override
  String get trashLeftTomorrow => 'se borra mañana';

  @override
  String trashLeftDays(int n) {
    return 'quedan $n días';
  }

  @override
  String trashInfoLine(String what, String deleted, String left) {
    return '$what · $deleted · $left';
  }

  @override
  String get edLayerLocked => 'Capa bloqueada — desbloquea para editar';

  @override
  String get expTitle => 'Opciones de exportación';

  @override
  String get expLow => 'Baja (1024 px)';

  @override
  String get expMedium => 'Media (2048 px)';

  @override
  String get expHigh => 'Alta (4096 px)';

  @override
  String get expMax => 'Máxima (8192 px)';

  @override
  String get expTransparent => 'Fondo transparente';

  @override
  String get expTransparentHint => 'Sin plantilla ni papel';

  @override
  String get expStrokesOnly => 'Solo trazos';

  @override
  String get expStrokesOnlyHint => 'Sin imágenes ni plantilla';

  @override
  String get expExport => 'Exportar';

  @override
  String get ocrUnsupported => 'OCR solo está disponible en Android e iOS';

  @override
  String get ocrWorking => 'Reconociendo texto…';

  @override
  String get ocrNoText => 'No se reconoció texto en esta página';

  @override
  String get ocrResultTitle => 'Texto reconocido';

  @override
  String get ocrCopied => 'Texto copiado al portapapeles';

  @override
  String get edGoogleAccount => 'Cuenta Google';

  @override
  String get edSyncedCloud => 'Sincronizado con la nube';

  @override
  String get edRestoreCloud => 'Restaurar desde la nube';

  @override
  String get edRestoreCloudHint => 'Última versión (last-write-wins)';

  @override
  String get edDriveVersions => 'Ver versiones en Drive';

  @override
  String get edUploadInklus => 'Subir archivo .inklus';

  @override
  String get edSyncOnForNotebook => 'Sync: activada para este cuaderno';

  @override
  String get edSyncOffForNotebook => 'Sync: desactivada para este cuaderno';

  @override
  String get edSyncDisabledMsg => 'Sync desactivada para este cuaderno';

  @override
  String get edSyncEnabledMsg => 'Sync activada para este cuaderno';

  @override
  String get edNoteSynced => 'Nota sincronizada con Google Drive';

  @override
  String get edPasswordHint => 'Contraseña (dejar vacío si no está cifrado)';

  @override
  String get edNoCloudCopy =>
      'Todavía no hay ninguna copia de esta nota en Google Drive';

  @override
  String get edNoteRestored => 'Nota restaurada desde Google Drive';

  @override
  String get edIsFullBackup =>
      'Ese archivo es un respaldo completo, no un cuaderno .inklus';

  @override
  String get edNoPassword => 'Sin contraseña';

  @override
  String get edNotebookTitle => 'Título del cuaderno';

  @override
  String get pdfUnsupported =>
      'Importar PDF por ahora solo está disponible en Android/iOS';

  @override
  String get pdfReadFailed => 'No se pudo leer el PDF';

  @override
  String get verRestoreTitle => 'Restaurar versión';

  @override
  String get verRestored => 'Versión restaurada';

  @override
  String get verEncrypted => 'Copia cifrada';

  @override
  String get verPasswordHint => 'Contraseña de la copia';

  @override
  String get verDecrypt => 'Descifrar';

  @override
  String get inkUnsupported =>
      'Reconocer escritura solo está disponible en Android e iOS';

  @override
  String get edDeleteImage => 'Eliminar imagen';

  @override
  String get edExitPresent => 'Salir de presentación';

  @override
  String get edLaserOff => 'Desactivar láser';

  @override
  String get edGoToPage => 'Ir a página';

  @override
  String get edGo => 'Ir';

  @override
  String get edNoStickers => 'Aún no tienes stickers instalados.';

  @override
  String get edOpenMarket => 'Abrir el marketplace';

  @override
  String get edSyncing => 'Sincronizando…';

  @override
  String get edSyncToDrive => 'Sincronizar con Google Drive';

  @override
  String get edSynced => 'Sincronizado';

  @override
  String get edSyncError => 'Error de sincronización';

  @override
  String get menuPagePng => 'Página como imagen (PNG)';

  @override
  String get menuPagePdf => 'Página como PDF';

  @override
  String get menuNotePdf => 'Nota completa (PDF)';

  @override
  String get menuStrokesSvg => 'Trazos (SVG)';

  @override
  String get menuPptx => 'Presentación (PowerPoint)';

  @override
  String get menuInklusCopy => 'Copia .inklus';

  @override
  String get menuShareImage => 'Compartir imagen';

  @override
  String get menuSharePdf => 'Compartir PDF';

  @override
  String get menuShareInklus => 'Compartir .inklus';

  @override
  String get menuExportShare => 'Exportar y compartir';

  @override
  String get menuTemplate => 'Plantilla…';

  @override
  String get menuGoToPage => 'Ir a página…';

  @override
  String get menuImportPdf => 'Importar PDF para anotar';

  @override
  String get menuClearPage => 'Limpiar página';

  @override
  String get menuPage => 'Página';

  @override
  String get menuSearchNote => 'Buscar en la nota';

  @override
  String get menuIndexInk => 'Indexar escritura (para buscarla)';

  @override
  String get menuIndexInkUnsupported => 'Indexar escritura (solo Android/iOS)';

  @override
  String get menuOcr => 'Reconocer texto (OCR)';

  @override
  String get menuOcrUnsupported => 'OCR (solo Android/iOS)';

  @override
  String get menuVersions => 'Historial de versiones';

  @override
  String get menuReminder => 'Crear recordatorio';

  @override
  String get menuNightOff => 'Desactivar modo nocturno';

  @override
  String get menuNightOn => 'Modo nocturno de escritura';

  @override
  String get menuPresent => 'Modo presentación';

  @override
  String get menuHapticsOn => 'Vibración al escribir: sí';

  @override
  String get menuHapticsOff => 'Vibración al escribir: no';

  @override
  String get menuContinuousScroll => 'Desplazamiento continuo entre hojas';

  @override
  String get menuView => 'Ver';

  @override
  String get menuBackup => 'Exportar respaldo completo';

  @override
  String get menuRestoreBackup => 'Importar .inklus o respaldo';

  @override
  String get menuData => 'Datos';

  @override
  String get menuStats => 'Estadísticas de escritura';

  @override
  String get clearPageBody =>
      'Se borrará todo el contenido de la página. Puedes deshacerlo después.';

  @override
  String get clearPageAction => 'Limpiar';

  @override
  String get pgPrev => 'Página anterior';

  @override
  String get pgNext => 'Página siguiente';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get zoomFit => 'Ajustar a la vista';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get shareTextPage => 'Página de Inklus';

  @override
  String get shareTextNotebook => 'Cuaderno de Inklus';

  @override
  String edInsertImageFailed(String error) {
    return 'No se pudo insertar la imagen: $error';
  }

  @override
  String expSvgFailed(String error) {
    return 'Error al exportar SVG: $error';
  }

  @override
  String ocrFailed(String error) {
    return 'Error al reconocer texto: $error';
  }

  @override
  String expFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String expPreview(String name) {
    return 'Previsualización: $name';
  }

  @override
  String expSaveDialog(String name) {
    return 'Guardar $name';
  }

  @override
  String expDone(String path) {
    return 'Exportado: $path';
  }

  @override
  String expSaveFailed(String error) {
    return 'No se pudo guardar el archivo: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String edSignInIncomplete(String detail) {
    return 'No se completó el inicio de sesión. Detalle: $detail';
  }

  @override
  String uploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Error al restaurar: $error';
  }

  @override
  String edFileUploaded(String name) {
    return 'Archivo \"$name\" subido a Google Drive';
  }

  @override
  String pdfImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'PDF importado: $_temp0 para anotar';
  }

  @override
  String pdfImportFailed(String error) {
    return 'Error al importar PDF: $error';
  }

  @override
  String verRestoreBody(String date) {
    return 'La nota volverá a como estaba el $date.\\n\\nEl estado actual se guarda antes como una versión local, así que puedes deshacer la restauración desde este mismo historial.';
  }

  @override
  String verRestoreFailed(String error) {
    return 'No se pudo restaurar la versión: $error';
  }

  @override
  String pptxFailed(String error) {
    return 'Error al exportar PowerPoint: $error';
  }

  @override
  String reminderCreated(String date, String time) {
    return 'Recordatorio creado para $date a las $time';
  }

  @override
  String inkIndexed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'Escritura indexada en $_temp0: ya puedes buscarla';
  }

  @override
  String inkFailed(String error) {
    return 'No se pudo reconocer la escritura: $error';
  }

  @override
  String backupFailed(String error) {
    return 'Error al exportar respaldo: $error';
  }

  @override
  String importDoneOpen(String message) {
    return '$message. Ábrelo desde la biblioteca.';
  }

  @override
  String noteHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'La nota tiene $_temp0';
  }

  @override
  String stickerInsertFailed(String error) {
    return 'No se pudo insertar el sticker: $error';
  }

  @override
  String get remNoNotebooks => 'No hay cuadernos para vincular';

  @override
  String get remPickNotebook => 'Seleccionar cuaderno';

  @override
  String get remPickHint => 'El recordatorio abrirá este cuaderno';

  @override
  String get remCreated => 'Recordatorio creado';

  @override
  String get remMessageTitle => 'Mensaje del recordatorio';

  @override
  String get remMessageHint => 'Ej: Revisar apuntes de clase';

  @override
  String get remNoMessage => 'Sin mensaje';

  @override
  String get remTitle => 'Recordatorios';

  @override
  String get remSubtitle => 'Avisos vinculados a tus cuadernos';

  @override
  String get remEmptyTitle => 'Sin recordatorios';

  @override
  String get remPending => 'Pendientes';

  @override
  String get remDone => 'Completados';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsSubtitle => 'Tu actividad de escritura en este dispositivo';

  @override
  String get statsEmptyTitle => 'Sin datos todavía';

  @override
  String get statsStrokes => 'Trazos';

  @override
  String get statsMinutes => 'Minutos';

  @override
  String get statsActiveDays => 'Días activos';

  @override
  String get statsStreaks => 'Rachas';

  @override
  String get statsCurrentStreak => 'Racha actual';

  @override
  String get statsRecord => 'Récord';

  @override
  String get statsActivity => 'Actividad — últimos 30 días';

  @override
  String get statsDaysWithPages => 'Días con páginas nuevas';

  @override
  String get smartTitle => 'Carpetas inteligentes';

  @override
  String get smartSubtitle => 'Organiza tus cuadernos automáticamente';

  @override
  String get smartByColor => 'Por color';

  @override
  String get smartByTag => 'Por etiqueta';

  @override
  String get onbSkip => 'Saltar';

  @override
  String get onbStart => 'Empezar';

  @override
  String get onb1Title => 'Escribe con tu lápiz';

  @override
  String get onb2Title => 'Muévete con los dedos';

  @override
  String get onb3Title => 'Herramientas arriba';

  @override
  String get onb4Title => 'Tus notas son tuyas';

  @override
  String get layerAdd => 'Añadir capa';

  @override
  String get layerRename => 'Renombrar capa';

  @override
  String get verSubtitle => 'Al restaurar, el estado actual se guarda antes';

  @override
  String get verOnDevice => 'En este dispositivo';

  @override
  String get verNoLocal => 'Aún no hay copias locales de esta nota.';

  @override
  String get verOnDrive => 'En Google Drive';

  @override
  String get verNotUploaded => 'Esta nota aún no se ha subido a Drive.';

  @override
  String get smartThisWeek => 'Esta semana';

  @override
  String get smartNoTags => 'Sin etiquetas';

  @override
  String get smartOther => 'Otro';

  @override
  String get colorNone => 'Sin color';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorOrange => 'Naranja';

  @override
  String get colorPurple => 'Morado';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorTurquoise => 'Turquesa';

  @override
  String get colorGray => 'Gris';

  @override
  String get onb1Body =>
      'Apoya la mano sin miedo: Inklus reconoce el lápiz y descarta la palma. La goma del lápiz o el botón lateral borran.';

  @override
  String get onb2Body =>
      'Con el lápiz, un dedo desplaza la página y dos dedos acercan o alejan. Puedes volver a dibujar con el dedo desde la barra.';

  @override
  String get onb3Body =>
      'Toca una herramienta para usarla y tócala otra vez para ver sus opciones: grosor, color, borrador parcial, figuras…';

  @override
  String get onb4Body =>
      'Todo se guarda en este dispositivo, sin cuentas ni anuncios. Si quieres, puedes hacer copia en tu Google Drive.';

  @override
  String get remEmptyBody =>
      'Crea recordatorios vinculados a tus cuadernos para no olvidar nada.';

  @override
  String get statsEmptyBody =>
      'Empieza a escribir en tus cuadernos y tus estadísticas aparecerán aquí.';

  @override
  String get remOverdue => ' · vencido';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String statsDayTooltip(String date, int strokes, int pages) {
    return '$date: $strokes trazos, $pages páginas';
  }

  @override
  String get searchInNote => 'Buscar en esta nota';

  @override
  String get searchInAll => 'Buscar en todas las notas';

  @override
  String get searchPrompt => 'Escribe para buscar';

  @override
  String searchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coincidencias',
      one: '1 coincidencia',
    );
    return '$_temp0';
  }

  @override
  String get searchInfo =>
      'Incluye cajas de texto y la escritura a mano ya reconocida (menú Nota → Indexar escritura).';

  @override
  String get searchTitleMatch => 'Título';

  @override
  String get pgDuplicate => 'Duplicar página';

  @override
  String get pgDelete => 'Eliminar página';

  @override
  String verDriveFailed(String error) {
    return 'No se pudo consultar Drive: $error';
  }

  @override
  String colorSemantics(String hex) {
    return 'Color #$hex';
  }

  @override
  String get errNotInklus =>
      'El archivo no es un cuaderno .inklus ni un respaldo de Inklus.';

  @override
  String get errNotInklusFile => 'No es un cuaderno .inklus válido';

  @override
  String get errNotInklusV2 => 'No es un cuaderno .inklus v2 válido';

  @override
  String get errCatalogTooLarge => 'Catálogo demasiado grande';

  @override
  String errCatalogVersion(String version) {
    return 'Versión de catálogo no soportada: $version';
  }

  @override
  String get errOcrUnsupported => 'OCR solo está disponible en Android e iOS.';

  @override
  String get errNotSignedIn => 'Inicia sesión con Google primero.';

  @override
  String get errEncrypted => 'La copia está cifrada: hace falta la contraseña';

  @override
  String driveConfigBody(String details) {
    return 'Error de configuración de Google (clientConfigurationError).\\n\\nCausa probable: la SHA-1 de la firma de esta app no está registrada en Google Cloud Console para el paquete com.inklus.inklus.\\n\\nSolución:\\n1. Ve a Google Cloud Console → APIs y servicios → Credenciales\\n2. Crea o edita el ID de cliente OAuth de Android con el paquete com.inklus.inklus y la SHA-1 de tu firma\\n3. Habilita Google Sign-In en la pantalla de consentimiento\\n\\nError original: $details';
  }

  @override
  String get noticeStylus =>
      'Lápiz detectado: ahora el dedo desplaza la página (actívalo en la barra si quieres dibujar con el dedo)';

  @override
  String get noticePageDeleted => 'Página eliminada';

  @override
  String get noticeFileUploaded => 'Archivo subido a Google Drive';

  @override
  String importBackupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuadernos',
      one: '1 cuaderno',
    );
    return 'Respaldo restaurado: $_temp0';
  }

  @override
  String importNotebookDone(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return 'Cuaderno \"$title\" importado ($_temp0)';
  }

  @override
  String importNotebookSimple(String title) {
    return 'Cuaderno \"$title\" importado';
  }

  @override
  String get driveRestoreNone => 'No hay copias de Inklus en tu Google Drive';

  @override
  String get driveRestoreUpToDate => 'Todo está al día: nada que restaurar';

  @override
  String driveRestoreUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas actualizadas',
      one: '1 nota actualizada',
    );
    return '$_temp0';
  }

  @override
  String driveRestoreAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recuperadas',
      one: '1 recuperada',
    );
    return '$_temp0';
  }

  @override
  String get driveRecovered => 'Recuperado de Drive';

  @override
  String get packClassicName => 'Cuadernos clásicos';

  @override
  String get packClassicDesc =>
      'Rayado ancho y estrecho, cuadrícula de 5 mm, puntos y pentagrama.';

  @override
  String get packTechName => 'Papel técnico';

  @override
  String get packTechDesc =>
      'Cuadrícula fina tipo milimetrado y agenda por columnas, en tonos suaves.';

  @override
  String get packStudyName => 'Paleta Estudio';

  @override
  String get packStudyDesc =>
      'Tinta azul y negra, rojo de corrección, verde y naranja para destacar.';

  @override
  String get packPastelName => 'Paleta Pastel';

  @override
  String get packPastelDesc => 'Tonos suaves para apuntes bonitos y diagramas.';

  @override
  String get packEarthName => 'Paleta Tierra';

  @override
  String get packEarthDesc =>
      'Ocres, oliva y terracota, con buen contraste sobre papel.';

  @override
  String get coverSimple => 'Degradado';

  @override
  String get coverClassic => 'Clásico';

  @override
  String get coverAurora => 'Aurora';

  @override
  String get coverWaves => 'Olas';

  @override
  String get coverGeometric => 'Geométrico';

  @override
  String get coverSun => 'Sol';

  @override
  String get coverDots => 'Puntos';

  @override
  String get coverLines => 'Rayas';

  @override
  String get untitled => 'Sin título';

  @override
  String get defaultNotebookTitle => 'Mi cuaderno';

  @override
  String get createFromFile => 'O empieza desde un archivo';

  @override
  String get createFromFileHint =>
      'Sube un PDF o fotos y escribe encima de cada página.';

  @override
  String get createFromPdf => 'Desde un PDF';

  @override
  String get createFromImages => 'Desde imágenes';

  @override
  String get createFromFileRemove => 'Quitar archivo';

  @override
  String createFromFilePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }
}
