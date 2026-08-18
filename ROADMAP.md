# 🗺️ Hoja de ruta — Inklus

> Estado del proyecto y próximos pasos. La **guía técnica para la IA** está en [`AGENTS.md`](AGENTS.md) (arquitectura, flujos críticos, gotchas); el manual de usuario/instalación en [`README.md`](README.md).

## 🧭 Cómo leer esta hoja de ruta (para la IA)

- Cada fila es una **tarea independiente** con su *por qué / cómo*: el **por qué** justifica el valor, el **cómo** apunta a archivos y APIs concretas del código (no es una orden de implementación, es la pista).
- Marcadores: **`✅`** = hecho e integrado en `main`; el resto está **ordenado por valor** dentro de cada fase.
- **Regla de oro: offline-first.** Todo debe seguir funcionando 100% sin red y sin cuenta; Google Drive es un respaldo *opcional*. Las imágenes siempre viven locales (viajan embebidas dentro del `.inklus`, nunca como archivos sueltos).
- Antes de implementar cualquier tarea: leer `AGENTS.md` y respetar sus **flujos críticos (no romper)** — stylus/rechazo de palma, capas de pintado, deshacer, exportación y sincronización.
- Orden sugerido: **Fase 1 → 2 → 3** son las de mayor valor actual (sin dependencias externas o integraciones simples); **4 → 6** son más experimentales y pueden esperar.

---

## ✅ Hecho (versión actual)

- **Escritura con stylus**: detección de puntero, **rechazo de palma**, presión real, borrador automático con `invertedStylus`.
- **Zoom/pan con dos dedos** (el stylus nunca panea); trazo suavizado con `perfect_freehand`.
- **Herramientas**: lapicero, lápiz, resaltador, borrador (parte trazos), selección/mover/redimensionar imágenes.
- **Plantillas**: lienzo infinito, hoja A4, rayas, cuadrícula, plantilla propia (hoja fija o relleno infinito).
- **Paleta + color personalizado (HSV)**, tamaño por herramienta, deshacer/rehacer.
- **Guardado local** JSON automático (debounce 600 ms, índice `index.json` + `documents/<id>.json`); páginas múltiples.
- **Selector de cuadernos** (biblioteca de inicio): miniaturas de la primera página, crear/renombrar/duplicar/eliminar; migración automática del legacy `current_document.json`.
- **Formato propio `.inklus`** (`inklus_format.dart`): contenedor ZIP autocontenido por cuaderno (`document.json` + **imágenes embebidas**), como `.goodnotes`/`.sdoc`. Se exporta desde el menú ⋮ y es el formato del backup de Drive.
- **Sincronización con Google Drive** (sin Firebase): signIn con scope `drive.file`, sesión silenciosa (One Tap), respaldo `<id>.inklus` en la carpeta 'Inklus' (upsert, no duplica), restore con extracción de imágenes.
- **Exportación**: página PNG/PDF, **cuaderno completo a PDF** (`renderNotebookPdf`), copia `.inklus`.
- **Icono de la app** (adaptativo Android, `flutter_launcher_icons`) y **build de release** (`--split-per-abi`, ~20 MB).

## ✅ Decisiones tomadas (no re-abrir)

- **Imágenes → locales, embebidas en `.inklus`**: nada se sube a servidores como archivos sueltos. El backup de Drive es un único archivo autocontenido por cuaderno.
- **Sin Firebase**: se eliminó por completo (causaba crash al arrancar: `FirebaseAuth.instance` sin `Firebase.initializeApp()`). Google Sign-In usa el `default_web_client_id` manual en `res/values/strings.xml`.
- **Offline-first**: el almacenamiento local es la fuente de verdad; Drive solo replica.

---

## 🧭 Fase 1 — Gestión de cuadernos y páginas *(alto valor, sin dependencias externas)*

| # | Tarea | Por qué / cómo |
|---|---|---|
| 1.2 | **Miniaturas de páginas** (franja inferior o panel lateral en el editor) | Reutilizar `ExportService.renderPagePng` (con `maxDimension` pequeño) por página; `goToPage` ya existe en `CanvasController`. |
| 1.3 | **Duplicar / reordenar páginas** | `Page.copyWith(id: nuevo)` para duplicar; arrastrar en la franja de miniaturas para reordenar (`Document.pages` es una lista mutable). |
| 1.4 | **Opciones de plantilla** (color de línea, separación, márgenes, tamaño de hoja) | `PageTemplate` ya tiene `lineColorValue`/`spacing`/`customW/customH`; falta la UI en `template_picker_sheet.dart`. |
| 1.5 | **Buscar y ordenar cuadernos** en la biblioteca | Filtro por título y orden por fecha/título/alfabético sobre `StorageService.loadIndex()`. |
| 1.6 | **Portada y color por cuaderno** | Añadir `color`/`cover` a `NotebookMeta` e `index.json`; mostrarlo en la tarjeta de la biblioteca. |
| 1.7 | **Importar `.inklus` desde la biblioteca** (abrir cuadernos compartidos) | Botón en la biblioteca → `FilePicker.pickFiles()` → `InklusFormat.importBytes` → guardar con `StorageService.save`. |
| 1.8 | **Papelera** (recuperar cuadernos eliminados) | `StorageService.delete` hoy borra en firme; mover a una carpeta `trash/` con fecha y purgar tras N días. |

