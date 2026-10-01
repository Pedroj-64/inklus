# 🗺️ Hoja de ruta — Inklus

> Estado del proyecto y próximos pasos. La **guía técnica para la IA** está en [`AGENTS.md`](AGENTS.md) (arquitectura, flujos críticos, gotchas); el manual de usuario/instalación en [`README.md`](README.md).

## 🧭 Cómo leer esta hoja de ruta (para la IA)

- Cada fila es una **tarea independiente** con su *por qué / cómo*: el **por qué** justifica el valor, el **cómo** apunta a archivos y APIs concretas del código (no es una orden de implementación, es la pista).
- Marcadores: **`✅`** = hecho e integrado; **`🔧`** = parcial / stub; el resto está **ordenado por valor** dentro de cada fase.
- **Regla de oro: offline-first.** Todo debe seguir funcionando 100% sin red ni cuenta; Google Drive es un respaldo *opcional*.
- **Filosofía open source / gratis.** No hay funciones "premium". Las dependencias externas deben ser gratuitas.

---

## ✅ Lo que la app ofrece hoy

> Verificado contra el código fuente (~25,678 líneas Dart en `lib/`, 216 tests pasando).

### ✨ UX y Onboarding
- **Onboarding tutorial**: 4 páginas ilustradas skippable al primer inicio; persiste con `SharedPreferences`.
- **Biblioteca rediseñada**: empty state con call-to-action, menú ⋮ con tema/ordenar/configuración, carpetas inteligentes, etiquetas.
- **Pantalla de configuración**: Google Drive (conectar/desconectar), tema claro/oscuro, backup local, acceso a estadísticas y recordatorios.
- **Barra de herramientas (tool rail)**: diseño flotante con bordes redondeados, separadores visuales, animaciones de selección.
- **Bottom bar rediseñada**: paleta de colores + slider de tamaño en dos filas, iconos toggle para formas/dedo, acciones de lazo.
- **Template picker**: secciones "Lienzo infinito" y "Hoja fija", tiles con preview, selector de formato al crear Note.
- **Portada de cuaderno**: estilos de portada (color/patrón/imagen propia) en la biblioteca.

### ✍️ Escritura y herramientas (10 herramientas)
- **Escritura con stylus**: presión real; **rechazo de palma** por lápiz apoyado, *hover* del lápiz (S-Pen/Apple Pencil), ventana de gracia tras levantarlo y tamaño de contacto (`PalmRejection`); al apoyar el lápiz se descarta lo que estuviera haciendo la palma.
- **Modo solo lápiz automático**: al detectar un lápiz, el dedo deja de dibujar y **desplaza la página con un dedo** (se recuerda; conmutable en la barra).
- **Borrador por hardware**: goma del lápiz (`invertedStylus`) y **botón lateral del S-Pen** mantenido = borrar.
- **Zoom/pan con dos dedos** (el stylus nunca panea); trazo suavizado con `perfect_freehand`.
- **Herramientas**: lapicero (`pen`), lápiz (`pencil`), resaltador (`highlighter`), **caligrafía** (`calligraphy`), **pincel** (`brush`), borrador (`eraser`), selección/mover (`select`), lazo (`lasso`), bucket (`bucket`), cajas de texto (`text`).
- **Paleta + color personalizado (HSV)**, tamaño por herramienta, deshacer/rehacer (60 niveles).
- **Háptica del lápiz** (vibración sutil al escribir, configurable).
- **Detección de figuras**: línea, rectángulo, círculo, **flecha** (con cabeza triangular).
- **Copy & paste de trazos** (portapapeles interno).
- **Snapping / guías magnéticas** al arrastrar imágenes.
- **Relleno de áreas** (bucket fill).
- **Transformar selección**: handles de escala/rotación + undo.

### 🎨 Plantillas (9 tipos)
- **Lienzo infinito**: blank, ruled, grid, dots, music, planner, habit — todos infinitos por defecto.
- **Hoja fija**: sheet (A4), custom (imagen del usuario, fija o relleno infinito).
- **Toggle "Lienzo infinito"**: checkbox en el template picker para ruled/grid/dots/planner (pueden ser finitos).
- **Personalización**: color de línea (9 colores), separación, tamaño de hoja (A4, Carta, B5, Half Ltr).
- **Biblioteca de plantillas propias**: guardar/cargar en `inklus/templates/`.
- **Marketplace de plantillas**: 12 bundled + catálogo remoto vía GitHub (`fetchRemoteCatalog()`).

