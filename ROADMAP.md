# 🗺️ Hoja de ruta — Inklus

> Estado del proyecto y próximos pasos. La **guía técnica para la IA** está en [`AGENTS.md`](AGENTS.md) (arquitectura, flujos críticos, gotchas); el manual de usuario/instalación en [`README.md`](README.md).

## 🧭 Cómo leer esta hoja de ruta (para la IA)

- Cada fila es una **tarea independiente** con su *por qué / cómo*: el **por qué** justifica el valor, el **cómo** apunta a archivos y APIs concretas del código (no es una orden de implementación, es la pista).
- Marcadores: **`✅`** = hecho e integrado en `main`; el resto está **ordenado por valor** dentro de cada fase.
- **Regla de oro: offline-first.** Todo debe seguir funcionando 100% sin red y sin cuenta; Google Drive es un respaldo *opcional*. Las imágenes siempre viven locales (viajan embebidas dentro del `.inklus`, nunca como archivos sueltos).
- **Filosofía open source / gratis.** Inklus es una app gratuita y de código abierto. No hay funciones "premium" ni features tras paywall. Las dependencias externas deben ser gratuitas o tener tier gratuito generoso. Si algo requiere un servicio de pago, se documenta como opcional y la app funciona perfectamente sin ello.
- Antes de implementar cualquier tarea: leer `AGENTS.md` y respetar sus **flujos críticos (no romper)** — stylus/rechazo de palma, capas de pintado, deshacer, exportación y sincronización.

---

## ✅ Hecho (versión actual)

### Escritura y herramientas
- **Escritura con stylus**: detección de puntero, **rechazo de palma**, presión real, borrador automático con `invertedStylus`.
- **Zoom/pan con dos dedos** (el stylus nunca panea); trazo suavizado con `perfect_freehand`.
- **Herramientas**: lapicero, lápiz, resaltador, borrador (parte trazos), selección/mover/redimensionar imágenes.
- **Paleta + color personalizado (HSV)**, tamaño por herramienta, deshacer/rehacer.
- **Háptica del lápiz** (vibración sutil al empezar a escribir, configurable desde menú ⋮).

### Plantillas
- **Plantillas**: lienzo infinito, hoja A4, rayas, cuadrícula, plantilla propia (hoja fija o relleno infinito).
- **Personalización de plantillas**: color de línea (9 colores), separación de rayas/cuadrícula, tamaño de hoja (A4, Carta, B5, Half Ltr).

### Gestión de cuadernos y páginas
- **Biblioteca de cuadernos**: miniaturas de la primera página, crear/renombrar/duplicar/eliminar; migración automática del legacy `current_document.json`.
- **Buscar y ordenar cuadernos** en la biblioteca (búsqueda por título, orden por fecha/título).
- **Color de portada por cuaderno** (9 colores, selector visual).
- **Miniaturas de páginas** en el editor (franja inferior con miniaturas renderizadas).
- **Duplicar / reordenar páginas** (drag & drop en la franja de miniaturas).
- **Papelera** (recuperar cuadernos eliminados, vaciar papelera).
- **Importar `.inklus`** desde la biblioteca (abrir cuadernos compartidos).

### Persistencia y formato
- **Guardado local** JSON automático (debounce 600 ms, índice `index.json` + `documents/<id>.json`); páginas múltiples.
- **Formato propio `.inklus`** (`inklus_format.dart`): contenedor ZIP autocontenido por cuaderno (`document.json` + **imágenes embebidas**), como `.goodnotes`/`.sdoc`. Se exporta desde el menú ⋮ y es el formato del backup de Drive.
- **Respaldo local completo** (todos los cuadernos + imágenes en un ZIP, exportar/importar).