## ☁️ Fase 2 — Sincronización y nube (Google Drive)

| # | Tarea | Por qué / cómo |
|---|---|---|
| 2.1 | ~~Estrategia de imágenes~~ **✅ Google Drive + `.inklus`** | Hecho: `DriveSyncService` (singleton `ChangeNotifier`) con `drive.file`; backup/restore del contenedor `.inklus`. Requiere Drive API habilitada + scope en consentimiento OAuth (README). |
| 2.2 | **Estado de sincronización visible** (icono subiendo/sincronizado/error por cuaderno) | Hookear `controller.onRemoteSync` (hoy silencioso) y exponer estado en `DriveSyncService`; mostrar en biblioteca y top bar. |
| 2.3 | **Conflictos** (dos dispositivos editan lo mismo) | Decisión de diseño: *last-write-wins* (fácil) vs merge por página (complejo). Documentar la elegida en AGENTS.md. |
| 2.4 | **Restaurar entre copias** (elegir entre las últimas N, no solo la más reciente) | En Drive: guardar versiones como `<id>_<fecha>.inklus` o usar el historial de revisiones; listar en la UI del menú ☁️. |
| 2.5 | **Cifrado opcional del backup** (`.inklus` con contraseña) | `archive` soporta `ZipEncoder(password:)` / `ZipDecoder().decodeBytes(bytes, password:)`; pedir contraseña al exportar/importar y guardarla nunca (solo hash para validar). |
| 2.6 | **Cambiar de cuenta / varias cuentas** | `GoogleSignIn.instance` mantiene una cuenta; añadir selector y re-autenticar (`signOut` + `signIn`). |
| 2.7 | **Subir/bajar `.inklus` manual** desde el menú ☁️ | Exportar el contenedor a Drive como archivo visible o importar uno elegido; reutiliza `InklusFormat`. |

## 📤 Fase 3 — Exportar y compartir

| # | Tarea | Por qué / cómo |
|---|---|---|
| 3.1 | ~~Cuaderno completo a PDF~~ **✅ Hecho** | `ExportService.renderNotebookPdf` (una hoja PDF por página, reusa `renderPagePng`). |
| 3.2 | **Compartir** (PNG/PDF/.inklus a otras apps) | Añadir `share_plus`; en Android `FilePicker.saveFile` ya devuelve URI — `share_plus` permite el share sheet directo. |
| 3.3 | **Tamaño/DPI de exportación configurables** | Parametrizar `renderPagePng` (hoy usa el mundo 1:1); añadir opción en el diálogo de exportar. |
| 3.4 | **Exportar región/selección** | Renderizar solo un `Rect` del mundo (ya lo soporta `paintWorld(visibleWorldRect:)`); recortar con la herramienta de selección. |
| 3.5 | **Exportar a texto** (OCR) | Mismo motor que 4.1; renderizar la página a imagen y pasarla al reconocedor, devolver texto. |
| 3.6 | **Exportar sin fondo / con plantilla** | Flag para omitir plantilla e imágenes de fondo en `paintWorld` (hoy pinta todo siempre). |

## ✍️ Fase 4 — Funciones avanzadas de escritura

| # | Tarea | Por qué / cómo |
|---|---|---|
| 4.1 | **OCR de tinta** (escritura → texto) | `google_mlkit_text_recognition` (on-device, gratis); seleccionar región con la herramienta de selección. |
| 4.2 | **Selección con lazo** (mover/borrar/copiar trazos) | Modo lasso en `ToolType`; hit-test contra puntos de trazos (`StrokePoint`); reutilizar el patrón de `CanvasAction` para deshacer. |
| 4.3 | **Figuras** (línea, flecha, rectángulo, círculo) | Post-procesar el trazo al soltar (aproximación a forma perfecta) o modo dedicado; guardar como `Stroke` normal. |
| 4.4 | **Rotación de imágenes** | `ImageItem` no tiene rotación; añadir campo `rotation` (+JSON) y asa de rotación en la selección. |
| 4.5 | **Editor de presión/streamline** (tipo Procreate) | Exponer `StrokeOptions` de `perfect_freehand` (thinning/smoothing/streamline) por herramienta. |
| 4.6 | **Transformar selección** (escalar/rotar/mover trazos) | Sobre la selección con lazo: aplicar transformación afín a los puntos y empujar una sola `CanvasAction`. |
| 4.7 | **Capas por página** (ocultar/bloquear/mover) | `Page` necesitaría una lista de capas; requiere migración de JSON (cuidado con la compatibilidad del `.inklus`). |
| 4.8 | **Cajas de texto** (teclado) | Nuevo tipo de item (`TextItem`) en el lienzo con `TextField` overlay; añadir al JSON y al `.inklus`. |
| 4.9 | **Lupa / minimapa** en lienzos infinitos | Overlay pequeño que muestra la posición del viewport en el mundo (útil al hacer zoom). |
| 4.10 | **Gestos y atajos** | Doble toque con borrador físico, mantener para borrador temporal, gesto de deshacer con dos dedos… en `drawing_canvas.dart`. |
| 4.11 | **Biblioteca de plantillas propias** | Guardar plantillas custom reutilizables (`inklus/templates/`) y listarlas en `template_picker_sheet.dart`. |
| 4.12 | **Modo presentación / pizarra** | Ocultar barras y dejar solo el lienzo (fullscreen); útil para clases/reuniones. |

