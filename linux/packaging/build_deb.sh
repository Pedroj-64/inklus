#!/bin/sh
# Empaqueta build/linux/x64/release/bundle como inklus_<versión>_amd64.deb.
# Uso (desde la raíz): flutter build linux --release && linux/packaging/build_deb.sh
set -eu
VERSION=$(grep '^version:' pubspec.yaml | sed -E 's/version: *([^+]*).*/\1/')
BUNDLE=build/linux/x64/release/bundle
OUT=${1:-inklus_${VERSION}_amd64.deb}
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
install -d "$ROOT/opt/inklus" "$ROOT/usr/bin" "$ROOT/usr/share/applications" \
  "$ROOT/usr/share/icons/hicolor/512x512/apps" "$ROOT/usr/share/mime/packages" \
  "$ROOT/usr/share/metainfo" "$ROOT/DEBIAN"
cp -r "$BUNDLE"/. "$ROOT/opt/inklus/"
ln -s /opt/inklus/inklus "$ROOT/usr/bin/inklus"
cp linux/packaging/com.inklus.inklus.desktop "$ROOT/usr/share/applications/"
cp linux/packaging/com.inklus.inklus.metainfo.xml "$ROOT/usr/share/metainfo/"
cp linux/packaging/inklus-mime.xml "$ROOT/usr/share/mime/packages/inklus.xml"
cp assets/icon/app_icon.png "$ROOT/usr/share/icons/hicolor/512x512/apps/inklus.png"
cat > "$ROOT/DEBIAN/control" <<CTRL
Package: inklus
Version: $VERSION
Section: graphics
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libglib2.0-0, libstdc++6
Maintainer: Inklus contributors <https://github.com/Pedroj-64/inklus>
Homepage: https://github.com/Pedroj-64/inklus
Description: Free handwritten notes for stylus, tablets and desktop
 Pressure-sensitive pens, palm rejection, PDF annotation, search and export.
 Free and open source (GPL-3.0-or-later), no premium tier.
CTRL
dpkg-deb --root-owner-group --build "$ROOT" "$OUT"
