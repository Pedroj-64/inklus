#!/bin/sh
# Empaqueta build/linux/x64/release/bundle como Inklus-x86_64.AppImage.
# Uso (desde la raíz): flutter build linux --release && linux/packaging/build_appimage.sh
set -eu
BUNDLE=build/linux/x64/release/bundle
OUT=${1:-Inklus-x86_64.AppImage}
rm -rf AppDir && mkdir -p AppDir/usr/bin AppDir/usr/share/mime/packages
cp -r "$BUNDLE"/. AppDir/usr/bin/
cp assets/icon/app_icon.png AppDir/inklus.png
cp linux/packaging/com.inklus.inklus.desktop AppDir/inklus.desktop
mkdir -p AppDir/usr/share/metainfo
cp linux/packaging/com.inklus.inklus.metainfo.xml AppDir/usr/share/metainfo/
cp linux/packaging/inklus-mime.xml AppDir/usr/share/mime/packages/inklus.xml
cat > AppDir/AppRun <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/inklus" "$@"
RUN
chmod +x AppDir/AppRun
[ -x appimagetool ] || {
  curl -fsSL -o appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool
}
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 ./appimagetool AppDir "$OUT"
