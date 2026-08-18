# ✒️ Inklus

App de escritura a mano para tablets con **stylus**, estilo GoodNotes/Samsung Notes, construida con **Flutter**. Todo en uno: escritura con presión, resaltador, borrador, plantillas infinitas o de hoja, plantillas propias con relleno y exportación a imagen/PDF.

**Target principal:** Android (tablets físicas) · **Plataforma secundaria:** Linux desktop (desarrollo/pruebas).

> 📚 Documentación: [`ROADMAP.md`](ROADMAP.md) (próximos pasos) · [`AGENTS.md`](AGENTS.md) (guía técnica para continuar el desarrollo con IA).

---

## 🎨 Funcionalidades

### Escritura (optimizada para stylus)
- **Detección de puntero** (`PointerDeviceKind`): stylus, `invertedStylus` (punta trasera = **borrador automático**), touch y mouse.
- **Rechazo de palma**: mientras el stylus está en contacto, *todos* los eventos `touch` simultáneos se ignoran por completo (no dibujan, no panean, no seleccionan).
- **Presión real** del stylus modulando el grosor del trazo en tiempo real.
- **Trazo suavizado** con `perfect_freehand` (grosor variable, puntas afiladas en el lápiz).
- **Zoom/pan SOLO con dos dedos** (táctil). El stylus nunca panea: escribir y navegar no interfieren.

### Herramientas (all-in-one)
- **Lapicero**: trazo uniforme, filo definido.
- **Lápiz**: grosor variable según presión, puntas afiladas.
- **Resaltador**: trazo ancho y translúcido.
- **Borrador** (manual + automático con `invertedStylus`): borrado fino que *parte* el trazo en fragmentos, tipo goma real.
- **Color y tamaño muy personalizables**: paleta + color personalizado (Matiz/Saturación/Brillo) y slider de tamaño por herramienta.
- Deshacer/rehacer por acciones (trazos e imágenes).

### Plantillas
| Plantilla | Comportamiento |
|---|---|
| Lienzo infinito | En blanco, se alarga al escribir |
| Hoja normal | Tamaño fijo tipo A4 (el mercado actual) |
| Rayas | Tipo cuaderno, infinitas, con margen |
| Cuadrícula | Tipo cuaderno, infinita |
| Plantilla propia | Subes una imagen: **hoja fija** o **relleno infinito** (se repite al escribir) |

### Contenido y exportación
- **Insertar imágenes del dispositivo** sobre el lienzo: moverlas y redimensionarlas (asa en la esquina).
- **Exportar** en varios formatos (render fuera de pantalla, independiente del zoom): página a **PNG/PDF**, **cuaderno completo a PDF** (todas las páginas) y **copia .inklus**.
- **Formato propio .inklus**: un único archivo autocontenido por cuaderno (como `.goodnotes`/`.sdoc`) que empaqueta el documento y sus imágenes — exportable, compartible y reimportable.
- **Guardado local automático** (JSON con debounce) — los trazos nunca se pierden ante cierres inesperados.

---

## 🧠 Decisiones clave (stylus / rendimiento)

### Rechazo de palma
Un `Listener` crudo recibe **todos** los eventos de puntero. La lógica:

```
stylus down → _stylusDown = true
cualquier touch mientras _stylusDown → se descarta (return)
stylus up → _stylusDown = false
```

Como `Listener` no participa en la *gesture arena*, no hay conflicto con el `GestureDetector` de zoom/pan.

### Capas de pintado (rendimiento)
- **Capa confirmada** (plantilla + trazos + imágenes) dentro de un `RepaintBoundary`. Su `shouldRepaint` devuelve `false` cuando solo cambió el trazo en progreso → la GPU reutiliza la capa cacheada.
- **Capa activa** (trazo en curso, cursor del borrador, selección) encima, se repinta cada frame sin invalidar la confirmada.

### Coordenadas
Los trazos se guardan en **coordenadas de mundo** (independientes del zoom). La transformación (escala + traslación) solo afecta a la vista: exportar a cualquier zoom da el mismo resultado.

---

## 📁 Estructura

