# 🤖 Guía técnica para continuar Inklus

App de escritura a mano para tablets con stylus (tipo GoodNotes), **Flutter 3.47 / Dart 3.13**, Material 3, UI y comentarios en **español**. Targets: **Android** (principal) + **Linux desktop** (dev).

> Documentación general: [`README.md`](README.md) · Próximos pasos: [`ROADMAP.md`](ROADMAP.md)

## Comandos

```bash
flutter pub get
flutter analyze            # debe quedar en 0 issues
flutter test               # test/*.dart: modelos, storage, backup, cifrado, lienzo, historial
flutter run -d linux       # desarrollo en escritorio
flutter run                # tablet Android conectada
flutter build apk --debug  # APK → build/app/outputs/flutter-apk/
dart run flutter_launcher_icons   # regenerar iconos desde assets/icon/
```

## Arquitectura (lib/)

```
models/      Notebook → Note → Page → Stroke/ImageItem/TextItem; PageTemplate, Layer,
             id.dart (newId: reloj+contador+aleatorio). Document = SOLO legacy/migración.
             Stroke es INMUTABLE: editar = crear otra instancia (copyWith/translated);
             cachea pointBounds/paintBounds y guarda thinning/smoothing/streamline (null = defaults)
             Page.bookmarked; TextItem con formato (bold/italic/underline/align/fontFamily)
logic/
  canvas_controller.dart   ★ Estado central ChangeNotifier: herramienta/color/tamaño, vista,
                             trazo activo, deshacer, páginas (+marcadores), guardado, capas,
                             selección del lazo (trazos + imágenes + textos), figuras
                             (ShapeMode: off/hold/always), láser, regla, borrador (EraserMode)
  pen_presets.dart         plumas favoritas (3 + resaltador) con color/grosor propios, persistentes
  palm_rejection.dart      política pura de rechazo de palma (lápiz apoyado/cerca, hover, contacto)
  ruler.dart               geometría pura de regla/transportador (tamaño fijo en pantalla, imán)
  stroke_engine.dart       perfect_freehand: polígono/Path por trazo cacheados con Expando
  eraser.dart              borrado parcial: parte el trazo en fragmentos (conserva orden)
  undo_stack.dart          CanvasAction (+ strokeDiff con índices) y applyOrderedSwap (z-order)
  lasso.dart / bucket_fill.dart / shape_detector.dart / snap_guides.dart  geometría pura
services/
  storage_service.dart     ★ índice v2 + notebooks/ + notes/; escrituras atómicas, cola del
                             índice, recuperación de índice corrupto, backup completo, favoritos
  file_utils.dart          writeAtomic, writeJsonAtomic (isolate para notas grandes), safeJoin/
                             safeFileName, decodeJsonAsync, SerialQueue
  backup_crypto.dart       AES-256-GCM + PBKDF2 en isolate
  search_service.dart      índice de búsqueda v2 por nota (título, texto tecleado, escritura
                             reconocida); sin acentos; SearchService.instance compartido
  version_history_service.dart  historial local: versions/<noteId>/<ms>.json.gz (máx. 20)
  marketplace/             ★ marketplace_models.dart + marketplace_service.dart: catálogo por CDN
                             (caché y catálogo incluido sin red), instalación con sha256,
                             plantillas/paletas/stickers instalados
  image_service.dart       copia archivos a la app + BoundedImageCache (LRU)
  export_service.dart      PNG/PDF/PPTX/SVG fuera de pantalla (reusa paintWorld)
  inklus_format.dart       ★ formato .inklus (ZIP autocontenido)
  drive_sync_service.dart  ★ Google Drive offline-first (drive.file)
  pdf_import_service.dart  importPages: una página de la nota por página del PDF
  import_service.dart      importación única: detecta por CONTENIDO .inklus v1/v2 o respaldo
                             completo (acepta .inklus.zip renombrados por Android)
  template_library_service.dart  "Mis plantillas" (imágenes propias)
ui/
  theme/                   ★ app_theme.dart (ThemeData claro/oscuro), inklus_colors.dart
                             (ThemeExtension + context.inklus/colors/text/isDark), tokens.dart
                             (Spacing, Radii, Motion, Sizes, Breakpoints)
  editor/                  editor_toolbar (barra única), tool_popovers (pluma/borrador/color),
                             anchored_popover, selection_bar, pages_panel, editor_shortcuts,
                             tool_visuals (icono+nombre por herramienta)
  notebook_library.dart    inicio: navegación lateral (Todos/Recientes/Favoritos/Carpetas/
                             Marketplace), búsqueda (+ en contenido), cuadrícula/lista
  marketplace_screen.dart  explorar / instalar paquetes
  home_screen.dart         editor: EditorToolbar + lienzo + SelectionBar + PagesPanel + zoom/páginas
  canvas/                  drawing_canvas (entrada), world_painter (pintado compartido con export),
                             canvas_overlays (regla, lupa)
  widgets/                 controller_selector, dialogs (showTextPrompt, runWithLoading),
                             search_sheet, custom_color_dialog, text_edit_overlay, inklus_logo,
                             page_scaffold (InklusPage, PageHeader, SectionCard, SettingsTile,
                             EmptyState, SheetHeader: base de las pantallas secundarias)…
tool/screenshots/          capturas de la UI real sin dispositivo (fuera de la suite de tests)
marketplace/               plantilla del repo inklus-marketplace (validador + CI + ejemplos)
```

