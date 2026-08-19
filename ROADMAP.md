# 🗺️ Hoja de ruta — Inklus

> Estado del proyecto y próximos pasos. La **guía técnica para la IA** está en [`AGENTS.md`](AGENTS.md) (arquitectura, flujos críticos, gotchas); el manual de usuario/instalación en [`README.md`](README.md).

## 🧭 Cómo leer esta hoja de ruta (para la IA)

- Cada fila es una **tarea independiente** con su *por qué / cómo*: el **por qué** justifica el valor, el **cómo** apunta a archivos y APIs concretas del código (no es una orden de implementación, es la pista).
- Marcadores: **`✅`** = hecho e integrado; **`🔧`** = parcial / stub; el resto está **ordenado por valor** dentro de cada fase.
- **Regla de oro: offline-first.** Todo debe seguir funcionando 100% sin red ni cuenta; Google Drive es un respaldo *opcional*.
- **Filosofía open source / gratis.** No hay funciones "premium". Las dependencias externas deben ser gratuitas.

---

## ✅ Lo que la app ofrece hoy

> Verificado contra el código fuente (29,437 líneas Dart, 82 tests pasando).

### ✨ UX y Onboarding
- **Onboarding tutorial**: 4 páginas ilustradas skippable al primer inicio; persiste con `SharedPreferences`.
- **Biblioteca rediseñada**: empty state con call-to-action, menú ⋮ con tema/ordenar/configuración, carpetas inteligentes, etiquetas.
- **Pantalla de configuración**: Google Drive (conectar/desconectar), tema claro/oscuro, backup local, acceso a estadísticas y recordatorios.
- **Barra de herramientas (tool rail)**: diseño flotante con bordes redondeados, separadores visuales, animaciones de selección.
- **Bottom bar rediseñada**: paleta de colores + slider de tamaño en dos filas, iconos toggle para formas/dedo, acciones de lazo.
- **Template picker**: secciones "Lienzo infinito" y "Hoja fija", tiles con preview, selector de formato al crear Note.
- **Portada de cuaderno**: primera página se usa como miniatura en la biblioteca.

### ✍️ Escritura y herramientas (10 herramientas)
- **Escritura con stylus**: detección de puntero, **rechazo de palma**, presión real, borrador automático con `invertedStylus`.
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
- **Respaldo local completo** (todos los cuadernos + imágenes en un ZIP).

### ☁️ Sincronización con Google Drive
- **Offline-first**: signIn con `drive.file`, sesión silenciosa (One Tap), backup automático silencioso.
- **Sync individual por Note**: cada Note se sincroniza como `.inklus` separado (minimiza tráfico y conflictos).
- **Estado visible**: iconos por Notebook (sincronizado/sincronizando/error/deshabilitado).
- **Cifrado AES-256-GCM**: `cryptography` v2.9, PBKDF2 100k iteraciones (reemplaza XOR legacy).
- **Conflictos**: selección de versión cuando hay múltiples copias en Drive.
- **Historial de revisiones**: listar versiones de una Note en Drive y restaurar.
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
- **Minimapa** en lienzos infinitos.
- **Regla visible** desde tool rail (overlay sobre canvas).
- **Lupa** (overlay flotante, se cierra al soltar).
- **Modo presentación / pizarra** (oculta todas las barras).

### 📱 Funciones de comunidad y ecosistema
- **Backlinks entre páginas** (`TextItem.linkToPageId` + `BacklinkService`).
- **Estadísticas de escritura** (`WritingStatsService` + pantalla con gráfico, rachas).
- **Recordatorios** vinculados a cuadernos (`ReminderService`).
- **Integración con calendario** (`CalendarService`).

### 📤 Importación
- **Import de PDF como fondo** (`PdfImportService`): renderiza PDF → imagen con `printing` (Android/iOS); se aplica como plantilla custom infinita.

### ⌨️ Atajos de teclado
- **Ctrl+Z**: deshacer.
- **Ctrl+Shift+Z / Ctrl+Y**: rehacer.
- **Ctrl+C**: copiar selección.
- **Ctrl+V**: pegar.

