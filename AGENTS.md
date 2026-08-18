# 🤖 Guía técnica para continuar Inklus

App de escritura a mano para tablets con stylus (tipo GoodNotes), **Flutter 3.47 / Dart 3.13**, Material 3, UI y comentarios en **español**. Targets: **Android** (principal) + **Linux desktop** (dev).

> Documentación general: [`README.md`](README.md) · Próximos pasos: [`ROADMAP.md`](ROADMAP.md)

## Comandos

```bash
flutter pub get
flutter analyze            # debe quedar en 0 issues
flutter test               # tests de modelos (test/widget_test.dart)
flutter run -d linux       # desarrollo en escritorio
flutter run                # tablet Android conectada
flutter build apk --debug  # APK → build/app/outputs/flutter-apk/
dart run flutter_launcher_icons   # regenerar iconos desde assets/icon/
```

## Arquitectura (lib/)

```
models/      Stroke, StrokePoint, Page, Document, ImageItem, PageTemplate (todo JSON)
logic/
  canvas_controller.dart   ★ Estado central ChangeNotifier: herramienta/color/tamaño,
                             transformación vista, trazo activo, deshacer, páginas,
                             guardado local + onRemoteSync
  stroke_engine.dart       perfect_freehand: polígono por herramienta (opciones por tool)
  eraser.dart              borra puntos dentro del radio y PARTE el trazo en fragmentos
  undo_stack.dart          acciones reversibles (CanvasAction)
services/
  storage_service.dart     ★ índice de cuadernos: <appSupport>/inklus/index.json +
                             documents/<id>.json (el debounce 600ms vive en el controlador);
                             migra el legacy current_document.json; CRUD (crear/renombrar/duplicar/eliminar)
  image_service.dart       copia archivos a la app + cache de ui.Image (clave = ruta)
  export_service.dart      PNG/PDF fuera de pantalla (reusa paintWorld); maxDimension para miniaturas;
                             renderNotebookPdf = cuaderno completo multipágina
  inklus_format.dart       ★ formato propio .inklus: ZIP autocontenido (document.json +
                             imágenes embebidas en images/); exportBytes/importBytes con
                             rutas inklus:// re-mapeadas a locales al importar
  drive_sync_service.dart  ★ Google Drive real (offline-first): signIn con
                             scope drive.file (google_sign_in 7), sesión silenciosa
                             (One Tap), backup/restore del JSON en carpeta 'Inklus';
                             las imágenes NUNCA se suben (quedan locales)
ui/
  notebook_library.dart    pantalla de inicio: lista de cuadernos con miniaturas + CRUD;
                             abre el editor con Navigator.push(HomeScreen(document: doc))
  home_screen.dart         editor: top bar (botón volver), riel, canvas, zoom, bottom bar, ☁️
  canvas/drawing_canvas.dart  ★ Listener (stylus/palma) + GestureDetector (zoom 2 dedos) + 2 capas
  canvas/world_painter.dart   pintado de plantilla/imágenes/trazos (compartido con export)
  widgets/                 tool_rail, bottom_bar (paleta+HSV+tamaños), template_picker_sheet
```

## ★ Flujos críticos (no romper)

### 1. Stylus y rechazo de palma — `drawing_canvas.dart`
- Un `Listener` **crudo** recibe TODOS los eventos (no participa en la gesture arena).
- `_stylusDown = true` al bajar stylus/mouse; **todo `PointerDeviceKind.touch` se descarta** mientras esté activo (`if (_stylusDown || _transforming) return;`). `invertedStylus` fuerza `ToolType.eraser`.
- El `GestureDetector` con callbacks de escala solo transforma con `pointerCount >= 2` y `!_stylusDown`. En `onScaleUpdate` se cancela el trazo de dedo en curso antes de transformar.
- Conversión: `world = (local - translate) / scale` (métodos `viewportToWorld`/`worldToViewport` del controlador).

### 2. Capas de pintado — `drawing_canvas.dart` (CanvasPainter / ActiveLayerPainter)
- **Capa confirmada** (plantilla+imágenes+trazos) dentro de `RepaintBoundary`. Su `shouldRepaint` compara `contentVersion` (se incrementa en `_touch()`) + `scale`/`translate`/`sheetSize`/`imageCache`: si solo cambia el trazo activo, NO repinta (ahí está la optimización).
- **Capa activa** (trazo en curso, cursor borrador, selección) encima, `shouldRepaint => true` siempre.
- `page` se muta en sitio (nunca se reemplaza la instancia), por eso el versionado es por contador, no por identidad.

### 3. Deshacer/rehacer — `undo_stack.dart` + `canvas_controller._applyAction`
- Cada operación empuja un `CanvasAction` con `strokesAdded/Removed` + `imagesAdded/Removed`. Deshacer = quitar los added y restaurar los removed (comparación por identidad de instancia). Imágenes: `updateImageLive` durante el arrastre (sin acción) y `commitImageChange(before, after)` al soltar (una sola acción).

### 4. Exportación — `export_service.dart`
- `paintWorld` (en `world_painter.dart`) pinta plantilla+imágenes+trazos en un rect dado; el lienzo la llama con el rect visible transformado y la exportación con el rect del contenido → lo que ves = lo que exportas.

