# 🎨 Sistema de diseño de Inklus

Objetivo: que cada pantalla se sienta del mismo producto, al nivel de GoodNotes/Notability. Código en `lib/ui/theme/` y `lib/ui/widgets/`.

## Piezas

| Qué | Dónde |
|---|---|
| `ThemeData` claro/oscuro (Material 3, esquema `fidelity`) | `ui/theme/app_theme.dart` |
| Colores propios (`context.inklus`, `context.colors`, `context.text`, `context.isDark`) | `ui/theme/inklus_colors.dart` |
| Medidas: `Spacing`, `Radii`, `Motion`, `Sizes`, `Breakpoints` | `ui/theme/tokens.dart` |
| Pantallas secundarias: `InklusPage`, `PageHeader`, `SectionCard`, `SettingsTile`, `EmptyState`, `SheetHeader` | `ui/widgets/page_scaffold.dart` |
| Diálogos: `showConfirmDialog`, `showTextPrompt`, `runWithLoading` | `ui/widgets/dialogs.dart` |

## Reglas

1. **Colores** solo desde `context.colors` (`ColorScheme`) o `context.inklus`. Nada de `Colors.white` / `Color(0x…)` en widgets. Excepción: colores que son **contenido** (portadas `kCoverColors`, etiquetas, líneas de plantilla, selector de color, lienzo).
2. **Medidas** solo de `Spacing`, `Radii`, `Sizes`, `Motion`. Objetivo táctil **≥ 48 dp**.
3. **Texto** con los roles de `context.text` (escala ajustada a tablet). Nada por debajo de **12 pt**; respeta `textScaler` del sistema.
4. **Pantallas secundarias** con `InklusPage` + `SectionCard`/`SettingsTile`/`EmptyState`. Hojas inferiores con `SheetHeader` (el asa la pone el tema). Confirmaciones con `showConfirmDialog`.
5. **Opciones de herramienta** en popovers anclados (`showAnchoredPopover`), no en barras fijas.
6. **Rebuilds**: widgets que dependen del controlador usan `ControllerSelector` con el valor mínimo que muestran (el controlador notifica en cada punto del trazo).
7. **Texto visible** siempre por l10n (`context.l10n`); ver [`TRANSLATING.md`](TRANSLATING.md). Los textos largos (alemán) no deben desbordar: celdas flexibles, `Flexible`/`maxLines` + elipsis.
8. **Accesibilidad**: `Semantics`/`tooltip` en iconos sin texto, swatches, portadas y miniaturas; contraste suficiente en claro y oscuro.

## Checklist «premium» para un PR de UI

- [ ] Tokens en lugar de literales; sin texto < 12 pt ni objetivos < 48 dp
- [ ] Claro y oscuro revisados
- [ ] Idioma largo (de) sin desbordes; escala de texto 1.3 sin romper
- [ ] Estados vacío, carga y error presentes
- [ ] Feedback de pulsación y transiciones con `Motion` (sin animaciones bruscas)
- [ ] Capturas con `flutter test tool/screenshots/screenshots_test.dart`

## Marca e icono

- **Icono**: plumilla blanca escribiendo un trazo dorado sobre degradado azul (`#5B8CFF → #2A4FD6`, tinta `#FFD66B → #FF9F43`). Fuente vectorial en `assets/icon/` (`icon_full.svg`, `icon_foreground.svg`, `icon_background.svg`); los PNG de `flutter_launcher_icons` salen de ahí con `rsvg-convert`.
- **README**: `docs/assets/icon-animated.svg` (la plumilla escribe el trazo en bucle) y `docs/assets/anim/*.{en,es}.svg` (presión, rechazo de palma, figuras, lazo). Son SVG/SMIL escritos a mano y **generados** por `tool/docs_assets/generate.py` (sin dependencias; edita el script, no los SVG).
- Una animación nueva = una función `scene_*` en el script, con fondo propio (se ve igual en tema claro y oscuro) y textos es/en en `TXT`.