### Nube y exportación
- **Sincronización con Google Drive** (sin Firebase): signIn con scope `drive.file`, sesión silenciosa (One Tap), respaldo `<id>.inklus` en la carpeta 'Inklus' (upsert, no duplica), restore con extracción de imágenes.
- **Estado de sincronización visible**: iconos por cuaderno (sincronizado/sincronizando/error/deshabilitado) en biblioteca y top bar.
- **Restaurar entre versiones**: listar versiones de Drive con fecha/tamaño, elegir cuál restaurar.
- **Cifrado opcional del backup**: contraseña al subir/restaurar desde Drive (XOR con clave derivada).
- **Sync selectiva**: flag `syncEnabled` por cuaderno; solo se sincronizan los marcados.
- **Cambiar de cuenta**: signOut + re-signIn desde el menú ☁️.
- **Subir/bajar `.inklus` manual**: archivo `.inklus` del dispositivo a Drive y viceversa.
- **Notificaciones de sync**: snackbar al completar backup/restore automático.
- **Exportación**: página PNG/PDF, **cuaderno completo a PDF** (`renderNotebookPdf`), copia `.inklus`.
- **Exportación configurable**: DPI (1024–8192 px), fondo transparente, solo trazos, región personalizada.
- **Previsualización de exportación**: diálogo con vista previa antes de guardar PNG.
- **Compartir**: PNG/PDF/.inklus a otras apps via `share_plus`.
- **Exportar a SVG**: trazos como paths SVG editables (Inkscape/Illustrator).
- **OCR de tinta**: reconocimiento de texto escrito a mano on-device (solo Android/iOS, `google_mlkit_text_recognition`).

### UI y experiencia
- **Icono de la app** (adaptativo Android, `flutter_launcher_icons`) y **build de release** (`--split-per-abi`, ~20 MB).
- **Modo presentación / pizarra** (oculta todas las barras, solo lienzo; botón para salir).
- **Minimapa** en lienzos infinitos (overlay que muestra la posición del viewport en el mundo).

### DevOps
- **CI (GitHub Actions)**: `flutter analyze` + `flutter test` + `flutter build apk --debug` en cada push/PR.
- **.gitignore** completo para open source (esconde API keys, keystore, Firebase, .env).

## ✅ Decisiones tomadas (no re-abrir)

- **Todo gratis, sin premium.** Inklus es open source y no tendrá funciones de pago. Las features premium de apps competidoras (GoodNotes, Samsung Notes, Notability) se implementan aquí de forma gratuita.
- **Imágenes → locales, embebidas en `.inklus`**: nada se sube a servidores como archivos sueltos. El backup de Drive es un único archivo autocontenido por cuaderno.
- **Sin Firebase**: se eliminó por completo (causaba crash al arrancar: `FirebaseAuth.instance` sin `Firebase.initializeApp()`). Google Sign-In usa el `default_web_client_id` manual en `res/values/strings.xml`.
- **Offline-first**: el almacenamiento local es la fuente de verdad; Drive solo replica.
- **Conflictos de Drive: last-write-wins.** El documento con `updatedAt` más reciente gana. Simple, predecible, sin pérdida de contenido.
- **Cifrado de backup: XOR con clave derivada.** Evita lectura casual; no es criptografía de grado militar pero es suficiente para archivos personales. Sin dependencias externas.
- **Sync selectiva**: `NotebookMeta.syncEnabled` (null = true por defecto para compatibilidad).

---

## 🧭 Fase 1 — Gestión de cuadernos y páginas *(✅ COMPLETA)*

| # | Tarea | Estado |
|---|---|---|
| 1.1 | ✅ **Biblioteca de cuadernos** (miniaturas, CRUD) | Hecho |
| 1.2 | ✅ **Miniaturas de páginas** (franja inferior en el editor) | `page_thumbnails.dart` |
| 1.3 | ✅ **Duplicar / reordenar páginas** (drag & drop) | `canvas_controller.dart` + `page_thumbnails.dart` |
| 1.4 | ✅ **Opciones de plantilla** (color de línea, separación, tamaño de hoja) | `template_picker_sheet.dart` |
| 1.5 | ✅ **Buscar y ordenar cuadernos** en la biblioteca | `notebook_library.dart` |
| 1.6 | ✅ **Portada y color por cuaderno** | `NotebookMeta.colorValue` + UI |
| 1.7 | ✅ **Importar `.inklus`** desde la biblioteca | `notebook_library.dart` |
| 1.8 | ✅ **Papelera** (recuperar cuadernos eliminados) | `trash_screen.dart` + `StorageService` |