## 🧪 Fase 5 — Calidad, plataformas y producto

| # | Tarea | Por qué / cómo |
|---|---|---|
| 5.1 | **Tests de lógica** (borrador, deshacer, transformación, exportación) | `eraser.dart`, `undo_stack.dart` y `InklusFormat` ya son testables en Dart puro; ampliar `test/`. |
| 5.2 | **Rendimiento en documentos grandes** | Cachear polígonos de `getStroke` por trazo (invalidar al editar); hoy se recalculan en cada pintado. |
| 5.3 | **iOS/macOS/Windows/Web** | Sin Firebase ya: `flutter create . --platforms=...`; revisar `google_sign_in` por plataforma (Linux no lo soporta — la app ya lo protege con try/catch). |
| 5.4 | **CI (GitHub Actions)** | `flutter analyze` + `flutter test` + `flutter build apk --release` en cada push/PR. |
| 5.5 | **Tema oscuro** | `ThemeData(brightness: dark)` en `app.dart`; revisar colores hardcodeados (`0xFFEFEDE8`, papel, etc.). |
| 5.6 | **i18n** (español/inglés) | La UI está 100% en español con strings inline; migrar a `flutter_localizations` + ARB. |
| 5.7 | **Respaldo local completo** (todos los cuadernos en un archivo) | ZIP del `index.json` + todos los `documents/*.json` (+ imágenes) → exportar/importar como copia de seguridad total. |
| 5.8 | **Háptica del lápiz** (vibración sutil al escribir) | `HapticFeedback.selectionClick()` en `endStroke` o al empezar; configurable. |
| 5.9 | **Crash reporting opt-in** | Sentry o similar (investigar con Gravity Index antes de integrar); solo con consentimiento del usuario. |
| 5.10 | **Importar PDF/imagen como fondo** | Convertir PDF a imagen (o `pdf` page → raster) y usarlo como plantilla custom. |

## 🚀 Fase 6 — Experiencia y funciones estrella

| # | Tarea | Por qué / cómo |
|---|---|---|
| 6.1 | **Audio sincronizado con la escritura** (tipo Notability) | Grabar micrófono y guardar marcas de tiempo por trazo; requiere campo nuevo en `Stroke` + reproductor. |
| 6.2 | **Recuadro de escritura ampliado** (zoom de escritura tipo Samsung Notes) | Escribir en un recuadro fijo que auto-desplaza el lienzo; gesto sencillo: al acercarse al borde, pan automático. |
| 6.3 | **Doble página / modo apaisado** | Dos `Page` visibles a la vez (render con dos `paintWorld`); útil en tablet en horizontal. |
| 6.4 | **Plantillas especializadas** (pauta Montessori, pentagrama, agenda, semanal) | Nuevos `TemplateType` o plantillas custom pre-cargadas; dibujo adicional en `world_painter.dart`. |
| 6.5 | **Historial de versiones en Drive** (autoguardado por fecha) | En cada backup, si pasó X tiempo, crear `<id>_<fecha>.inklus` además del principal; restaurar cualquiera (ver 2.4). |
| 6.6 | **Widget de la app** (acceso rápido al último cuaderno) | Widget de Android (GLU/`home_widget`) que abre el cuaderno más reciente. |

---

## 🔧 Convenciones para continuar

- Idioma de la UI y comentarios: **español**.
- Coordenadas de trazos: **mundo** (independientes del zoom); la vista aplica `scale`+`translate`.
- Toda mutación del documento pasa por `CanvasController` (única fuente de verdad, `ChangeNotifier`).
- Guardado local automático con debounce de 600 ms; Drive replica el mismo documento en formato `.inklus`.
- La app es **offline-first**: nunca romper el flujo local por una dependencia de red/cuenta.
- Iconos: `dart run flutter_launcher_icons` (fuente en `assets/icon/`). Release: `flutter build apk --release --split-per-abi`.
