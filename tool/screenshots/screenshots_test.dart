// SPDX-License-Identifier: GPL-3.0-or-later
// ignore_for_file: invalid_use_of_visible_for_testing_member
// Capturas de la UI real (biblioteca, editor, regla) a PNG, sin dispositivo.
// Útil para revisar el diseño y comparar antes/después.
//
//   flutter test tool/screenshots/screenshots_test.dart
//
// Salida: $INKLUS_SHOTS_DIR (por defecto build/screenshots). Está fuera de
// test/ a propósito: no forma parte de la suite ni de la CI.
// Nota: el texto pintado directamente en un Canvas (números de la regla) sale
// como cajas porque el entorno de test no tiene fuente por defecto.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/note.dart';
import 'package:flutter/gestures.dart';
import 'package:inklus/app.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:inklus/services/marketplace/marketplace_service.dart';
import 'package:inklus/ui/marketplace_screen.dart';
import 'package:inklus/ui/note_list_screen.dart';
import 'package:inklus/ui/settings_screen.dart';
import 'package:inklus/ui/trash_screen.dart';
import 'package:inklus/ui/reminder_screen.dart';
import 'package:inklus/ui/writing_stats_screen.dart';
import 'package:inklus/ui/create_notebook_screen.dart';
import 'package:inklus/ui/onboarding_screen.dart';
import 'package:inklus/ui/widgets/template_picker_sheet.dart';
import 'package:inklus/ui/widgets/tag_editor_sheet.dart';
import 'package:inklus/ui/widgets/smart_folders_sheet.dart';
import 'package:inklus/ui/widgets/layers_sidebar.dart';
import 'package:inklus/services/template_library_service.dart';
import 'package:inklus/ui/home_screen.dart';
import 'package:inklus/ui/theme/app_theme.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/services/image_service.dart';
import 'package:inklus/ui/canvas/drawing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