```
lib/
├── main.dart / app.dart          # Entrada y tema
├── models/                       # Stroke, Page, Document, PageTemplate, ImageItem (JSON)
├── logic/
│   ├── canvas_controller.dart    # Estado central (ChangeNotifier): herramienta, zoom, deshacer
│   ├── stroke_engine.dart        # Suavizado perfect_freehand por herramienta
│   ├── eraser.dart               # Borrado fino que parte trazos en fragmentos
│   └── undo_stack.dart           # Deshacer/rehacer por acciones
├── services/
│   ├── storage_service.dart      # Persistencia local JSON (buffer principal)
│   ├── image_service.dart        # Copia/decodificación de imágenes del dispositivo
│   ├── export_service.dart       # PNG/PDF (render fuera de pantalla)
│    └── drive_sync_service.dart   # Sincronización Google: auth + Firestore + Storage
└── ui/
    ├── home_screen.dart          # Pantalla principal (barras + lienzo + zoom)
    ├── canvas/
    │   ├── drawing_canvas.dart   # Listener (stylus/palma) + GestureDetector (2 dedos)
    │   └── world_painter.dart    # Pintado de plantillas/trazos/imágenes (compartido con export)
    └── widgets/                  # Riel de herramientas, paleta, selector de plantillas
```

---

## 🚀 Ejecutar

```bash
flutter pub get
flutter run -d linux        # escritorio (desarrollo)
flutter run -d <tablet>     # Android (requiere modo desarrollador/USB)
```

Exportar a imagen/PDF usa el selector de archivos nativo de cada plataforma.

---

## ☁️ Sincronización con Google Drive (respaldo opcional)

La app es **offline-first**: todo el contenido (trazos, páginas, plantillas e **imágenes**) vive en el dispositivo y funciona 100% sin cuenta ni red. La sincronización es un **respaldo opcional** a Google Drive, implementada en `lib/services/drive_sync_service.dart`:

- **Google Sign-In** (`google_sign_in`) con el scope `drive.file`: la app solo ve/crea sus propios archivos en tu Drive (15 GB gratis) — nada se sube a servidores de terceros.
- Con sesión iniciada, cada guardado local **replica el cuaderno** a una carpeta **Inklus** en tu Drive como `<id>.inklus` en el **formato propio de la app**: un único archivo autocontenido con el documento y sus **imágenes embebidas** (igual que hacen las apps del mercado). Se actualiza siempre en el mismo archivo (no se duplica).
- **Sesión persistente**: al abrir la app se restaura la sesión silenciosamente (One Tap); el botón ☁️ de la barra superior muestra el estado.
- **Subir ahora / Restaurar** desde el menú ☁️. Restaurar trae la copia más reciente (por fecha del documento) y extrae sus imágenes a la app automáticamente.

### Configuración (solo una vez)

El proyecto **Google Cloud** (`inklus`) ya existe (es el mismo de Firebase) y el APK ya incluye los clientes OAuth — **no hace falta Firebase, ni `google-services.json`, ni `flutterfire`**. Solo:

1. En [console.cloud.google.com](https://console.cloud.google.com) → proyecto `inklus` → **APIs y servicios → Biblioteca**: habilita **Google Drive API**.
2. En **APIs y servicios → Pantalla de consentimiento de OAuth**: configura la app (usuario externo), añade el scope `https://www.googleapis.com/auth/drive.file` y publícala.
3. Registra la **huella SHA-1** del keystore de firma en **APIs y servicios → Credenciales** (app Android `com.inklus.inklus`):
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```
   (Sin el SHA-1, Google Sign-In devuelve error `10` en Android. Si ya lo registraste para Firebase, es el mismo.)

Y listo: pulsa el ☁️ en la barra superior → **Conectarse con Google**.

> Sin sesión o sin Drive API habilitada, la app funciona igual: todo sigue siendo local (offline-first) y el guardado automático nunca se pierde.

---

## 🧪 Tests

```bash
flutter test   # serialización JSON de los modelos
```

## 🛠️ Stack

Flutter 3.47 (stable) · `perfect_freehand` (suavizado) · `path_provider` · `file_picker` · `pdf` · Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`) · Material 3
