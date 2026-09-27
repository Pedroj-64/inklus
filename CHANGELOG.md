# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones [SemVer](https://semver.org/lang/es/).

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