### 📚 Gestión de cuadernos y páginas
- **Jerarquía Cuaderno → Note**: `Notebook` contiene `Note[]`, cada Note tiene `Page[]`.
- **Biblioteca**: tarjetas de Notebook con miniatura, CRUD (crear/renombrar/duplicar/eliminar).
- **Pantalla `NoteListScreen`**: lista de Notes dentro de un Notebook, crear/renombrar/eliminar/duplicar con selector de plantilla.
- **Buscar y ordenar** cuadernos (título + etiquetas, orden por fecha/título).
- **Color de portada** por Notebook (9 colores).
- **Etiquetas / tags** por Notebook + editor de tags.
- **Smart folders** (carpetas dinámicas): filtran por tags, color, fecha.
- **Miniaturas de páginas** en el editor (franja inferior con drag & drop).
- **Papelera** (recuperar cuadernos eliminados, vaciar).
- **Importar `.inklus`** desde la biblioteca.

### 💾 Persistencia y formato
- **Guardado local** JSON automático (debounce 600 ms).
- **Formato `.inklus`**: ZIP autocontenido (`document.json` + imágenes embebidas) — compatible con `.goodnotes`/`.sdoc`.
- **Migración automática**: formato antiguo (`current_document.json`) → `Notebook + Note`.
- **Respaldo local completo** (ZIP con `notebooks/` + `notes/` + imágenes + papelera + recordatorios/estadísticas). Al importar **fusiona** con lo local, re-mapea rutas de imágenes entre dispositivos y rechaza rutas inseguras (zip-slip).
- **Escrituras atómicas** (temporal + `rename`) y cola serializada del índice: un cierre inesperado nunca deja un JSON truncado; si `index.json` se corrompe, se reconstruye desde `notebooks/`.
- **Historial de versiones local** (`VersionHistoryService`): instantáneas gzip en `inklus/versions/<noteId>/` al abrir/cerrar la nota (máx. 20); menú ⋮ → "Historial de versiones" para restaurar (la versión actual se guarda antes).

### ☁️ Sincronización con Google Drive
- **Offline-first**: signIn con `drive.file`, sesión silenciosa (One Tap), backup automático silencioso.
- **Sync individual por Note**: cada Note se sincroniza como `.inklus` separado (minimiza tráfico y conflictos). La subida automática se agrupa (máx. una cada 20 s + al salir del editor).
- **Estado visible**: iconos por Notebook (sincronizado/sincronizando/error/deshabilitado).
- **Cifrado AES-256-GCM** (`BackupCrypto`): `cryptography` v2.9, PBKDF2 100k iteraciones en un isolate; clave derivada de UTF-8 (compatible con backups antiguos derivados de `codeUnits`).
- **Conflictos**: selección de versión cuando hay múltiples copias en Drive.
- **Historial de revisiones en Drive**: `DriveSyncService.downloadVersion` (sin UI propia aún; el historial *local* sí tiene UI).
- **Sync selectiva**: flag `syncEnabled` por Notebook.
- **Cambiar de cuenta** / cerrar sesión.
- **Subir/bajar `.inklus` manual**.
- **Notificaciones** (snackbar al completar sync).

### 📤 Exportar y compartir
- **PNG** con previsualización antes de guardar.
- **PDF** (página o cuaderno completo).
- **PowerPoint** (`.pptx` con imágenes por diapositiva).
- **SVG** (trazos como paths editables).
- **`.inklus`** (copia del cuaderno).
- **Configurable**: DPI (1024–8192 px), fondo transparente, solo trazos, región personalizada.
- **Compartir** (PNG/PDF/.inklus a otras apps via `share_plus`).

### 🔍 OCR y búsqueda
- **OCR de tinta**: reconocimiento on-device con ML Kit (Android/iOS).
- **OCR on-demand** (`recognizeStrokes()`): renderiza trazos → ML Kit para reconocer la última escritura.
- **Búsqueda en contenido**: `SearchService` indexa textItems + OCR.