## 🎨 Reglas de interfaz (lavado de cara)

- **Colores**: solo desde `context.colors` (ColorScheme) o `context.inklus` (InklusColors). Nada de
  `Colors.white`/`Color(0x…)` sueltos en widgets nuevos. `ThemeColors` existe por compatibilidad.
- **Medidas**: `Spacing`, `Radii`, `Sizes`, `Motion` de `ui/theme/tokens.dart`; objetivo táctil ≥ 48 dp.
- **Texto**: roles de `context.text` (la escala está ajustada para tablet); nada por debajo de 12 pt.
- **Rebuilds**: widgets que dependen del controlador usan `ControllerSelector` con el valor mínimo
  que muestran (el controlador notifica en cada punto del trazo).
- **Opciones de herramienta**: en popovers anclados (`showAnchoredPopover`), no en barras fijas.
- Revisar cambios visuales con `flutter test tool/screenshots/screenshots_test.dart`.

## ★ Flujos críticos (no romper)

### 1. Stylus y rechazo de palma — `drawing_canvas.dart` + `logic/palm_rejection.dart`
- Un `Listener` **crudo** recibe TODOS los eventos (no participa en la gesture arena), incluido `onPointerHover` (el hover del lápiz marca "lápiz cerca").
- `PalmRejection` (pura, testeada): un toque se descarta si hay lápiz apoyado, flotando cerca, levantado hace <400 ms, o si `radiusMajor` es grande. Al apoyar el lápiz, `_rejectPalmInProgress()` cancela el trazo/pan que estuviera haciendo un dedo.
- El estado del lápiz se actualiza **al principio** de `_onPointerUp/_onPointerCancel` (antes de cualquier `return`): si no, se quedaba "apoyado" para siempre.
- `invertedStylus` o `kSecondaryStylusButton` (botón del S-Pen) = borrador para ese trazo. **No** hay atajos destructivos con el lápiz.
- `controller.onStylusDetected()`: la primera vez pasa a *solo lápiz* (`fingerDrawingEnabled=false`, persistido); entonces **un dedo desplaza** la página (`_oneFingerPans`) y dos dedos hacen zoom. El zoom es incremental (sin saltos al entrar/salir dedos).
- Regla (`logic/ruler.dart`): tamaño fijo en pantalla; un dedo sobre ella la arrastra y un segundo dedo la rota (`_rulerPointers`); el trazo se engancha a un borde solo si **empieza** a <26 px de él (`RulerGeometry.snapFor/project`).
- Conversión: `world = (local - translate) / scale` (métodos `viewportToWorld`/`worldToViewport` del controlador). La hoja fija está **centrada en el origen** del mundo (`fitView`, `paintWorld`, exportación y regla lo asumen).