### 5. Sincronización — `drive_sync_service.dart` (Google Drive, offline-first)
- **Singleton** `DriveSyncService.instance` (`ChangeNotifier`): la sesión se comparte entre biblioteca y editor; el ☁️ escucha con `Listenable.merge([controller, service])`.
- `signIn()`: `GoogleSignIn.instance.authenticate(scopeHint: [drive.file])`. El **access token NO viene en `authentication`** (v7 solo trae idToken): se pide con `account.authorizationClient.authorizeScopes([drive.file])` (interactivo) o `authorizationForScopes` (silencioso, puede devolver null).
- `restoreSession()` (silenciosa, One Tap) se llama al arrancar en `NotebookLibraryScreen`.
- Backup: carpeta 'Inklus' en Drive, un archivo `<document.id>.inklus` por cuaderno (upsert, no duplica) en el formato propio `InklusFormat` (documento + **imágenes embebidas** → el backup es autocontenido). Restore: lista la carpeta, importa cada `.inklus` (extrae imágenes a `<appSupport>/inklus/restored/<id>/`) y elige la más reciente por `updatedAt`. `googleapis` 16 (`drive/v3.dart`): `files.create/update` con `uploadMedia: commons.Media`; descarga con GET `alt=media` vía `_BearerClient` (http).
- Backup automático = silencioso (si el scope no está autorizado se omite, el local ya protege); 'Subir ahora' usa `promptForConsent: true` (puede mostrar consentimiento).
- La UI se entera vía `controller.onRemoteSync` (callback en cada guardado) y `controller.replaceDocument(doc)` tras restaurar.
- Exportación (menú ⋮ del editor): página PNG/PDF, **cuaderno PDF** (`renderNotebookPdf`) y **copia .inklus** (`InklusFormat.exportBytes` → `FilePicker.saveFile`).

## 🚨 Gotchas de versiones (ya resueltas, no revertir)

- **file_picker 12**: API estática — `FilePicker.pickFiles()` → `List<PlatformFile>`, `FilePicker.pickFile()` → `PlatformFile?`, `FilePicker.saveFile({fileName, bytes})` → `Uri?`. **No existe** `FilePicker.platform`.
- **google_sign_in 7**: `GoogleSignIn.instance.authenticate({scopeHint})` / `attemptLightweightAuthentication()` (One Tap). `authentication` solo trae `idToken`; el access token se pide con `authorizationClient.authorizeScopes/authorizationForScopes`. `default_web_client_id` está **manualmente** en `android/app/src/main/res/values/strings.xml` (ya no lo genera google-services; no usar Firebase).
- **googleapis 16 / `_discoveryapis_commons`**: `drive.DriveApi(client)` con `uploadMedia: commons.Media(Stream.value(bytes), len, contentType:)`; `files.update(File request, String fileId, ...)` (¡el request va primero!). googleapis_auth no exporta su `AuthenticatedClient` → usar `_BearerClient` propio sobre `http`.
- **No Firebase**: la app no inicializa ni depende de Firebase (se eliminó). Si se reintroduce, `main.dart` debe llamar a `Firebase.initializeApp()` antes de tocar `FirebaseAuth.instance` (causa del crash al arrancar).
- **perfect_freehand 2.5.2**: `getStroke(List<PointVector>, options:)` → `List<Offset>` (polígono). `StrokeOptions` tiene `size/thinning/smoothing/streamline/simulatePressure/start/end/isComplete` (sin `roughness`). En `stroke_engine.dart` se importa con `hide StrokePoint` (colisión con nuestro modelo).
- **pdf 3.x**: `pw.Document`, `pw.Page(pageFormat: PdfPageFormat...)`, `pw.MemoryImage(pngBytes)`.
- **Google Drive API** debe estar habilitada en el proyecto Google Cloud (`inklus`) y el scope `drive.file` en la pantalla de consentimiento OAuth; sin eso, sign-in da error `403 accessNotConfigured`.
- `MaterialApp` de Flutter exporta `Page` (navigator): donde se importe nuestro `models/page.dart` junto a material, usar `hide Page`.

## Modelo de datos (JSON)

`Document{id,title,createdAt,updatedAt,pages[]}` → `Page{id,name,template,strokes[],images[]}` → `Stroke{id,tool,color,size,points[{x,y,p}]}`, `ImageItem{id,path,x,y,w,h}`, `PageTemplate{type,lineColor,spacing,imagePath,infiniteFill,customW,customH}`. Trazos en **coordenadas de mundo**.

## Reglas de negocio

- La **biblioteca** (`NotebookLibraryScreen`) es la pantalla de inicio; abre un cuaderno con `Navigator.push` y al volver refresca índice y miniaturas. `HomeScreen` recibe el `Document` ya cargado (no lo lee de disco).
- `StorageService` es un índice: `index.json` (metadatos ordenados por `updatedAt`) + `documents/<id>.json`. `save()` hace upsert en ambos; las imágenes viven en `inklus/images/` compartido entre cuadernos (al eliminar un cuaderno no se limpian las imágenes huérfanas — pendiente).
- Migración: si `index.json` no existe pero sí `current_document.json`, se importa como primer cuaderno y se borra el legacy.
- Lienzo infinito: plantillas `blank/ruled/grid/custom+infiniteFill`; hoja finita: `sheet/custom sin relleno` (contenido recortado a la hoja).
- `fitView` centra la hoja finita o pone zoom 1.0 en infinitas.