### 🧩 Herramientas de edición
- **Capas por página**: visibilidad, bloqueo, **opacidad por capa** (0–100%).
- **Sidebar de capas docked** (~240px, patrón Canva, empuja el canvas).
- **Cajas de texto** (`TextItem` + `TextEditOverlay`).
- **Regla y transportador** (botón: regla → transportador → ocultar): tamaño fijo en pantalla, escala en **cm/mm de la hoja**, ángulo en vivo con imán a 0/45/90°, se arrastra con un dedo y se rota con dos; el lápiz se **engancha al borde** cercano (o al arco del transportador, como compás).
- **Lupa** (overlay flotante, se cierra al soltar).
- **Modo presentación / pizarra** (oculta todas las barras).
- **Modo nocturno de escritura**: invierte la luminosidad del lienzo conservando el tono (solo en pantalla; la exportación no cambia). Se recuerda entre sesiones.

### 📱 Funciones de comunidad y ecosistema
- **Backlinks entre páginas** (`TextItem.linkToPageId` + `BacklinkService`).
- **Estadísticas de escritura** (`WritingStatsService` + pantalla con gráfico, rachas).
- **Recordatorios** vinculados a cuadernos (`ReminderService`).
- **Integración con calendario** (`CalendarService`).

### 📤 Importación
- **Importar PDF para anotar** (`PdfImportService.importPages`): cada página del PDF se convierte en una página de la nota (hoja fija con el PDF de fondo, proporción real), procesando página a página (Android/iOS).

### ⌨️ Atajos de teclado
- **Ctrl+Z**: deshacer.
- **Ctrl+Shift+Z / Ctrl+Y**: rehacer.
- **Ctrl+C**: copiar selección.
- **Ctrl+V**: pegar.

### 🧪 Calidad y DevOps
- **173 tests** pasando (modelos, storage, backup, cifrado, migración, CRUD, formatos, lógica del lienzo, historial).
- **CI (GitHub Actions)**: `flutter analyze` + `flutter test --coverage` + APK debug + build Linux; en tags `v*` genera APK/AAB **firmados** (secretos `ANDROID_KEYSTORE_*`) y los publica en la release.
- **Firma de release** desde `android/key.properties` (no versionado); sin él, release usa la clave debug.
- **Tema oscuro** adaptado (scaffold, top bar, bottom bar, tool rail, biblioteca).
- **Animaciones de transición** suaves.
- **Rendimiento del lienzo**: culling por rectángulo (solo se pinta lo visible), `Path`/polígono cacheados por instancia de trazo (`Expando`, sin fugas), aerosol cacheado como `Picture`, trazo activo O(1) por punto, borrador con prefiltro por rectángulo, deshacer compacto que conserva el orden (z-order), rebuilds acotados en el editor (`ControllerSelector`), caché de imágenes LRU acotada por memoria.

---

## 🚀 Camino a la release 2.0 (plan por versiones)

> Estado de partida (sept. 2026): base técnica sólida (persistencia atómica, backup completo, rendimiento del lienzo, rechazo de palma, regla, PDF multipágina, exportación sin recortes). Lo que separa a Inklus de GoodNotes/Notability/Samsung Notes ahora es sobre todo **experiencia** (UI, flujo de páginas, búsqueda, lazo) y **distribución** (tienda, legal, marketplace).

### ✅ v1.4 — "Escribe como debe" (hecho en la rama `optimizacion`)
- Rechazo de palma completo + modo solo lápiz + pan con un dedo + botón S-Pen; arreglado el bug que dejaba la pantalla sin responder al tacto tras mover una selección con el lápiz.
- Eliminado el doble toque con la goma que **borraba la página sin deshacer**. Borrar página → "Deshacer" en un aviso; limpiar página se deshace con Ctrl+Z.
- Hoja fija centrada al abrir (salía desplazada), margen del rayado en su sitio, sin trazos invisibles fuera de la hoja, presets A4/Carta/B5/Half Letter funcionando.
- **Exportación y miniaturas sin recortes** (antes solo salía un cuarto de la hoja en PNG/PDF/PPTX/OCR y en las miniaturas de la biblioteca).
- Plantillas infinitas: líneas nítidas a cualquier zoom y nivel de detalle (al alejar ya no se generan >150.000 círculos por frame con puntos/hábitos); casillas de hábitos con contorno.
- Regla/transportador rediseñados y usables. PDF multipágina para anotar. Tema claro/oscuro recordado y funcional desde cualquier pantalla. Editor con ~15 % más de lienzo visible (barra inferior en una fila, miniaturas plegadas por defecto).

