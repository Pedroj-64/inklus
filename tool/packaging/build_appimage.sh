#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Empaqueta el build de Linux de Inklus como AppImage (un solo archivo
# ejecutable que funciona en casi cualquier distribución x86_64).
#
#   flutter build linux --release
#   APPIMAGETOOL=/ruta/appimagetool-x86_64.AppImage tool/packaging/build_appimage.sh
#
# Resultado: dist/Inklus-<versión>-x86_64.AppImage
# appimagetool: https://github.com/AppImage/appimagetool/releases (continuous).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(grep '^version:' "$ROOT/pubspec.yaml" | sed 's/version: *//; s/+.*//')"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
APPDIR="$ROOT/build/Inklus.AppDir"
OUT="$ROOT/dist/Inklus-$VERSION-x86_64.AppImage"
TOOL="${APPIMAGETOOL:-appimagetool}"

[ -x "$BUNDLE/inklus" ] || { echo "Falta $BUNDLE: ejecuta 'flutter build linux --release'"; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$ROOT/dist"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

# Punto de entrada: el bundle de Flutter busca lib/ y data/ junto al binario.
cat > "$APPDIR/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/inklus" "$@"
RUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/inklus.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Inklus
Comment=Cuadernos de escritura a mano
Exec=inklus
Icon=inklus
Categories=Office;Education;Graphics;
Terminal=false
X-AppImage-Version=$VERSION
DESK

cp "$ROOT/assets/icon/app_icon.png" "$APPDIR/inklus.png"
ln -sf inklus.png "$APPDIR/.DirIcon"

# APPIMAGE_EXTRACT_AND_RUN: funciona aunque el sistema no tenga FUSE.
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" --no-appstream "$APPDIR" "$OUT"
echo "AppImage: $OUT"
