# ✒️ Inklus

🌐 [English](README.md) · **Español**

App de escritura a mano para tablets con **stylus**, al estilo de GoodNotes o Samsung Notes, construida con **Flutter**. Presión real, rechazo de palma, cuadernos con plantillas, lazo, reconocimiento de escritura, importación de PDF y respaldo opcional en Google Drive.

**Gratis, sin anuncios, sin cuentas y sin analítica.** Todo vive en tu dispositivo.

**Plataforma principal:** Android (tablets) · **Secundaria:** Linux desktop.

> 📚 [`CHANGELOG.md`](CHANGELOG.md) · [Privacidad](docs/privacy.md) · [Pruebas en dispositivo](docs/testing.md) · [Marketplace](marketplace/README.md)

---

## 📲 Instalar (Android)

Inklus se distribuye como APK en [**GitHub Releases**](https://github.com/Pedroj-64/inklus/releases) (no está en Google Play).

1. En la última release, descarga el APK de tu tablet. Casi todas las tablets actuales usan **`app-arm64-v8a-release.apk`**; si no se instala, prueba `app-armeabi-v7a-release.apk`.
2. Ábrelo. Android pedirá permiso para **instalar apps de origen desconocido** para tu navegador o gestor de archivos: concédelo solo para esta instalación.
3. Las actualizaciones se instalan igual, encima de la versión anterior, sin perder tus notas.

> Antes de cambiar de dispositivo, exporta un respaldo: **Configuración → Exportar respaldo completo** (o activa la copia en Google Drive).

---

## 🎨 Funcionalidades

### ✍️ Escritura con stylus
- **Presión real** que modula el grosor del trazo, suavizado con `perfect_freehand`.
- **Rechazo de palma completo**: detecta el lápiz apoyado o cerca (hover), con ventana de gracia y tamaño de contacto. Modo *solo lápiz* automático.
- **Borrador automático** con la punta trasera del lápiz o el botón lateral del S-Pen.
- **Zoom y desplazamiento con los dedos**: escribir y navegar nunca interfieren.
- **Plumas favoritas** (3 + resaltador) con color y grosor propios, y colores recientes.

### 🧰 Herramientas
| Herramienta | Qué hace |
|---|---|
| Lapicero / Lápiz | Trazo uniforme o con grosor variable según la presión |
| Resaltador | Trazo ancho y translúcido |
| Borrador | Parcial (parte el trazo como una goma real), trazo completo o solo resaltador |
| Lazo | Mover, escalar, rotar, copiar, pegar, duplicar, recolorear y convertir a texto (trazos, imágenes y textos) |
| Figuras | Mantén al terminar el trazo para enderezarlo: líneas, rectángulos, triángulos, elipses |
| Regla y transportador | Medidas en cm/mm de la hoja, ángulo en vivo, el trazo se pega al borde |
| Texto enriquecido | Negrita, cursiva, subrayado, alineación, familia y tamaño |
| Puntero láser y lupa | Para presentar o escribir con detalle |
| Imágenes | Insertar del dispositivo, mover y redimensionar |

### 📄 Plantillas
| Plantilla | Comportamiento |
|---|---|
| Lienzo infinito | En blanco, crece al escribir |
| Hoja | Tamaño fijo tipo A4, con desplazamiento continuo entre hojas |
| Rayas / Cuadrícula | Tipo cuaderno |
| Plantilla propia | Subes una imagen: **hoja fija** o **relleno infinito** |

### 📚 Organización
- **Biblioteca** con cuadernos, portadas, favoritos, recientes y vista cuadrícula/lista.
- **Etiquetas** y **carpetas inteligentes**.
- **Búsqueda** en todas las notas, incluida la **escritura a mano reconocida** (ML Kit, en el dispositivo).
- **Marcadores de página**, ir a página y atajos de teclado.
- **Papelera** con restauración y purga automática a los 30 días.
- **Recordatorios** vinculados a cuadernos y **estadísticas de escritura** (totales y rachas).

### 💾 Importar, exportar y respaldar
- **Importar PDF** para anotarlo (una página de la nota por página del PDF).
- **Exportar** página o cuaderno completo a **PNG, PDF, SVG o PPTX** (render fuera de pantalla, independiente del zoom).
- **Formato propio `.inklus`**: un único archivo por cuaderno con el documento y sus imágenes: compartible y reimportable.
- **Guardado instantáneo** de cada cambio e **historial de versiones** local.
- **Respaldo completo** en `.zip`, con **cifrado opcional AES-256-GCM** (clave derivada con PBKDF2).
- **Marketplace** de paquetes gratuitos (plantillas, paletas, stickers) con verificación sha256.

### ☁️ Google Drive (opcional)
La app es **offline-first**: funciona al 100 % sin cuenta ni red. Si inicias sesión con Google:
- Cada cuaderno se replica a una carpeta **Inklus** de tu Drive como `.inklus`, siempre en el mismo archivo.
- Usa el permiso **`drive.file`**: la app solo ve los archivos que ella misma crea.
- **Restaurar desde Drive** trae la versión más reciente de cada nota, y el historial de versiones muestra también las revisiones guardadas en Drive.

---

## 🔒 Privacidad

No hay servidores de Inklus, analítica ni anuncios. Los errores se registran **solo en el dispositivo** y tú decides si compartirlos (Configuración → Registro de errores). Detalles en [`docs/privacy.md`](docs/privacy.md).

### Secretos (para quien contribuya o publique)

- **Nunca al repo:** keystore (`*.jks`), `android/key.properties`, `client_secret*.json`, `google-services.json`, `.env`. Todo está en `.gitignore` y la CI (`secret-scan`, gitleaks) rechaza lo que se cuele.
- **Firma de releases:** la CI lee `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD` de *GitHub → Settings → Secrets*. El keystore se guarda **fuera** del repositorio y con copia de seguridad cifrada: perderlo impide actualizar los APK ya instalados.
- **Es público (no es secreto):** el ID de cliente OAuth y las huellas SHA-1 de firma; identifican la app, no dan acceso. Un `client_secret` sí es secreto: la app no lo necesita, no lo descargues.
- **Si se filtra algo:** rotar en Google Cloud (Credenciales), regenerar el secreto de GitHub y reescribir el historial solo si el valor sigue vigente.

---

## 🧠 Decisiones técnicas

### Rechazo de palma
Un `Listener` crudo recibe **todos** los eventos de puntero antes que la *gesture arena*. Mientras el lápiz está en contacto o cerca de la pantalla, los toques simultáneos se descartan: no dibujan, no desplazan y no seleccionan. Como `Listener` no compite en la arena de gestos, no hay conflicto con el `GestureDetector` de zoom/pan.

### Capas de pintado
- **Capa confirmada** (plantilla + trazos + imágenes) dentro de un `RepaintBoundary`: la GPU la reutiliza mientras solo cambia el trazo en curso.
- **Capa activa** (trazo en curso, cursor del borrador, selección) encima; se repinta cada frame sin invalidar la confirmada. Añadir un punto es O(1).
- **Durante el zoom/desplazamiento** el lienzo se dibuja desde una instantánea y solo se pintan en vivo las franjas que el gesto destapa; al soltar se repinta nítido.
- Culling, cachés por trazo, nivel de detalle en plantillas y codificación de notas grandes en otro isolate.

### Coordenadas de mundo
Los trazos se guardan en coordenadas independientes del zoom. La transformación (escala + traslación) solo afecta a la vista, así que exportar da el mismo resultado a cualquier zoom.

---

## 📁 Estructura

```
lib/
├── main.dart · app.dart           # Entrada, tema e idiomas
├── models/                        # Notebook, Note, Page, Stroke, ImageItem, TextItem, Template
├── logic/
│   ├── canvas_controller.dart     # Estado central (+ canvas_view / canvas_selection / canvas_layers)
│   ├── stroke_engine.dart         # Suavizado por herramienta
│   ├── palm_rejection.dart        # Rechazo de palma
│   ├── eraser.dart · lasso.dart   # Borrado fino y selección
│   ├── shape_detector.dart        # Reconocimiento de figuras
│   ├── ruler.dart · snap_guides.dart
│   └── undo_stack.dart            # Deshacer/rehacer por página
├── services/
│   ├── storage_service.dart       # Persistencia local (escrituras atómicas)
│   ├── inklus_format.dart         # Formato .inklus
│   ├── export_service.dart        # PNG / PDF / SVG (+ pptx_builder.dart)
│   ├── import_service.dart        # .inklus y respaldos
│   ├── pdf_import_service.dart    # PDF → páginas anotables
│   ├── drive_sync_service.dart    # Respaldo en Google Drive
│   ├── backup_crypto.dart         # AES-256-GCM + PBKDF2
│   ├── ocr_service.dart           # Reconocimiento de escritura (ML Kit)
│   ├── search_service.dart · version_history_service.dart
│   ├── reminder_service.dart · writing_stats_service.dart
│   └── marketplace/               # Catálogo de paquetes
├── ui/
│   ├── canvas/                    # Lienzo, overlays y pintor (compartido con la exportación)
│   ├── editor/                    # Barra, popovers, panel de páginas, historial
│   ├── theme/                     # Sistema de diseño (tema, tokens, colores)
│   ├── widgets/                   # Componentes compartidos
│   └── *_screen.dart              # Biblioteca, ajustes, papelera, recordatorios…
└── l10n/                          # Traducciones (español / inglés)
```

---

## 🚀 Desarrollo

Requiere **Flutter 3.47** (stable).

```bash
flutter pub get
flutter run -d linux        # escritorio
flutter run -d <tablet>     # Android (modo desarrollador / USB)
```

### Tests

```bash
flutter analyze
flutter test                                          # modelos, storage, lienzo, historial, traducciones…
flutter test tool/screenshots/screenshots_test.dart   # capturas de la UI (build/screenshots)
flutter test integration_test -d <dispositivo>        # flujos críticos en tablet/emulador
```

La CI de GitHub Actions ejecuta análisis, tests y pruebas de integración en cada PR, y publica los APK firmados al crear un tag `v*` (las notas de la release salen del CHANGELOG).

### Google Drive en tu propia compilación

Si compilas un fork, necesitas tu propio proyecto de Google Cloud (no hace falta Firebase ni `google-services.json`):

1. En [console.cloud.google.com](https://console.cloud.google.com), crea un proyecto y habilita **Google Drive API**.
2. Configura la **pantalla de consentimiento OAuth** con el scope `https://www.googleapis.com/auth/drive.file`.
3. En **Credenciales**, crea un cliente OAuth **Android** (paquete + huella SHA-1 de tu keystore) y un cliente **Web**; pon el ID del cliente web en `android/app/src/main/res/values/strings.xml` (`default_web_client_id`).
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```
   Sin la huella SHA-1 registrada, Google Sign-In devuelve el error `10`.

---

## 🛠️ Stack

Flutter · Dart · Material 3 · `perfect_freehand` · `pdf` / `printing` · `archive` · `google_sign_in` + `googleapis` · `cryptography` · Google ML Kit (texto y tinta digital) · `share_plus` · `file_picker` · `shared_preferences` · `intl`

## 📜 Licencia

Inklus es software libre: puedes redistribuirlo y/o modificarlo bajo los términos de la
**GNU General Public License v3.0 o posterior** (GPL-3.0-or-later), publicada por la Free
Software Foundation. Consulta el archivo [`LICENSE`](LICENSE).

Copyright © 2026 Pedro ([@Pedroj-64](https://github.com/Pedroj-64)) y contribuidores de Inklus.

Cada archivo fuente lleva la cabecera `// SPDX-License-Identifier: GPL-3.0-or-later`.
Cualquier versión modificada que se distribuya debe publicarse también bajo GPL-3.0 con su código fuente.