---

## ☁️ Fase 2 — Sincronización y nube *(✅ COMPLETA)*

| # | Tarea | Estado |
|---|---|---|
| 2.1 | ✅ **Google Drive + `.inklus`** | `DriveSyncService` con `drive.file`; backup/restore del contenedor `.inklus`. |
| 2.2 | ✅ **Estado de sincronización visible** | `SyncStatus` enum; iconos en tarjetas de la biblioteca y top bar del editor. |
| 2.3 | ✅ **Conflictos** (last-write-wins) | `restoreDocument()` compara `updatedAt`; la versión más reciente de Drive gana. |
| 2.4 | ✅ **Restaurar entre copias** | `listVersions()` lista archivos `.inklus` en Drive; menú ☁️ → "Ver versiones". |
| 2.5 | ✅ **Cifrado opcional del backup** | XOR con clave derivada de la contraseña; pedir contraseña al exportar/importar desde Drive. |
| 2.6 | ✅ **Cambiar de cuenta** | `switchAccount()` cierra sesión y abre selector de Google. |
| 2.7 | ✅ **Subir/bajar `.inklus` manual** | `uploadInklusFile()` sube un archivo elegido del dispositivo; menú ☁️ → "Subir archivo .inklus". |
| 2.8 | ✅ **Sync selectiva** | Flag `syncEnabled` en `NotebookMeta`; toggle en menú ☁️; backup automático respeta el flag. |
| 2.9 | ✅ **Notificación de sync** | `onSyncComplete` callback en `DriveSyncService`; snackbar en biblioteca y editor. |

---

## 📤 Fase 3 — Exportar y compartir *(✅ COMPLETA)*

| # | Tarea | Estado |
|---|---|---|
| 3.1 | ✅ **Cuaderno completo a PDF** | `ExportService.renderNotebookPdf` (una hoja PDF por página). |
| 3.2 | ✅ **Compartir** (PNG/PDF/.inklus a otras apps) | `share_plus` v13; menú ⋮ → compartir PNG/PDF/.inklus. |
| 3.3 | ✅ **Tamaño/DPI de exportación configurable** | `ExportOptions(maxDimension:)` con diálogo: baja/media/alta/máxima (1024–8192 px). |
| 3.4 | ✅ **Exportar región/selección** | `ExportOptions(region: Rect)` — renderiza solo un rect del mundo. |
| 3.5 | ✅ **Exportar a texto** (OCR) | `google_mlkit_text_recognition` on-device; solo Android/iOS; `OcrService.recognizeText()` con diálogo + copiar. |
| 3.6 | ✅ **Exportar sin fondo / con plantilla** | `ExportOptions(transparentBackground: true)` + `paintWorld(omitTemplate:)`. |
| 3.7 | ✅ **Exportar solo trazos** | `ExportOptions(strokesOnly: true)` + `paintWorld(omitImages:, omitTemplate:)`. |
| 3.8 | ✅ **Exportar a SVG** | `ExportService.renderPageSvg()` con `package:xml` v7; polígonos de `StrokeEngine.outlineFor` → paths SVG. |
| 3.9 | ✅ **Previsualización de exportación** | Diálogo con imagen previa antes de guardar (PNG); confirma o cancela. |

---

## ✍️ Fase 4 — Funciones avanzadas de escritura *(✅ COMPLETA)*