### 🧪 Calidad y DevOps
- **82 tests** pasando (modelos, storage, migración, CRUD, formatos, lógica).
- **CI (GitHub Actions)**: `flutter analyze` + `flutter test` + `flutter build apk --debug`.
- **Tema oscuro** adaptado (scaffold, top bar, bottom bar, tool rail, biblioteca).
- **i18n** (español/inglés con ARB).
- **Accesibilidad** (etiquetas `Semantics`).
- **Animaciones de transición** suaves.
- **Optimización de renderizado** (`RepaintBoundary` + `contentVersion`).
- **Caché de polígonos** en `StrokeEngine`.

---

## 🔧 Lo que falta

### 🔴 Prioritario (antes de launch)

| # | Tarea | Fase | Descripción |
|---|---|---|---|
| 1 | **Respaldo local de Notes** | Persistencia | `exportFullBackup`/`importFullBackup` exportan Documents, no el nuevo formato `notebooks/` + `notes/`. Adaptar para que el backup local incluya la jerarquía completa. |
| 2 | **Papelera de Notes** | CRUD | `loadTrash`/`restoreFromTrash` solo manejan Documents. Adaptar paraNotes y Notebooks por separado. |
| 3 | **Test B5: luminosidad** | Calidad | Test que verifique que `paperColorDark` (#424242) tiene mayor luminosidad que `deskColorDark` (fondo del canvas en modo oscuro). |
| 4 | **iOS / macOS / Windows / Web** | Plataformas | `flutter create . --platforms=...`; revisar `google_sign_in`, `printing` (PDF import), ML Kit por plataforma. |
| 5 | **Crash reporting opt-in** | Ops | Sentry free tier; solo con consentimiento explícito; sin tracking. |

### 🟡 Importante (mejoras de UX)

| # | Tarea | Fase | Descripción |
|---|---|---|---|
| 6 | **Widget de Android** | Estrella | `home_widget` para acceso rápido al último cuaderno desde la pantalla de inicio. |
| 7 | **Historial de versiones local real** | Estrella | Actualmente `_showVersionHistory()` es un stub (snackbar). Implementar guardado en `inklus/versions/` con timestamps y UI para restaurar. |
| 8 | **Audio sincronizado** | Estrella | Grabar micrófono + timestamps por trazo; reproductor con seek. Requiere paquete `record`. |
| 9 | **Zoom writing** | Estrella | Recuadro fijo tipo Samsung Notes; auto-desplaza el lienzo al borde. |
| 10 | **Doble página** | Estrella | Dos páginas visibles en modo apaisado; render dual `paintWorld`. |
| 11 | **Modo nocturno de escritura real** | Estrella | Actualmente solo muestra un snackbar. Implementar inversión de colores del canvas sin cambiar el tema UI. |

### 🟢 Diferenciadores (largo plazo)

| # | Tarea | Fase | Descripción |
|---|---|---|---|
| 12 | **Plantillas con IA** | Comunidad | Generar plantillas personalizadas a partir de descripción de texto; usar Gemini Nano local. |
| 13 | **OCR en tiempo real (streaming)** | Comunidad | Actualmente `recognizeStrokes()` es on-demand. Extender a reconocimiento continuo mientras se escribe. |

---

## 📊 Métricas del proyecto

| Métrica | Valor |
|---|---|
| Archivos Dart (lib/) | ~55 |
| Líneas de código | ~29,400 |
| Tests | 82 (todos pasando) |
| Modelos | 9 (`document`, `note`, `notebook`, `page`, `stroke`, `template`, `image_item`, `text_item`, `id`) |
| Servicios | 14 |
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
- CI: `flutter analyze` + `flutter test` + `flutter build apk --debug` en GitHub Actions.
- Onboarding: se guarda en `SharedPreferences('onboarding_seen')` = false tras completar.
- **ToolType** tiene 10 valores: `pen`, `pencil`, `highlighter`, `calligraphy`, `brush`, `eraser`, `select`, `lasso`, `bucket`, `text`.
- **Stroke.shapeType** persiste la forma detectada (`line`, `arrow`, `rectangle`, `circle`).
- **Jerarquía de datos**: `Notebook` → `Note` → `Page` → `Stroke/ImageItem/TextItem`.
- **Sync**: cada Note se sincroniza individualmente como `<noteId>.inklus` en Drive.