### ✅ v1.4 (cont.) — Lavado de cara y paridad (hecho en la rama `optimizacion`)
- **U1 Sistema de diseño**: `ui/theme/` (ThemeData central, `InklusColors`, tokens), esquema `fidelity` que respeta el azul de marca.
- **U2 Editor**: barra superior única con plumas, herramientas, deshacer, páginas, capas, ☁️ y ⋮; opciones en **popovers anclados**; panel lateral de páginas; indicador "‹ 2/5 ›"; zoom compacto. Se eliminaron el riel lateral, la barra inferior y la tira de miniaturas.
- **U3 Plumas favoritas**: 3 plumas + resaltador con color/grosor propios y colores recientes (persistentes).
- **U4 Menú ⋮** agrupado en submenús (Exportar y compartir · Página · Nota · Ver · Datos).
- **U5 Biblioteca**: logo propio, navegación lateral (Todos, Recientes, Favoritos, Carpetas, Marketplace), buscador M3 con búsqueda en el contenido, cuadrícula/lista, favoritos.
- **F1 Lazo**: selecciona trazos, imágenes y textos; mover/eliminar juntos (deshacible); recolorear, grosor, duplicar y **convertir a texto** (Android/iOS).
- **F2 Borrador**: parcial, trazo completo, solo resaltador.
- **F3 Páginas**: marcadores (+ filtro), ir a página N, anterior/siguiente, atajos de teclado.
- **F4 Búsqueda**: índice v2 por nota (título, texto, escritura reconocida), sin acentos, global desde la biblioteca; "Indexar escritura".
- **F5 Texto enriquecido**: negrita, cursiva, subrayado, alineación, familia, tamaño.
- **F6 Figuras**: "mantener para enderezar" (por defecto), triángulo, elipse real, rectángulo cerrado.
- **F8 (parcial)**: la lupa sigue al lápiz y su aumento es relativo al zoom.
- **F9 Láser** (también en modo presentación).
- **Marketplace propio**: pantalla, instalación verificada, catálogo incluido sin red y plantilla del repo (`marketplace/`).

### ✅ v1.4.2 — Estabilidad de la release (hecho)
- Arranque en release (reglas R8 de WorkManager), inicio de sesión con Google (`initialize(serverClientId)`), timeout de 60 s en Drive.
- **Restaurar desde Drive** (last-write-wins por nota + cuaderno "Recuperado de Drive").
- **Importación única por contenido** (`ImportService`): `.inklus` v1/v2, respaldo completo y `.inklus.zip` renombrados.
- Autoguardado fijo (sin intervalo configurable), nuevo icono, Configuración migrada al sistema de diseño.

### 🎯 Siguiente — plan por fases (revisado contra el código, 2026-09-27)
> Prioridades: **1) no perder datos, 2) fluidez con notas grandes, 3) interfaz consistente, 4) distribución pública.** Cada fase es una versión publicable.

**Hallazgos que motivan el orden**
- `StorageService.saveNote` escribe el archivo y **después** llama a `note.touch()`: el JSON en disco lleva el `updatedAt` del guardado anterior (afecta a *last-write-wins* de Drive y a "Recientes").
- `createNote`/`renameNote`/… hacen `loadNotebook` (lee **todas** las notas) + `saveNotebook` (reescribe **todas**): renombrar una nota reescribe el cuaderno entero.
- El autoguardado hace `jsonEncode` de la nota completa en el hilo de UI (la lectura ya usa `decodeJsonAsync`).
- `CanvasPainter.shouldRepaint` compara `scale`/`translate`: al desplazar o hacer zoom se vuelven a dibujar todos los trazos en cada frame.
- `ImageService.decode` decodifica a resolución completa (foto de 12 MP ≈ 48 MB; la caché de 192 MB aguanta ~4).
- El job "Release firmado (tags v*)" de `ci.yml` ya existe: solo faltan el keystore y los secretos.
- *(Encontrado al hacer la Fase 0)* las copias de una sola nota (Drive, "copia .inklus") son `.inklus` v1 con `format.json`, y `importAuto` las mandaba al importador v2 → fallaban. Corregido en 1.4.3.