### 2. Capas de pintado — `drawing_canvas.dart` (CanvasPainter / ActiveLayerPainter)
- **Capa confirmada** (plantilla+imágenes+trazos) dentro de `RepaintBoundary`. Su `shouldRepaint` compara `contentVersion` (se incrementa en `_touch()`) + `scale`/`translate`/`sheetSize`/`imageCache`: si solo cambia el trazo activo, NO repinta (ahí está la optimización).
- **Capa activa** (trazo en curso, cursor borrador, selección) encima, `shouldRepaint => true` siempre. El trazo en curso usa una lista de puntos mutable (añadir = O(1)); al soltar se congela (`List.unmodifiable`).
- `page` se muta en sitio (nunca se reemplaza la instancia), por eso el versionado es por contador, no por identidad. `_touch()` = cambio real (repinta + agenda guardado); `_touchLive()` = arrastre en vivo (solo repinta; se guarda en el commit).
- `paintWorld` hace **culling** con `stroke.paintBounds` y aplica opacidad de capa con un `saveLayer` por tramo de capa (`_LayerPainter`). La caché de imágenes expone `version` para que `CanvasPainter` repinte al terminar de decodificar.
- El editor NO reconstruye la pantalla en cada punto: `ControllerSelector` + notificadores granulares (`toolContextNotifier`/`bottomBarContextNotifier`, que `notifyListeners()` dispara solo si cambió lo que muestran).

### 3. Deshacer/rehacer — `undo_stack.dart` + `canvas_controller._applyAction`
- Cada operación empuja un `CanvasAction` con `strokesAdded/Removed` + `imagesAdded/Removed` + `textItemsAdded/Removed`. `_applyAction` usa `applyOrderedSwap`: si un añadido tiene el mismo id que un quitado se reemplaza **en su posición**; si la acción trae `strokesRemovedAt/AddedAt` (borrador, eliminar selección → `CanvasAction.strokeDiff`) se reinserta por índice. Nunca `addAll` al final (cambiaría el z-order). Imágenes: `updateImageLive` durante el arrastre (sin acción) y `commitImageChange(before, after)` al soltar (una sola acción).
- Al crear trazos derivados usar SIEMPRE `copyWith`/`translated` (conservan capa, figura, relleno y ajustes); `Stroke(...)` a mano pierde atributos.

### 4. Exportación — `export_service.dart`
- `paintWorld` (en `world_painter.dart`) pinta plantilla+imágenes+trazos en un rect dado; el lienzo la llama con el rect visible transformado y la exportación con el rect del contenido → lo que ves = lo que exportas.
- `renderPagePng` DEBE hacer `canvas.translate(-bounds.left, -bounds.top)`: los límites empiezan en negativo (hoja centrada). Hay test de regresión (`test/export_test.dart`).
- `paintWorld(viewScale:)`: grosor de líneas de plantilla constante en pantalla y nivel de detalle (`_lodSpacing`) para patrones infinitos al alejar el zoom.

### 5. Editor, plumas y selección
- `EditorToolbar`: tocar una herramienta la activa; tocarla **otra vez** abre su popover.
- `PenPresetsController.activate()` aplica pluma (con guarda `_applying` para no copiar el color de la
  anterior); `HomeScreen` escucha `bottomBarContextNotifier` y llama a `syncFrom` para guardar cambios.
- Lazo: trazos por instancia, imágenes y textos **por id**; mover guarda instantánea al primer frame y
  `commitMoveStrokes` empuja una única acción. Escalar/rotar, copiar/pegar y color: solo trazos.

