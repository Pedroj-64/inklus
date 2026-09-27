# 🛒 Marketplace de Inklus

Catálogo **comunitario y gratuito** de paquetes para [Inklus](https://github.com/Pedroj-64/inklus):
plantillas de página, paletas de color y stickers. Todo el contenido es de licencia libre.

> Esta carpeta es la **plantilla** del repositorio `inklus-marketplace`. Para ponerlo en marcha:
> crea el repo `Pedroj-64/inklus-marketplace`, copia aquí dentro el contenido de esta carpeta y
> haz push. La app lo lee desde `https://cdn.jsdelivr.net/gh/Pedroj-64/inklus-marketplace@main/`
> (constante `MarketplaceService.defaultBaseUrl`). Mientras no exista, la app muestra el catálogo
> incluido de serie.

## Cómo funciona

```
packs/<id>/manifest.json   ← lo que escribe el autor
packs/<id>/*.png           ← imágenes (stickers, fondos de plantilla, vista previa)
catalog.json               ← lo genera la CI (NO editar a mano): manifiestos + sha256 + tamaños
```

1. Cada PR se valida con `dart run bin/build_catalog.dart --check`.
2. Al fusionar en `main`, la CI regenera `catalog.json` y lo publica.
3. jsDelivr lo sirve por CDN (gratis, con caché). La app descarga el catálogo, y al instalar un
   paquete **verifica el sha256 y el tamaño** de cada archivo antes de guardarlo. Nunca se ejecuta
   nada descargado.

## Publicar un paquete

1. Haz un fork y crea `packs/<tu-id>/manifest.json` (el id: minúsculas, números y guiones).
2. Añade tus imágenes dentro de `packs/<tu-id>/` (PNG, JPG o WebP; máx. 5 MB cada una, 20 MB en total).
3. Ejecuta `dart pub get && dart run bin/build_catalog.dart --check`.
4. Abre un Pull Request. Un mantenedor lo revisa (ver `CODEOWNERS`).

### Tipos de paquete

**Plantillas** — paramétricas (tipos integrados) o con imagen de fondo:

```json
{
  "id": "mis-plantillas", "name": "Mis plantillas", "description": "…",
  "type": "template", "author": "Tu nombre", "license": "CC-BY-4.0", "version": "1.0.0",
  "templates": [
    { "name": "Rayado ancho", "params": { "type": "ruled", "spacing": 64, "lineColor": "#9DB6D9" } },
    { "name": "Agenda semanal", "image": "packs/mis-plantillas/agenda.png", "infinite": false }
  ],
  "preview": "packs/mis-plantillas/preview.png"
}
```

Tipos para `params.type`: `blank`, `sheet`, `ruled`, `grid`, `dots`, `music`, `planner`, `habit`.
`params.infinite` (por defecto `true`) decide si el patrón es un lienzo infinito o una hoja.

**Paletas** — de 2 a 16 colores `#RRGGBB`:

```json
{ "id": "paleta-mar", "name": "Mar", "type": "palette", "palette": ["#0EA5E9", "#0369A1"], … }
```

**Stickers** — imágenes PNG con transparencia:

```json
{ "id": "estrellas", "name": "Estrellas", "type": "stickers",
  "stickers": ["packs/estrellas/star.png", "packs/estrellas/sparkle.png"], … }
```

## Reglas

- Solo contenido **propio o con licencia libre**. Licencias aceptadas: `CC0-1.0`, `CC-BY-4.0`, `CC-BY-SA-4.0`.
- Nada de marcas registradas, contenido ofensivo ni datos personales.
- Retiradas: abre un issue con la etiqueta `retirada` (proceso DMCA/derechos de autor).