#### Fase 0 — v1.4.3 "Datos seguros" (✅ 0.1–0.3 hechos; falta 0.4, manual)
| # | Cambio | Dónde | Hecho cuando |
|---|---|---|---|
| 0.1 | ✅ `note.touch()` **antes** de escribir (`saveNote(touch: false)` para copias restauradas). | `storage_service.dart` `saveNote` | Test: el `updatedAt` leído del archivo = el de memoria. |
| 0.2 | ✅ `_editNotebook()`: escribe solo `notebooks/<id>.json` + índice; crear/renombrar/mover/borrar una nota toca solo esa nota. | `storage_service.dart` | Test: renombrar no modifica los archivos de las otras notas. |
| 0.3 | ✅ `writeJsonAtomic(background:)`: `toJson()` en el hilo principal (instantánea) y `jsonEncode` + escritura en `Isolate.run`, como `decodeJsonAsync`. | `file_utils.dart`, `saveNote` | Sin tirones al guardar una nota de 100 páginas (perfilado). |
| 0.4 | Keystore de release + secretos `ANDROID_KEYSTORE_BASE64/…PASSWORD/KEY_ALIAS/KEY_PASSWORD` (**manual**). Fijar la clave antes de repartir APKs: cambiarla obliga a desinstalar. | GitHub → Settings → Secrets | `git tag v1.4.3 && git push --tags` publica APKs firmados. |

#### Fase 1 — v1.5 "Fluido con notas grandes" (✅ hecha salvo la medición en dispositivo)
| # | Cambio | Dónde |
|---|---|---|
| 1.1 | ✅ **Pan/zoom por composición** (`ViewSnapshot`, `toImageSync`; se vuelve a tomar si el zoom varía ×1,6): durante el gesto, reproducir la capa confirmada grabada una vez como `ui.Picture` (por `contentVersion`) aplicando solo la transformación; rasterizar a la escala final al soltar. | `drawing_canvas.dart` (`CanvasPainter`, `_onScaleUpdate/End`) |
| 1.2 | ⏸️ **Trazo activo incremental — descartado tras medir**: `getStroke` cuesta ~0,5 ms con 3.000 puntos (≈25 s de trazo continuo) frente a 8–16 ms por frame; trocearlo metería saltos en uniones y puntas con presión simulada. Reabrir solo si 1.5 lo muestra en el dispositivo. | `stroke_engine.dart` |
| 1.3 | ✅ **Imágenes a resolución de pantalla** (`kCanvasImageMaxSide` = 2560) en el lienzo; `imagesForExport` decodifica a la resolución de la exportación, página a página. | `image_service.dart`, `export_service.dart` |
| 1.4 | ✅ **Pan acotado** en hoja fija (`clampSheetTranslate`, margen 48 px). | `canvas_controller.dart` |
| 1.5 | 🔧 Medir en la tablet con `flutter run --profile`: cuaderno de prueba generado por `flutter test tool/stress/stress_note_test.dart` → `build/inklus_stress.inklus`. | — |

#### Fase 2 — v1.6 "Todo con el mismo diseño" (✅ hecha)
- ✅ **P1**: todas las pantallas y hojas migradas a `ui/widgets/page_scaffold.dart` + tokens (`InklusPage` aplica el margen lateral; `showConfirmDialog` para confirmaciones destructivas). Quedan colores literales solo donde son **contenido** (paletas de portada/etiquetas/plantillas, selector de color, lienzo).
- ✅ **P7**: el lazo escala/rota/copia/pega/duplica imágenes y textos (`transformSelectedStrokes`, portapapeles de tres tipos, `selectionHandles` como única fuente de las asas).
- ✅ **P8**: revisiones de Drive en el historial (`DriveSyncService.listRevisions/downloadRevision`, `ui/editor/version_history_sheet.dart`).
- ✅ Extra: papelera reescrita (`TrashEntry`, notas sueltas, purga de 30 días).