### 4A — Prioritarias (alto impacto, bajo esfuerzo)

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 4.1 | ✅ **OCR de tinta** | Hecho (3.5) | `google_mlkit_text_recognition` on-device. |
| 4.4 | ✅ **Rotación de imágenes** | Hecho | Campo `rotation` en `ImageItem` (+JSON), asa de rotación en selección, `canvas.rotate()` en `world_painter.dart`. |
| 4.5 | ✅ **Editor de presión/streamline** | Hecho | Panel deslizante en `stroke_options_sheet.dart` (thinning/smoothing/streamline por herramienta). |
| 4.9 | ✅ **Minimapa** | Hecho | `minimap.dart` (overlay en esquina inferior izquierda). |
| 4.10 | ✅ **Gestos y atajos** | Hecho | Doble toque con borrador físico = borrar página; deshacer con gesto de dos dedos. |
| 4.11 | ✅ **Biblioteca de plantillas propias** | Hecho | `TemplateLibraryService` guarda en `inklus/templates/`; listar en `template_picker_sheet.dart`. |
| 4.12 | ✅ **Modo presentación** | Hecho | Toggle en menú ⋮ que oculta todas las barras. |

### 4B — Intermedias (alto impacto, esfuerzo medio)

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 4.2 | ✅ **Selección con lazo** | Hecho | `ToolType.lasso`; hit-test ray-casting; marching ants; handles de escala/rotación. |
| 4.3 | ✅ **Figuras** (línea, rectángulo, círculo, flecha) | Hecho | `shape_detector.dart` post-procesa trazos al soltar; toggle activable. |
| 4.13 | ✅ **Copy & paste de trazos** | Hecho | Portapapeles interno en `CanvasController`; copiar/pegar selección del lazo. |
| 4.14 | ✅ **Snapping / guías magnéticas** | Hecho | `snap_guides.dart` detecta alineación; guías visuales azules al arrastrar imágenes. |

### 4C — Avanzadas (alto impacto, alto esfuerzo)

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 4.6 | ✅ **Transformar selección** | Hecho | Handles de escala/rotación sobre bounding box de trazos seleccionados; transformación afín + undo. |
| 4.7 | ✅ **Capas por página** | Hecho | `Layer` model en `page.dart`; visibilidad/bloqueo/renombrar; botón en tool rail. |
| 4.8 | ✅ **Cajas de texto** (teclado) | Hecho | `TextItem` model + `TextEditOverlay` + `ToolType.text`; editable in-place. |
| 4.15 | ✅ **Relleno de áreas** (bucket) | Hecho | `ToolType.bucket`; detecta trazo encerrado más cercano y rellena con color. |

---

## 🧪 Fase 5 — Calidad, plataformas y producto *(✅ COMPLETA)*

### 5A — Esenciales

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 5.1 | ✅ **Tests de lógica** | Hecho | 28 tests: eraser, undo, shape_detector, snap_guides, image_item rotation. |
| 5.5 | ✅ **Tema oscuro** | Hecho | `ThemeData(brightness: dark)` en `app.dart`; toggle en biblioteca; canvas respeta tema. |
| 5.6 | ✅ **i18n** (español/inglés) | Hecho | Strings migrados a ARB con `flutter_localizations`. |
| 5.13 | ✅ **Accesibilidad** | Hecho | Etiquetas `Semantics` en tool_rail, bottom_bar, menus. |
| 5.14 | ✅ **Tests de UI** | Hecho | Widget tests para biblioteca, editor, modelos. |

### 5B — Importantes

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 5.2 | ✅ **Rendimiento** | Hecho | Caché de polígonos en `StrokeEngine._outlineCache` (invalida al editar/borrar/deshacer). |
| 5.11 | ✅ **Optimización de renderizado** | Hecho | Compartido con 5.2; `contentVersion` evita repintado completo. |
| 5.10 | ✅ **Importar PDF como fondo** | Hecho | Menú ⋮ → Importar PDF; usa FilePicker para elegir archivo. |
| 5.12 | ✅ **Animaciones de transición** | Hecho | Transiciones suaves en navigator y cambio de modo presentación. |

### 5C — Plataformas y operación

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 5.3 | **iOS / macOS / Windows / Web** | Pendiente | Sin Firebase: `flutter create . --platforms=...`; revisar `google_sign_in`. |
| 5.9 | **Crash reporting opt-in** | Pendiente | Sentry free tier; solo con consentimiento; sin tracking. |

---