final out = Platform.environment['INKLUS_SHOTS_DIR'] ?? 'build/screenshots';

Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final base = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(Future.value(ByteData.view(File('$base/$f').readAsBytesSync().buffer)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(File('$base/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
}

Future<void> shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final element = find.byType(MaterialApp).evaluate().first;
    final image = await captureImage(element);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory tmp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Directory(out).createSync(recursive: true);
    await loadFonts();
    tmp = Directory.systemTemp.createTempSync('inklus_shots_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tmp.path);
    SharedPreferences.setMockInitialValues({'onboarding_seen': false});
  });

  Future<void> seed() async {
    final s = StorageService.instance;
    if ((await s.loadIndex()).isNotEmpty) return;
    for (final (t, c) in [('Matemáticas', 0xFF1E88E5), ('Diario', 0xFFE53935), ('Física II', 0xFF43A047), ('Ideas', 0xFFFDD835)]) {
      await s.createNotebook(title: t, colorValue: c, template: const PageTemplate(type: TemplateType.ruled));
    }
  }

  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';
    testWidgets('library $tag', (tester) async {
      tester.view.physicalSize = const Size(2560, 1600);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.platformBrightnessTestValue =
          dark ? Brightness.dark : Brightness.light;
      await tester.runAsync(seed);
      await tester.pumpWidget(const InklusApp());
      await settle(tester);
      await shot(tester, 'library_$tag');
    });

    testWidgets('editor $tag', (tester) async {
      tester.view.physicalSize = const Size(2560, 1600);
      tester.view.devicePixelRatio = 2;
      final metas = await tester.runAsync(() async {
        await seed();
        return StorageService.instance.loadIndex();
      });
      final nb = await tester.runAsync(() => StorageService.instance.loadNotebook(metas!.first.id));
      final note = nb!.notes.first;
      final page = note.pages.first;
      page.strokes.clear();
      for (var i = 0; i < 6; i++) {
        page.strokes.add(Stroke(
          id: 's$i',
          points: [for (var x = 0; x < 60; x++) StrokePoint(80.0 + x * 6, 120.0 + i * 40 + 12 * (x % 7 == 0 ? 1 : 0), 0.5)],
          tool: ToolType.pen,
          colorValue: 0xFF1A237E,
          size: 3,
        ));
      }
      await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kAppLocale,
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: HomeScreen(note: note, notebookId: nb.id),
      ));
      await settle(tester);
      await shot(tester, 'editor_$tag');
      if (!dark) {
        // Tocar la pluma activa abre su popover de opciones.
        await tester.tap(find.byTooltip('Bolígrafo 1'));
        await settle(tester);
        await shot(tester, 'editor_pen_popover');
      }
    });
  }

  for (final proto in [false, true]) {
    testWidgets('ruler $proto', (tester) async {
      tester.view.physicalSize = const Size(2000, 1300);
      tester.view.devicePixelRatio = 2;
      final c = CanvasController(StorageService.instance)..setHapticEnabled(false);
      c.setTemplate(const PageTemplate(type: TemplateType.sheet));
      await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kAppLocale,
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: DrawingCanvas(controller: c, imageService: ImageService())),
      ));
      await settle(tester);
      c.fitView(c.viewportSize);
      c.cycleRuler();
      if (proto) c.cycleRuler();
      c.setRulerTransform(c.rulerCenter, proto ? 0 : -0.5);
      await tester.pump();
      await shot(tester, proto ? 'protractor' : 'ruler');
      await tester.runAsync(c.flush);
    });
  }

  testWidgets('marketplace', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    final offline = MarketplaceService(
      client: MockClient((_) async => throw const SocketException('sin red')),
      storage: StorageService.instance,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kAppLocale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: MarketplaceScreen(service: offline),
    ));
    await settle(tester);
    await shot(tester, 'marketplace');
  });

  // --- Resto de pantallas y hojas (revisión del sistema de diseño) ---------
  Future<void> app(WidgetTester tester, Widget home, {bool dark = false}) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kAppLocale,
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: home,
    ));
    await settle(tester);
  }

  /// Pantalla con un botón que abre una hoja/diálogo; captura con ella abierta.
  Future<void> sheet(WidgetTester tester, String name,
      Future<void> Function(BuildContext) open, {bool dark = false}) async {
    await app(
      tester,
      Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: FilledButton(onPressed: () => open(ctx), child: const Text('abrir')),
          ),
        ),
      ),
      dark: dark,
    );
    await tester.tap(find.text('abrir'));
    await settle(tester);
    await shot(tester, name);
  }

  for (final dark in [false, true]) {
    final tag = dark ? 'dark' : 'light';
    testWidgets('notes $tag', (tester) async {
      final nb = await tester.runAsync(() async {
        await seed();
        final metas = await StorageService.instance.loadIndex();
        return StorageService.instance.loadNotebook(metas.first.id);
      });
      await app(tester, NoteListScreen(notebook: nb!), dark: dark);
      await shot(tester, 'notes_$tag');
    });

    testWidgets('settings $tag', (tester) async {
      await app(tester, const SettingsScreen(), dark: dark);
      await shot(tester, 'settings_$tag');
    });
  }

  testWidgets('editor hojas apiladas', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    // Solo lápiz: un dedo desplaza la página.
    SharedPreferences.setMockInitialValues({
      'onboarding_seen': false,
      'finger_drawing': false,
      'finger_drawing_user_set': true,
    });
    Page sheet(String name, double y0) {
      final p = Page.blank(name: name, template: const PageTemplate(type: TemplateType.sheet));
      for (var i = 0; i < 8; i++) {
        p.strokes.add(Stroke(
          id: '$name$i',
          points: [for (var x = 0; x < 60; x++) StrokePoint(-400.0 + x * 10, y0 + i * 60 + 8 * (x % 5 == 0 ? 1 : 0), 0.5)],
          tool: ToolType.pen,
          colorValue: 0xFF1A237E,
          size: 4,
        ));
      }
      return p;
    }
    final note = Note(
      id: 'note_stack',
      title: 'Apuntes',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      pages: [sheet('A', 300), sheet('B', -780)],
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kAppLocale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: HomeScreen(note: note, notebookId: 'nb_stack'),
    ));
    await settle(tester);
    final canvas = find.byType(DrawingCanvas);
    final g = await tester.startGesture(tester.getCenter(canvas), kind: PointerDeviceKind.touch);
    for (var i = 1; i <= 20; i++) {
      await g.moveBy(const Offset(0, -22));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await settle(tester);
    await shot(tester, 'editor_stacked');
    SharedPreferences.setMockInitialValues({'onboarding_seen': false});
  });

  testWidgets('trash', (tester) async {
    await app(tester, TrashScreen(storage: StorageService.instance));
    await shot(tester, 'trash');
  });

  testWidgets('reminders', (tester) async {
    await app(tester, const ReminderScreen());
    await shot(tester, 'reminders');
  });

  testWidgets('stats', (tester) async {
    await app(tester, const WritingStatsScreen());
    await shot(tester, 'stats');
  });

  testWidgets('stats con datos', (tester) async {
    await tester.runAsync(() async {
      final now = DateTime.now();
      final days = <String, dynamic>{};
      for (var i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        if (i % 7 == 5) continue; // algún día sin escribir
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
        days[key] = {
          'date': d.toIso8601String(),
          'strokes': 40 + (i * 37) % 260,
          'pages': i % 4 == 0 ? 2 : 0,
          'minutes': 10 + i % 25,
          'docs': 1 + i % 3,
        };
      }
      File('${tmp.path}/inklus/stats.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(days));
    });
    await app(tester, const WritingStatsScreen());
    await shot(tester, 'stats_data');
    File('${tmp.path}/inklus/stats.json').deleteSync();
  });

  testWidgets('trash con cuadernos', (tester) async {
    await tester.runAsync(() async {
      final nb = await StorageService.instance
          .createNotebook(title: 'Apuntes viejos', colorValue: 0xFF8E24AA);
      await StorageService.instance.deleteNotebook(nb.id);
    });
    await app(tester, TrashScreen(storage: StorageService.instance));
    await shot(tester, 'trash_items');
  });

  testWidgets('create notebook', (tester) async {
    await app(tester, const CreateNotebookScreen(notebookCount: 4));
    await shot(tester, 'create_notebook');
  });

  testWidgets('onboarding', (tester) async {
    await app(tester, const OnboardingScreen());
    await shot(tester, 'onboarding');
  });

  testWidgets('template picker', (tester) async {
    final c = CanvasController(StorageService.instance)..setHapticEnabled(false);
    await sheet(
      tester,
      'template_picker',
      (ctx) => showTemplatePicker(ctx,
          controller: c,
          imageService: ImageService(),
          templateLibrary: TemplateLibraryService()),
    );
  });

  testWidgets('tag editor', (tester) async {
    await sheet(
      tester,
      'tag_editor',
      (ctx) => showTagEditor(
          context: ctx,
          currentTags: const ['clase', 'física'],
          allAvailableTags: const ['clase', 'física', 'ideas', 'diario']),
    );
  });

  testWidgets('smart folders', (tester) async {
    final metas = await tester.runAsync(() async {
      await seed();
      return StorageService.instance.loadIndex();
    });
    await sheet(
      tester,
      'smart_folders',
      (ctx) => showSmartFoldersSheet(context: ctx, metas: metas!, currentFolder: null),
    );
  });

  testWidgets('layers', (tester) async {
    final c = CanvasController(StorageService.instance)..setHapticEnabled(false);
    await app(
      tester,
      Scaffold(
        body: Row(children: [
          const Expanded(child: SizedBox()),
          SizedBox(width: 280, child: LayersSidebar(controller: c, onClose: () {})),
        ]),
      ),
    );
    await shot(tester, 'layers');
  });
}