#### Fase 3 — v1.7 "Base sana" (✅ hecha salvo páginas en archivos)
- ✅ `CanvasController` dividido con `part` + mixins sobre `_CanvasCore`: `canvas_view.dart` (zoom/pan, desplazamiento continuo), `canvas_selection.dart` (lazo, portapapeles, transformar), `canvas_layers.dart`. API pública intacta.
- ✅ `AppPaths` único (`lib/services/app_paths.dart`): ningún servicio construye `appSupport/inklus` a mano.
- ✅ Legacy fuera: `backupDocument/restoreDocument/RestoreResult`, `listVersions/downloadVersion`, `BacklinkService` y el adaptador `controller.document` (exportación y recordatorios usan `Note`).
- ⏸️ **Páginas en archivos separados**: aplazado a propósito. Cambia el formato en disco y toca papelera, respaldo completo (re-mapeo de rutas de imágenes), limpieza de imágenes huérfanas, migración e importación: un fallo pierde notas. El guardado de notas grandes ya va en segundo plano (1.4.3) y P3 no lo necesita (las páginas están en memoria). Reabrir solo si la medición con el cuaderno de estrés muestra carga lenta o memoria alta con notas de cientos de páginas; entonces: `notes/<id>.json` (metadatos + `pageIds`) + `notes/<id>/pages/<pageId>.json`, carga perezosa, y adaptar esos cinco puntos con tests de ida y vuelta.

#### Fase 4 — v2.0 "Release pública"
- ✅ **R2** política de privacidad (`docs/privacy.md`, enlazada en Configuración). **R3** (manual): en Google Cloud → pantalla de consentimiento → URL de la política + *Publish app*.
- ✅ **R4** releases en GitHub: notas desde el CHANGELOG, comprobación tag = versión, instrucciones de instalación en README y en cada release.
- ✅ **R5** `integration_test/app_test.dart` (también en CI con Xvfb) + guion manual `docs/testing.md`.
- ✅ **R6** sustituido por un **registro de errores local** (`ErrorLog`) que el usuario comparte a mano: coherente con "sin analítica ni terceros".
- ✅ **P3** desplazamiento continuo entre hojas fijas (+ deshacer por página).
- ✅ **P2** i18n (2026-10): todas las pantallas y avisos en `lib/l10n/app_{es,en}.arb`; la app sigue el idioma del sistema (es/en; otro → inglés). Errores con código (`AppError`/`userError`), resultados con `message(l10n)`. Quedan en español por diseño: contenido guardado en datos (títulos por defecto, nombres de páginas/capas; se traducen al mostrarse con `displayTitle`), catálogo remoto del marketplace y diagnósticos técnicos (`validatePack`, logs).
- **v2.0** = P2 terminado + R3 hecho + guion de `docs/testing.md` superado en una tablet.

#### Aparcado (poco valor ahora o coste alto)
P4 audio sincronizado, P5 ventana de zoom, R7 plugin nativo de latencia (solo si la medición de 1.5 lo justifica), R8 otras plataformas.

### ✅ Ronda 2026-10 (texto, Drive, UI)
- Texto tipo Docs: formato por selección (negrita/cursiva/subrayado/tachado/color/resaltado/fuente), 11 fuentes, interlineado, mover y ensanchar la caja, deshacer correcto; arreglado que tocar la barra moviera la página.
- Figuras: resaltador recto, ajuste a ejes. Drive: carpeta por cuaderno, sync selectiva desde Configuración y menú del cuaderno, diagnóstico de inicio de sesión. UI: portadas nuevas + "Tu imagen" visible, marketplace rediseñado.
- Pendiente de verificar en tablet: edición de texto con S-Pen/teclado, y el inicio de sesión de Drive (registrar SHA-1 de debug y release en Google Cloud).

