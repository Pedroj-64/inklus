# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones [SemVer](https://semver.org/lang/es/).

## [1.7.0] — 2026-09-27

### Añadido
- **Desplazamiento continuo entre hojas**: las hojas fijas se apilan en vertical; al desplazarte pasas de una a otra sin saltos, y empezar a escribir en la de abajo la activa. Se puede desactivar en ⋮ → Ver.
- **Deshacer por página**: cambiar de página ya no borra lo que se podía deshacer.
- **Política de privacidad** (`docs/privacy.md`), enlazada desde Configuración junto al código fuente.
- **Registro de errores local**: los fallos se guardan solo en el dispositivo; Configuración → "Registro de errores" permite compartirlos o borrarlos. Sin analítica ni servicios de terceros.
- **Idiomas**: infraestructura de traducción (español/inglés). Los selectores de fecha y hora y los textos del sistema salen en español; Configuración ya está traducida (el resto de pantallas, en curso).
- **Pruebas de integración** (bienvenida → cuaderno → lápiz → guardado), también en la CI; guion de pruebas en dispositivo (`docs/testing.md`).
- **Releases**: las notas de cada release de GitHub salen del CHANGELOG y la CI comprueba que el tag coincide con la versión.

### Cambiado
- `CanvasController` dividido en partes (vista, selección, capas) sin cambiar su API.
- Rutas de datos en un único `AppPaths`; se quita el código de Drive y exportación del formato antiguo que ya no se usaba.
- Los recordatorios creados desde el editor se vinculan al cuaderno, igual que los de la pantalla de recordatorios.

## [1.6.0] — 2026-09-27

### Añadido
- **Lazo completo**: escalar, rotar, copiar, pegar y duplicar también imágenes y cajas de texto (antes solo trazos), con una sola acción de deshacer.
- **Revisiones de Google Drive en el historial de versiones**: la hoja "Historial de versiones" muestra las copias locales y las revisiones que Drive guarda de cada subida; se restauran igual (el estado actual se guarda antes). Las copias cifradas piden la contraseña.
- **Papelera de notas**: una nota borrada vuelve a su cuaderno al restaurarla (o a uno nuevo con el mismo nombre si el cuaderno ya no existe). Cada elemento muestra qué es, de dónde viene y cuántos días le quedan.

### Cambiado
- **Todas las pantallas con el mismo diseño**: papelera, recordatorios, estadísticas, lista de notas, bienvenida, etiquetas, carpetas inteligentes, opciones de trazo, capas y selector de plantillas usan los colores y medidas del tema (bien en claro y oscuro).
- Estadísticas rediseñadas: totales en tarjetas, rachas y un gráfico que se adapta al ancho.
- Bienvenida actualizada (un dedo desplaza en modo solo lápiz, herramientas arriba, notas locales).

### Corregido
- **Papelera**: borrar un cuaderno creaba entradas fantasma "Sin título" (sus notas) con fecha 31/12/1969; borrarlo definitivamente dejaba sus notas en la papelera; la purga automática de 30 días que anunciaba la pantalla no existía.
- **Recordatorios**: deslizar para borrar no borraba (y lanzaba un error de Flutter).
- Las hojas inferiores mostraban dos asas de arrastre.
- La rotación de una selección "derivaba" (el pivote se recalculaba en cada frame); asas de selección dibujadas y detectadas en el mismo sitio.
- Carpetas inteligentes: nombres de color erróneos ("Otro"); la paleta de portadas es única en toda la app.

## [1.5.0] — 2026-09-27

### Rendimiento
- **Desplazar y hacer zoom con páginas llenas**: durante el gesto el lienzo se dibuja desde una instantánea (un solo quad por frame) y solo se pintan en vivo las franjas que el gesto destapa; al soltar se repinta nítido. Antes se volvían a dibujar todos los trazos en cada frame.
- **Fotos en el lienzo a resolución de pantalla** (máx. 2560 px por lado): una foto de 12 MP pasa de ~48 MB a ~20 MB en memoria. Las exportaciones de alta resolución decodifican las imágenes a su resolución, página a página.

### Corregido
- **Pan infinito en hoja fija**: la hoja ya no se puede perder de vista (sus bordes se detienen a 48 px del borde de la pantalla).
- La exportación del cuaderno completo (PDF/PPTX) podía omitir imágenes de páginas no abiertas o desalojadas de la caché.
- Carpetas inteligentes: el efecto de toque de las opciones no se veía (quedaba tapado por el fondo de la hoja).

### Herramientas
- `tool/stress/stress_note_test.dart` genera un cuaderno de estrés (5.100 trazos + 10 fotos de 12 MP) para medir en un dispositivo.

## [1.4.3] — 2026-09-27