### 6. Marketplace y búsqueda
- `MarketplaceService.validatePack` = reglas de `marketplace/bin/build_catalog.dart` (mantener iguales).
- Instalar: descargar → comprobar tamaño y sha256 → `writeAtomic`; si algo falla se borra el paquete.
- `SearchService.indexNote` al abrir/salir de una nota; la escritura reconocida (OCR, "Indexar
  escritura", "Convertir a texto") se guarda con `setHandwriting` y se conserva al reindexar.

### 7. Sincronización — `drive_sync_service.dart` (Google Drive, offline-first)
- **Singleton** `DriveSyncService.instance` (`ChangeNotifier`): la sesión se comparte entre biblioteca y editor; el ☁️ escucha con `Listenable.merge([controller, service])`.
- `signIn()`: `GoogleSignIn.instance.authenticate(scopeHint: [drive.file])`. El **access token NO viene en `authentication`** (v7 solo trae idToken): se pide con `account.authorizationClient.authorizeScopes([drive.file])` (interactivo) o `authorizationForScopes` (silencioso, puede devolver null).
- Toda llamada a `GoogleSignIn.instance` va precedida de `await _ensureInitialized()` (`initialize(serverClientId:)` una sola vez; reintentable si falla).
- `restoreSession()` (silenciosa, One Tap) se llama al arrancar en `NotebookLibraryScreen`.
- `restoreLibrary(storage)` (Configuración → "Restaurar desde Drive"): last-write-wins por nota; las que no existen en local van a un cuaderno nuevo "Recuperado de Drive". `_BearerClient` aplica timeout de 60 s.
- Backup: carpeta 'Inklus' en Drive, un archivo `<note.id>.inklus` por nota (upsert, no duplica) en el formato propio `InklusFormat` (documento + **imágenes embebidas** → el backup es autocontenido). Restore: lista la carpeta, importa cada `.inklus` (extrae imágenes a `<appSupport>/inklus/restored/<id>/`) y elige la más reciente por `updatedAt`. `googleapis` 16 (`drive/v3.dart`): `files.create/update` con `uploadMedia: commons.Media`; descarga con GET `alt=media` vía `_BearerClient` (http).
- Backup automático = silencioso (si el scope no está autorizado se omite, el local ya protege); 'Subir ahora' usa `promptForConsent: true` (puede mostrar consentimiento).
- La UI se entera vía `controller.onRemoteSync` (callback en cada guardado local; `HomeScreen` lo agrupa: máx. una subida cada 20 s + al salir) y `controller.replaceNote(note)` tras restaurar.
- Salir del editor: `_goBack()`/`PopScope` hacen `await controller.flush()` antes del `pop` (la biblioteca lee el índice ya actualizado); `HomeScreen.dispose` hace `controller.dispose()`.
- Exportación (menú ⋮ del editor): página PNG/PDF, **cuaderno PDF** (`renderNotebookPdf`) y **copia .inklus** (`InklusFormat.exportBytes` → `FilePicker.saveFile`).

## 🚨 Gotchas de versiones (ya resueltas, no revertir)

- **file_picker 12**: API estática — `FilePicker.pickFiles()` → `List<PlatformFile>`, `FilePicker.pickFile()` → `PlatformFile?`, `FilePicker.saveFile({fileName, bytes})` → `Uri?`. **No existe** `FilePicker.platform`.
- **google_sign_in 7**: exige `GoogleSignIn.instance.initialize(serverClientId: <cliente web>)` **una vez y esperado** antes de cualquier otra llamada (si no: "serverClientId must be provided"). `GoogleSignIn.instance.authenticate({scopeHint})` / `attemptLightweightAuthentication()` (One Tap). `authentication` solo trae `idToken`; el access token se pide con `authorizationClient.authorizeScopes/authorizationForScopes`. `default_web_client_id` está **manualmente** en `android/app/src/main/res/values/strings.xml` (ya no lo genera google-services; no usar Firebase).
- **googleapis 16 / `_discoveryapis_commons`**: `drive.DriveApi(client)` con `uploadMedia: commons.Media(Stream.value(bytes), len, contentType:)`; `files.update(File request, String fileId, ...)` (¡el request va primero!). googleapis_auth no exporta su `AuthenticatedClient` → usar `_BearerClient` propio sobre `http`.
- **No Firebase**: la app no inicializa ni depende de Firebase (se eliminó). Si se reintroduce, `main.dart` debe llamar a `Firebase.initializeApp()` antes de tocar `FirebaseAuth.instance` (causa del crash al arrancar).
- **perfect_freehand 2.5.2**: `getStroke(List<PointVector>, options:)` → `List<Offset>` (polígono). `StrokeOptions` tiene `size/thinning/smoothing/streamline/simulatePressure/start/end/isComplete` (sin `roughness`). En `stroke_engine.dart` se importa con `hide StrokePoint` (colisión con nuestro modelo).
- **pdf 3.x**: `pw.Document`, `pw.Page(pageFormat: PdfPageFormat...)`, `pw.MemoryImage(pngBytes)`.
- **Google Drive API** debe estar habilitada en el proyecto Google Cloud (`inklus`) y el scope `drive.file` en la pantalla de consentimiento OAuth; sin eso, sign-in da error `403 accessNotConfigured`.
- `MaterialApp` de Flutter exporta `Page` (navigator): donde se importe nuestro `models/page.dart` junto a material, usar `hide Page`.

## Modelo de datos (JSON)

`Notebook{id,title,noteIds[],color,coverStyle,coverImagePath,tags}` → `Note{id,title,createdAt,updatedAt,pages[]}` → `Page{id,name,template,strokes[],images[],textItems[],layers[]}` → `Stroke{id,tool,color,size,points[{x,y,p}],fillColor,layer,shape,th,sm,sl}` (`Document` = formato legacy, solo migración), `ImageItem{id,path,x,y,w,h,rotation,layer}`, `TextItem{id,x,y,w,text,fontSize,color,layer}`, `PageTemplate{type,lineColor,spacing,imagePath,infiniteFill,customW,customH}`, `Layer{name,visible,locked}`. Trazos e imágenes en **coordenadas de mundo**; las capas filtran visibilidad.

## Reglas de negocio

- La **biblioteca** (`NotebookLibraryScreen`) es la pantalla de inicio → `NoteListScreen` → `HomeScreen(note:, notebookId:)`, que recibe el `Note` ya cargado (no lo lee de disco). Al volver se refrescan índice y miniaturas.
- `StorageService`: `index.json` (`formatVersion: 2`, metadatos por `updatedAt`) + `notebooks/<id>.json` (solo `noteIds`) + `notes/<id>.json`. Toda escritura pasa por `writeAtomic`; toda modificación del índice por `_updateIndex` (cola serializada). Cambios de un cuaderno que no tocan el contenido (crear/renombrar/duplicar/borrar nota, título, color, etiquetas) van por `_editNotebook` (solo `notebooks/<id>.json` + índice, **sin** cargar ni reescribir las notas); `saveNotebook` reescribe todas y es solo para cuadernos nuevos/importados. `saveNote` hace `touch()` **antes** de escribir (`touch: false` para copias restauradas: conservan su fecha). `.inklus`: v2 = tiene `notebook.json`; v1/nota suelta = `document.json` (también lleva `format.json`, no usarlo para detectar). Las imágenes viven en `inklus/images/` compartido; `collectOrphanedImages` borra las no referenciadas (notas activas, papelera y versiones) con 10 min de gracia.
- Migración: `current_document.json` o un índice v1 (`documents/`) se convierten a Notebook+Note automáticamente.
- Lienzo infinito: plantillas `blank/ruled/grid/custom+infiniteFill`; hoja finita: `sheet/custom sin relleno` (contenido recortado a la hoja).
- `fitView` centra la hoja finita o pone zoom 1.0 en infinitas.

## Decisiones de diseño (no re-abrir)

- **Todo gratis, sin premium.** Inklus es open source y no tendrá funciones de pago. Las features premium de GoodNotes/Samsung Notes/Notability se implementan aquí de forma gratuita.
- **Conflictos de Drive: last-write-wins**. Cuando dos dispositivos editan el mismo cuaderno, el documento con `updatedAt` más reciente gana. Es más simple que merge por página y evita pérdida de contenido no intencionada. El usuario puede ver todas las versiones en Drive (menú ☁️ → "Ver versiones") y restaurar la que quiera.
- **Cifrado de backup: AES-256-GCM + PBKDF2-HMAC-SHA256 (100k)** con `cryptography` (reemplazó al XOR original). Formato `[salt 16][nonce 12][ciphertext][tag 16]`, en `BackupCrypto`. La clave se deriva de los bytes UTF-8 de la contraseña; el descifrado reintenta con `codeUnits` para abrir backups antiguos.
- **Sync selectiva**: `NotebookMeta.syncEnabled` (null = true por defecto para compatibilidad). El backup automático solo sube cuadernos con sync habilitado.
