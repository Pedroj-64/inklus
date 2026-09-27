# 🗺️ Hoja de ruta — Inklus

> Estado del proyecto y próximos pasos. La **guía técnica para la IA** está en [`AGENTS.md`](AGENTS.md) (arquitectura, flujos críticos, gotchas); el manual de usuario/instalación en [`README.md`](README.md).

## 🧭 Cómo leer esta hoja de ruta (para la IA)

- Cada fila es una **tarea independiente** con su *por qué / cómo*: el **por qué** justifica el valor, el **cómo** apunta a archivos y APIs concretas del código (no es una orden de implementación, es la pista).
- Marcadores: **`✅`** = hecho e integrado; **`🔧`** = parcial / stub; el resto está **ordenado por valor** dentro de cada fase.
- **Regla de oro: offline-first.** Todo debe seguir funcionando 100% sin red ni cuenta; Google Drive es un respaldo *opcional*.
- **Filosofía open source / gratis.** No hay funciones "premium". Las dependencias externas deben ser gratuitas.

---

## ✅ Lo que la app ofrece hoy

> Verificado contra el código fuente (~25,400 líneas Dart en `lib/`, 178 tests pasando).

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

### 🎯 Siguiente: v1.5 — "Todo con el mismo diseño" (orden recomendado)
> Objetivo: terminar el lavado de cara (P1), dejar lista la distribución pública (R2–R4) y cerrar las dos carencias más visibles del lazo y del historial (P7, P8).

| Orden | Tarea | Qué hacer | Hecho cuando |
|---|---|---|---|
| 1 | **P1a — pantallas secundarias** | `trash_screen.dart`, `reminder_screen.dart`, `writing_stats_screen.dart` → `InklusPage` + `SectionCard`/`SettingsTile`/`EmptyState` de `ui/widgets/page_scaffold.dart`; colores de `context.colors`/`context.inklus`, medidas de `tokens.dart`. | Sin `ThemeColors`/`kAccentColor` en esos archivos; capturas de `tool/screenshots` revisadas en claro y oscuro. |
| 2 | **P1b — hojas y listas** | `note_list_screen.dart`, `create_notebook_screen.dart`, `onboarding_screen.dart` y las hojas de `ui/widgets/` (`template_picker_sheet`, `layers_sidebar`, `tag_editor_sheet`, `smart_folders_sheet`, `stroke_options_sheet`, `custom_color_dialog`) → `SheetHeader` + tokens. | `grep -rn "ThemeColors\|kAccentColor" lib/ui` solo devuelve el lienzo (`canvas/`) y la biblioteca, justificados. |
| 3 | **R2 — Política de privacidad** | `docs/privacy.md` publicado con GitHub Pages: todo local, Drive solo con `drive.file`, sin analítica ni rastreo; enlace desde Configuración → Acerca de. | URL pública y enlazada en la app y en el README. |
| 4 | **R3 — OAuth en producción** *(manual, en Google Cloud)* | Pantalla de consentimiento: logo, dominio de la política, scope `drive.file` → *Publish app*. `drive.file` es no sensible: no requiere verificación completa. | El inicio de sesión ya no caduca a los 7 días ni está limitado a 100 usuarios de prueba. |
| 5 | **R4 — Releases en GitHub** | Workflow en tags `v*`: `flutter build apk --release --split-per-abi` firmado con secretos (`key.properties` generado en CI), adjunta APKs y el bloque de `CHANGELOG.md` de esa versión. README: instalar desde "orígenes desconocidos". | `git tag v1.5.0 && git push --tags` publica la release sola. |
| 6 | **P8 — Versiones de Drive en el historial** | En la hoja de "Historial de versiones", sección "En Google Drive" que lista revisiones (`DriveSyncService.downloadVersion` ya existe) y restaura igual que una versión local (guardando antes la actual). | Restaurar una revisión de Drive desde el editor sin salir de la nota. |
| 7 | **P7 — Lazo completo** | Escalar/rotar y copiar/pegar también `ImageItem`/`TextItem` (hoy solo trazos); una única `CanvasAction` con los tres tipos. | Tests en `test/` de transformar + deshacer con selección mixta. |

**Después de v1.5:** P3 (scroll vertical continuo) y P2 (i18n) son los siguientes de mayor valor; R5 (guion de pruebas en dispositivo) antes de anunciar la v2.0.

