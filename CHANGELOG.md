# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones [SemVer](https://semver.org/lang/es/).

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