### 🟡 Pendiente (siguiente ronda)
| # | Tarea | Detalle |
|---|---|---|
| P1 | ✅ **Migrar pantallas restantes al sistema de diseño** | Hecho en 1.4.2 (Configuración) y 1.6.0 (resto). |
| P2 | ✅ **i18n** | Hecho (ver Fase 4). |
| P3 | ✅ **Desplazamiento vertical continuo** entre páginas (1.7.0). Vista doble en apaisado: pendiente. |
| P4 | **Audio sincronizado** (`record`) con reproducción que resalta lo escrito. |
| P5 | **Ventana de zoom** tipo Samsung Notes (recuadro de escritura ampliada que avanza solo). |
| P6 | **Portadas desde el marketplace** y plantillas con imagen/PDF en el catálogo real (hoy el catálogo incluido solo trae plantillas paramétricas y paletas). |
| P7 | ✅ **Escalar/rotar y copiar/pegar** también imágenes y textos del lazo (1.6.0). |
| P8 | ✅ **UI de revisiones de Drive** en el historial de versiones (1.6.0). |

### 🔵 v2.0 — Release pública (sin Google Play)
> Decisión: **no se publica en Google Play**. Distribución por **GitHub Releases** (APK firmados por la CI en cada tag `v*`) y, opcionalmente, IzzyOnDroid. (F-Droid principal no admite dependencias propietarias como ML Kit / Google Sign-In.)

| # | Tarea | Detalle |
|---|---|---|
| R1 | ✅ **LICENSE GPL-3.0-or-later** | `LICENSE` + cabecera SPDX en cada `.dart` + sección en README. |
| R2 | ✅ **Política de privacidad** | `docs/privacy.md` (1.7.0), enlazada en Configuración: todo local, Drive con `drive.file`, ML Kit en el dispositivo, sin analítica. Es la URL para la pantalla de consentimiento OAuth. |
| R3 | **OAuth en producción** | Pasar la pantalla de consentimiento de Google Cloud de *Testing* a *In production* (si no: máx. 100 usuarios de prueba y tokens que caducan a los 7 días). |
| R4 | ✅ **Releases en GitHub** | Tags `v*` → la CI firma, adjunta APK por ABI + AAB, comprueba tag = versión y usa la sección del CHANGELOG como notas. Instalación explicada en README y en cada release. |
| R5 | ✅ **Pruebas en dispositivo** | `integration_test` (CI con Xvfb) + guion manual `docs/testing.md` para Galaxy Tab S, tablet USI y teléfono. |
| R6 | ✅ **Registro de errores** | Local y compartido a mano por el usuario (en lugar de Sentry). |
| R7 | **Latencia del lápiz** | Medir; si es alta, plugin nativo Android con *front-buffered rendering* + predicción de movimiento. |
| R8 | **Otras plataformas** | iPadOS / Windows (revisar `google_sign_in`, ML Kit y `printing`). |
| R9 | **Versionado** | SemVer + `CHANGELOG.md`. |

### 🛒 Marketplace propio de Inklus

**Estado actual:** `TemplateMarketplaceService` es **código muerto** (ninguna pantalla lo usa). Solo maneja *parámetros* de plantillas integradas (tipo, color, espaciado), no archivos, sin validación, y apunta a un repo externo (`nicblo/inclus-templates`). Se puede reutilizar su estructura de caché/parseo, pero el formato hay que rehacerlo.

**Propuesta (coste 0 €, coherente con "todo gratis"):**

1. **Repositorio propio** `inklus-marketplace` (en tu cuenta u organización de GitHub). Cada paquete es una carpeta `packs/<id>/` con `manifest.json` + archivos + `preview.webp`.
2. **Tipos de contenido**: plantillas (paramétricas o imagen/PDF de fondo, finitas o infinitas), **planners PDF** con enlaces, paquetes de **stickers** (PNG/SVG), **portadas**, **paletas de color**, **presets de pluma**, fondos para la regla.
3. **Catálogo generado por CI**: una GitHub Action valida cada PR (esquema JSON, tamaños máximos, dimensiones de imagen, tipos permitidos —nunca ejecutables—, licencia declarada CC0/CC-BY, autor) y publica `catalog.json` v2 con **sha256** de cada archivo y `minAppVersion`.
4. **Distribución por CDN gratuito**: `https://cdn.jsdelivr.net/gh/<usuario>/inklus-marketplace@<tag>/…` (caché global, versionado por tag) o GitHub Releases. La app verifica el sha256 antes de instalar.
5. **En la app**: pantalla *Marketplace* (categorías, búsqueda, vista previa, instalar/desinstalar), instalación en `inklus/marketplace/<packId>/`, uso offline; los paquetes instalados aparecen en el selector de plantillas, el panel de stickers y las portadas.
6. **Publicar**: fase A por Pull Request (moderación con `CODEOWNERS`); fase B, botón "Publicar" en la app que abre un *issue form* de GitHub o un Cloudflare Worker gratuito que crea el PR; valoraciones con reacciones o Workers KV.
7. **Legal**: normas de contenido, proceso de retirada (DMCA) y licencia obligatoria por paquete.