### 🟡 Pendiente (siguiente ronda)
| # | Tarea | Detalle |
|---|---|---|
| P1 | **Migrar pantallas restantes al sistema de diseño** | ✅ Configuración (con `ui/widgets/page_scaffold.dart`). Faltan lista de notas, papelera, recordatorios, estadísticas, selector de plantillas y capas, que aún usan colores sueltos (`ThemeColors`/`kAccentColor`): reutilizar `InklusPage`/`SectionCard`/`SettingsTile`/`EmptyState`. |
| P2 | **i18n** | `flutter_localizations` + ARB (ES fuente, EN); arregla selectores de fecha en inglés. |
| P3 | **Desplazamiento vertical continuo** entre páginas (como GoodNotes/Notability) y vista doble en apaisado. |
| P4 | **Audio sincronizado** (`record`) con reproducción que resalta lo escrito. |
| P5 | **Ventana de zoom** tipo Samsung Notes (recuadro de escritura ampliada que avanza solo). |
| P6 | **Portadas desde el marketplace** y plantillas con imagen/PDF en el catálogo real (hoy el catálogo incluido solo trae plantillas paramétricas y paletas). |
| P7 | **Escalar/rotar y copiar/pegar** también imágenes y textos del lazo (hoy solo trazos). |
| P8 | **UI de revisiones de Drive** en el historial de versiones. |

### 🔵 v2.0 — Release pública (sin Google Play)
> Decisión: **no se publica en Google Play**. Distribución por **GitHub Releases** (APK firmados por la CI en cada tag `v*`) y, opcionalmente, IzzyOnDroid. (F-Droid principal no admite dependencias propietarias como ML Kit / Google Sign-In.)

| # | Tarea | Detalle |
|---|---|---|
| R1 | ✅ **LICENSE GPL-3.0-or-later** | `LICENSE` + cabecera SPDX en cada `.dart` + sección en README. |
| R2 | **Política de privacidad** | Página pública (GitHub Pages): todo local; Drive con `drive.file` (solo archivos creados por la app); sin analítica. Necesaria para verificar la pantalla de consentimiento OAuth. |
| R3 | **OAuth en producción** | Pasar la pantalla de consentimiento de Google Cloud de *Testing* a *In production* (si no: máx. 100 usuarios de prueba y tokens que caducan a los 7 días). |
| R4 | **Releases en GitHub** | Tags `v*` → la CI firma y adjunta APK por ABI; notas desde `CHANGELOG.md`; instrucciones de instalación (orígenes desconocidos) en README. |
| R5 | **Pruebas en dispositivo** | Galaxy Tab S (S-Pen), tablet con lápiz USI, teléfono. Guion manual + `integration_test` de flujos críticos. |
| R6 | **Crash reporting opt-in** | Sentry (free) solo con consentimiento explícito; sin datos de contenido. |
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
| **Dividir `CanvasController` (estado)** | Ya se extrajo la geometría pura (`lasso.dart`, `bucket_fill.dart`, `ruler.dart`, `palm_rejection.dart`). Falta separar `ViewTransform`, `SelectionController` y `LayerManager`. |
| **Consolidar Drive legacy** | Caminos paralelos Document vs Note en `drive_sync_service`; `SearchService` aún indexa `Document`. |
| **`AppPaths` único** | Cinco servicios reconstruyen `getApplicationSupportDirectory()/inklus` (usar `StorageService.baseDirectory()`). |
| **Papelera de Notes sueltas** | Una Note borrada individualmente se trata como `Document` legacy al restaurar. |
| ✅ **Timeouts de Drive** | Resuelto en 1.4.2: `_BearerClient` corta a los 60 s (todas las llamadas pasan por él). |
| **Pan sin límites** | En hoja fija se puede desplazar la vista indefinidamente; acotar a la hoja con margen. |
| **Trazo activo incremental** | `getStroke` recorre todo el trazo en curso en cada evento; medir en trazos muy largos. |

## 📊 Métricas del proyecto

| Métrica | Valor |
|---|---|
| Archivos Dart (lib/) | ~85 |
| Líneas de código | ~25,400 |
| Tests | 178 (todos pasando) |
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
