# ✒️ Inklus

🌐 **English** · [Español](README.es.md)

Handwriting app for **stylus** tablets, in the spirit of GoodNotes or Samsung Notes, built with **Flutter**. Real pressure sensitivity, palm rejection, notebooks with templates, lasso, handwriting recognition, PDF import and optional Google Drive backup.

**Free, ad-free, no accounts and no analytics.** Everything lives on your device.

**Main platform:** Android (tablets) · **Secondary:** Linux desktop.

> 📚 [`CHANGELOG.md`](CHANGELOG.md) · [Privacy](docs/privacy.md) · [On-device testing](docs/testing.md) · [Marketplace](marketplace/README.md)

---

## 📲 Install (Android)

Inklus is distributed as an APK on [**GitHub Releases**](https://github.com/Pedroj-64/inklus/releases) (it is not on Google Play).

1. From the latest release, download the APK for your tablet. Most current tablets use **`app-arm64-v8a-release.apk`**; if it won't install, try `app-armeabi-v7a-release.apk`.
2. Open it. Android will ask you to allow **installing apps from unknown sources** for your browser or file manager: grant it for this installation only.
3. Updates install the same way, on top of the previous version, without losing your notes.

> Before switching devices, export a backup: **Settings → Export full backup** (or enable Google Drive backup).

---

## 🎨 Features

### ✍️ Stylus writing
- **Real pressure** modulating stroke width, smoothed with `perfect_freehand`.
- **Full palm rejection**: detects the pen touching or hovering nearby, with a grace window and contact-size check. Automatic *pen-only* mode.
- **Automatic eraser** with the pen's back end or the S-Pen side button.
- **Finger zoom and pan**: writing and navigating never interfere.
- **Favorite pens** (3 + highlighter) with their own color and width, plus recent colors.

### 🧰 Tools
| Tool | What it does |
|---|---|
| Ballpoint / Pencil | Uniform stroke or pressure-dependent width |
| Highlighter | Wide, translucent stroke |
| Eraser | Partial (splits the stroke like a real eraser), whole stroke, or highlighter only |
| Lasso | Move, scale, rotate, copy, paste, duplicate, recolor and convert to text (strokes, images and text) |
| Shapes | Hold at the end of a stroke to straighten it: lines, rectangles, triangles, ellipses |
| Ruler and protractor | cm/mm measurements on the page, live angle, strokes snap to the edge |
| Rich text | Bold, italic, underline, alignment, font family and size |
| Laser pointer and magnifier | For presenting or writing in detail |
| Images | Insert from the device, move and resize |

### 📄 Templates
| Template | Behavior |
|---|---|
| Infinite canvas | Blank, grows as you write |
| Sheet | A4-like fixed size, with continuous scrolling between sheets |
| Ruled / Grid | Notebook style |
| Custom template | Upload an image: **fixed sheet** or **infinite fill** |

### 📚 Organization
- **Library** with notebooks, covers, favorites, recents and grid/list view.
- **Tags** and **smart folders**.
- **Search** across all notes, including **recognized handwriting** (ML Kit, on-device).
- **Page bookmarks**, go to page and keyboard shortcuts.
- **Trash** with restore and automatic purge after 30 days.
- **Reminders** linked to notebooks and **writing stats** (totals and streaks).

### 💾 Import, export and backup
- **PDF import** to annotate it (one note page per PDF page).
- **Export** a page or a whole notebook to **PNG, PDF, SVG or PPTX** (off-screen rendering, independent of zoom).
- **Native `.inklus` format**: a single file per notebook with the document and its images: shareable and re-importable.
- **Instant save** of every change and local **version history**.
- **Full backup** as `.zip`, with **optional AES-256-GCM encryption** (key derived with PBKDF2).
- **Marketplace** of free packs (templates, palettes, stickers) with sha256 verification.

### ☁️ Google Drive (optional)
The app is **offline-first**: it works 100% without an account or network. If you sign in with Google:
- Each notebook is mirrored to an **Inklus** folder in your Drive as `.inklus`, always in the same file.
- It uses the **`drive.file`** scope: the app only sees files it created itself.
- **Restore from Drive** brings back the latest version of each note, and the version history also shows revisions saved on Drive.

---

## 🔒 Privacy

There are no Inklus servers, analytics or ads. Errors are logged **on the device only** and you decide whether to share them (Settings → Error log). Details in [`docs/privacy.md`](docs/privacy.md).

### Secrets (for contributors and publishers)

- **Never in the repo:** keystore (`*.jks`), `android/key.properties`, `client_secret*.json`, `google-services.json`, `.env`. All are in `.gitignore` and CI (`secret-scan`, gitleaks) rejects anything that slips through.
- **Release signing:** CI reads `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` from *GitHub → Settings → Secrets*. Keep the keystore **outside** the repository with an encrypted backup: losing it prevents updating already-installed APKs.
- **Public (not secret):** the OAuth client ID and the signing SHA-1 fingerprints; they identify the app, they don't grant access. A `client_secret` *is* secret: the app doesn't need it, don't download it.
- **If something leaks:** rotate it in Google Cloud (Credentials), regenerate the GitHub secret, and rewrite history only if the value is still valid.

---

## 🧠 Technical decisions

### Palm rejection
A raw `Listener` receives **all** pointer events before the *gesture arena*. While the pen is touching or near the screen, simultaneous touches are discarded: they don't draw, pan or select. Since `Listener` doesn't compete in the gesture arena, there is no conflict with the zoom/pan `GestureDetector`.

### Paint layers
- **Committed layer** (template + strokes + images) inside a `RepaintBoundary`: the GPU reuses it while only the in-progress stroke changes.
- **Active layer** (in-progress stroke, eraser cursor, selection) on top; repainted every frame without invalidating the committed one. Adding a point is O(1).
- **During zoom/pan** the canvas is drawn from a snapshot and only the strips uncovered by the gesture are painted live; a crisp repaint happens on release.
- Culling, per-stroke caches, level of detail in templates and encoding of large notes in a separate isolate.

### World coordinates
Strokes are stored in zoom-independent coordinates. The transform (scale + translation) only affects the view, so exporting gives the same result at any zoom.

---

## 📁 Structure

```
lib/
├── main.dart · app.dart           # Entry point, theme and locales
├── models/                        # Notebook, Note, Page, Stroke, ImageItem, TextItem, Template
├── logic/
│   ├── canvas_controller.dart     # Central state (+ canvas_view / canvas_selection / canvas_layers)
│   ├── stroke_engine.dart         # Per-tool smoothing
│   ├── palm_rejection.dart        # Palm rejection
│   ├── eraser.dart · lasso.dart   # Fine erasing and selection
│   ├── shape_detector.dart        # Shape recognition
│   ├── ruler.dart · snap_guides.dart
│   └── undo_stack.dart            # Per-page undo/redo
├── services/
│   ├── storage_service.dart       # Local persistence (atomic writes)
│   ├── inklus_format.dart         # .inklus format
│   ├── export_service.dart        # PNG / PDF / SVG (+ pptx_builder.dart)
│   ├── import_service.dart        # .inklus and backups
│   ├── pdf_import_service.dart    # PDF → annotatable pages
│   ├── drive_sync_service.dart    # Google Drive backup
│   ├── backup_crypto.dart         # AES-256-GCM + PBKDF2
│   ├── ocr_service.dart           # Handwriting recognition (ML Kit)
│   ├── search_service.dart · version_history_service.dart
│   ├── reminder_service.dart · writing_stats_service.dart
│   └── marketplace/               # Pack catalog
├── ui/
│   ├── canvas/                    # Canvas, overlays and painter (shared with export)
│   ├── editor/                    # Toolbar, popovers, pages panel, history
│   ├── theme/                     # Design system (theme, tokens, colors)
│   ├── widgets/                   # Shared components
│   └── *_screen.dart              # Library, settings, trash, reminders…
└── l10n/                          # Translations (Spanish / English)
```

---

## 🚀 Development

Requires **Flutter 3.47** (stable).

```bash
flutter pub get
flutter run -d linux        # desktop
flutter run -d <tablet>     # Android (developer mode / USB)
```

### Tests

```bash
flutter analyze
flutter test                                          # models, storage, canvas, history, translations…
flutter test tool/screenshots/screenshots_test.dart   # UI screenshots (build/screenshots)
flutter test integration_test -d <device>             # critical flows on tablet/emulator
```

GitHub Actions CI runs analysis, tests and integration tests on every PR, and publishes signed APKs when a `v*` tag is created (release notes come from the CHANGELOG).

### Google Drive in your own build

If you build a fork you need your own Google Cloud project (no Firebase or `google-services.json` required):

1. In [console.cloud.google.com](https://console.cloud.google.com), create a project and enable the **Google Drive API**.
2. Configure the **OAuth consent screen** with the scope `https://www.googleapis.com/auth/drive.file`.
3. Under **Credentials**, create an **Android** OAuth client (package + your keystore's SHA-1 fingerprint) and a **Web** client; put the web client ID in `android/app/src/main/res/values/strings.xml` (`default_web_client_id`).
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```
   Without the SHA-1 fingerprint registered, Google Sign-In returns error `10`.

---

## 🛠️ Stack

Flutter · Dart · Material 3 · `perfect_freehand` · `pdf` / `printing` · `archive` · `google_sign_in` + `googleapis` · `cryptography` · Google ML Kit (text and digital ink) · `share_plus` · `file_picker` · `shared_preferences` · `intl`

## 📜 License

Inklus is free software: you can redistribute it and/or modify it under the terms of the
**GNU General Public License v3.0 or later** (GPL-3.0-or-later), published by the Free
Software Foundation. See the [`LICENSE`](LICENSE) file.

Copyright © 2026 Pedro ([@Pedroj-64](https://github.com/Pedroj-64)) and Inklus contributors.

Every source file carries the header `// SPDX-License-Identifier: GPL-3.0-or-later`.
Any modified version that is distributed must also be released under GPL-3.0 with its source code.