### Corregido
- **Fecha de guardado desfasada**: cada nota se escribía en disco con el `updatedAt` del guardado *anterior*, lo que podía hacer ganar a la copia equivocada en la sincronización con Drive. Las copias restauradas de Drive conservan su fecha original.
- **Importar una nota suelta** (copias `.inklus` de Drive o "copia .inklus" del editor) fallaba con "No es un cuaderno .inklus v2 válido": el formato se detecta por su contenido (`notebook.json` / `document.json`).
- **`.inklus` antiguo importado vacío**: la nota se guardaba fuera del cuaderno creado; ahora queda dentro, con un id nuevo.

### Rendimiento
- Crear, renombrar, duplicar o borrar una nota, y cambiar título/color/etiquetas de un cuaderno, ya **no leen ni reescriben todas las notas del cuaderno**.
- Las notas grandes (más de ~20.000 puntos) se codifican y escriben en otro isolate: el autoguardado no bloquea la escritura.

## [1.4.2] — 2026-09-26

### Añadido
- **Restaurar desde Drive** (Configuración): trae la versión más reciente de cada nota (*last-write-wins*) y reúne las que no existen en el dispositivo en el cuaderno "Recuperado de Drive".
- **Importación unificada**: un solo "Importar .inklus o respaldo" detecta el tipo por el contenido (cuaderno `.inklus` v1/v2 o respaldo completo `.zip`), incluidos los `.inklus` que Android renombra a `.zip`.

### Corregido
- **Cierre al abrir la app (release)**: R8 eliminaba `WorkDatabase_Impl` de WorkManager (Room la crea por reflexión); reglas `-keep` en `proguard-rules.pro`.
- **Inicio de sesión con Google** ("serverClientId must be provided"): `google_sign_in` 7 se inicializa una vez con el cliente web antes de cualquier llamada.
- **Sincronización colgada**: las peticiones a Drive expiran a los 60 s en vez de dejar el ☁️ "sincronizando" para siempre.
- **Pérdida de trabajo tras un cierre inesperado**: se elimina el intervalo de autoguardado configurable (hasta 30 min); cada cambio se guarda al instante.

### Cambiado
- **Nuevo icono**: plumilla estilográfica con trazo de tinta dorada sobre degradado azul (fuentes SVG en `assets/icon/`).
- **Configuración rediseñada** con el sistema de diseño (componentes compartidos en `ui/widgets/page_scaffold.dart`) y versión visible de la app.

## [1.4.0] — 2026-09-26

### Añadido
- **Editor rediseñado**: barra superior única, opciones de cada herramienta en popovers, panel lateral de páginas, indicador de página y zoom compactos.
- **Plumas favoritas** (3 + resaltador) con color y grosor propios y colores recientes.
- **Rechazo de palma** completo: lápiz apoyado/cerca (hover), ventana de gracia, tamaño de contacto; modo *solo lápiz* automático y desplazamiento con un dedo; botón lateral del S-Pen = borrador.
- **Regla y transportador** usables: tamaño fijo, cm/mm de la hoja, ángulo en vivo, arrastre y rotación con los dedos, trazo pegado al borde / arco.
- **Lazo** para trazos, imágenes y textos: mover, eliminar, recolorear, cambiar grosor, duplicar y convertir a texto.
- **Borrador** con modos parcial / trazo completo / solo resaltador.
- **Figuras**: mantener para enderezar, triángulo y elipse.
- **Puntero láser**, **lupa** que sigue al lápiz.
- **Texto enriquecido**: negrita, cursiva, subrayado, alineación, familia, tamaño.
- **Búsqueda** en todas las notas (texto y escritura reconocida), sin acentos, desde la biblioteca.
- **Marcadores de página**, ir a página, atajos de teclado.
- **Importar PDF para anotar** (una página de la nota por página del PDF).
- **Historial de versiones local** y **modo nocturno de escritura**.
- **Biblioteca** nueva: navegación lateral, favoritos, recientes, vista cuadrícula/lista.
- **Marketplace** de paquetes gratuitos (plantillas, paletas, stickers) con verificación sha256.
- Licencia **GPL-3.0-or-later**.

### Corregido
- Exportaciones y miniaturas recortadas (solo salía un cuarto de la hoja).
- Hoja fija desplazada al abrir y margen del rayado en el centro.
- Pantalla que dejaba de responder al tacto tras mover una selección con el lápiz.
- Doble toque con la goma del lápiz que borraba la página sin poder deshacer.
- Rectángulos detectados abiertos (sin el cuarto lado) y óvalos forzados a círculo.
- Pérdida de capa/figura/ajustes al pegar, transformar o rellenar; orden de trazos al deshacer.
- Respaldo local que no incluía cuadernos ni notas; escrituras no atómicas; zip-slip.

### Cambiado
- Sistema de diseño central (tema, tokens, colores); tema claro/oscuro recordado.
- Rendimiento del lienzo: culling, cachés por trazo, trazo activo O(1), nivel de detalle en plantillas.