## 🚀 Fase 6 — Funciones estrella *(✅ COMPLETA)*

> Estas son las features que diferencian a las apps premium del mercado. En Inklus serán **gratuitas y open source**.

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 6.1 | ✅ **Audio sincronizado** | Hecho | Grabar micrófono + timestamps por trazo; reproductor con seek. |
| 6.2 | ✅ **Zoom writing** | Hecho | Recuadro fijo tipo Samsung Notes; auto-desplaza el lienzo al borde. |
| 6.3 | ✅ **Doble página** | Hecho | Dos páginas visibles en modo apaisado; render dual `paintWorld`. |
| 6.4 | ✅ **Plantillas especializadas** | Hecho | Pentagrama musical, agenda semanal, tracker de hábitos, dot grid. |
| 6.5 | ✅ **Historial de versiones local** | Hecho | Autoguardado con timestamps en `inklus/versions/`; restaurar desde UI. |
| 6.6 | **Widget de Android** | Pendiente | `home_widget` para acceso rápido al último cuaderno. |
| 6.7 | ✅ **Modo nocturno de escritura** | Hecho | Toggle en menú ⋮; canvas invierte colores sin cambiar tema UI. |
| 6.8 | ✅ **OCR en tiempo real** | Hecho | Streaming OCR con ML Kit; texto aparece al escribir. |

---

## 🔮 Fase 7 — Funciones de comunidad y ecosistema

> Todo open source, todo gratis. Estas funciones construyen comunidad alrededor de Inklus.

| # | Tarea | Estado | Por qué / cómo |
|---|---|---|---|
| 7.1 | **Etiquetas / tags por cuaderno** | Pendiente | Añadir etiquetas a los cuadernos y filtrar por ellas en la biblioteca. |
| 7.2 | **Smart folders** (carpetas dinámicas) | Pendiente | Carpetas que agrupan cuadernos automáticamente por etiquetas, fecha o color. |
| 7.3 | **Backlinks entre páginas** | Pendiente | Enlaces internos que conecten páginas del mismo cuaderno o entre cuadernos (tipo wiki). |
| 7.4 | **Marketplace de plantillas** | Pendiente | Repositorio open source de plantillas compartidas; los usuarios contribuyen y descargan. |
| 7.5 | **Plantillas con IA** | Pendiente | Generar plantillas personalizadas (agendas, horarios, trackers) a partir de una descripción de texto; usar un modelo local (Gemini Nano, etc.). |
| 7.6 | **Búsqueda en trazos** | Pendiente | Indexar resultados del OCR y permitir buscar dentro de los cuadernos por contenido escrito. |
| 7.7 | **Exportar a PowerPoint/Keynote** | Pendiente | Convertir páginas a diapositivas editables (cada página = una diapositiva). |
| 7.8 | **Estadísticas de escritura** | Pendiente | Minutos escritos, páginas creadas, trazos por día; gráficos en la biblioteca (todo local, sin servidores). |
| 7.9 | **Recordatorios** | Pendiente | Programar recordatorios vinculados a cuadernos específicos (alarma local del dispositivo). |
| 7.10 | **Integración con calendario** | Pendiente | Crear cuadernos vinculados a eventos del calendario del dispositivo. |

---

## 🔧 Convenciones para continuar

- Idioma de la UI y comentarios: **español**.
- Coordenadas de trazos: **mundo** (independientes del zoom); la vista aplica `scale`+`translate`.
- Toda mutación del documento pasa por `CanvasController` (única fuente de verdad, `ChangeNotifier`).
- Guardado local automático con debounce de 600 ms; Drive replica el mismo documento en formato `.inklus`.
- La app es **offline-first**: nunca romper el flujo local por una dependencia de red/cuenta.
- Todo es **gratis y open source**: no crear funciones premium ni dependencias de pago.
- Iconos: `dart run flutter_launcher_icons` (fuente en `assets/icon/`). Release: `flutter build apk --release --split-per-abi`.
- CI: `flutter analyze` + `flutter test` + `flutter build apk --debug` en GitHub Actions.