Contenido inicial sugerido: agenda semanal/mensual real (con días y cabeceras, la plantilla "planner" actual es solo una rejilla), Cornell, hoja de cálculo/ingeniería, papel milimetrado, pentagrama con clave, storyboard, calendario, rastreador de hábitos de 31 días, portadas y 3-4 paquetes de stickers.

### 🛠️ Deuda técnica pendiente
| Tarea | Descripción |
|---|---|
| ✅ **Dividir `CanvasController` (estado)** | Hecho en 1.7.0: `canvas_view.dart`, `canvas_selection.dart`, `canvas_layers.dart` (`part` + mixins). |
| ✅ **Consolidar Drive legacy** | Hecho en 1.7.0: Drive y exportación solo trabajan con `Note`; `Document` queda para migración e importar `.inklus` v1. |
| ✅ **`AppPaths` único** | Hecho en 1.7.0: `lib/services/app_paths.dart`. |
| ✅ **Papelera de Notes sueltas** | Resuelto en 1.6.0 (`TrashEntry`, vuelve a su cuaderno). |
| ✅ **Timeouts de Drive** | Resuelto en 1.4.2: `_BearerClient` corta a los 60 s (todas las llamadas pasan por él). |
| ✅ **Pan sin límites** | Resuelto en 1.5.0 (Fase 1.4). |
| **Trazo activo incremental** | Medido en 1.5.0: no compensa (ver Fase 1.2). |

## 📊 Métricas del proyecto

| Métrica | Valor |
|---|---|
| Archivos Dart (lib/) | ~94 |
| Líneas de código | ~25,678 |
| Tests | 216 unitarios + 1 de integración + 23 capturas (todos pasando) |
| Modelos | 9 (`document`, `note`, `notebook`, `page`, `stroke`, `template`, `image_item`, `text_item`, `id`) |
| Servicios | 17 (+ `file_utils`) |
| Herramientas de escritura | 10 (pen, pencil, highlighter, calligraphy, brush, eraser, select, lasso, bucket, text) |
| Tipos de plantilla | 9 (blank, sheet, ruled, grid, custom, music, planner, habit, dots) |
| Pantallas | 8 (library, note_list, home, settings, onboarding, trash, reminder, writing_stats) |
| Widgets | 11 |

---

## 🔧 Convenciones para continuar

- Idioma de la UI y comentarios: **español**.
- Coordenadas de trazos: **mundo** (independientes del zoom); la vista aplica `scale`+`translate`.
- Toda mutación del documento pasa por `CanvasController` (única fuente de verdad, `ChangeNotifier`).
- Guardado local automático con debounce de 600 ms; Drive replica individualmente cada Note en formato `.inklus`.
- La app es **offline-first**: nunca romper el flujo local por una dependencia de red/cuenta.
- Todo es **gratis y open source**: no crear funciones premium ni dependencias de pago.
- Iconos: `dart run flutter_launcher_icons` (fuente en `assets/icon/`). Release: `flutter build apk --release --split-per-abi`.
- CI: `flutter analyze` + `flutter test --coverage` + APK debug + Linux; release firmado en tags `v*`.
- Onboarding: se guarda en `SharedPreferences('onboarding_seen')` = false tras completar.
- **ToolType** tiene 10 valores: `pen`, `pencil`, `highlighter`, `calligraphy`, `brush`, `eraser`, `select`, `lasso`, `bucket`, `text`.
- **Stroke.shapeType** persiste la forma detectada (`line`, `arrow`, `rectangle`, `circle`).
- **Jerarquía de datos**: `Notebook` → `Note` → `Page` → `Stroke/ImageItem/TextItem`.
- **Sync**: cada Note se sincroniza individualmente como `<noteId>.inklus` en Drive.
