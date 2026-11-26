// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/services/app_paths.dart';
import 'package:inklus/ui/create_notebook_screen.dart';
import 'package:inklus/ui/home_screen.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/services/image_service.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/marketplace_screen.dart';
import 'package:inklus/ui/notebook_library.dart';
import 'package:inklus/ui/settings_screen.dart';
import 'package:inklus/ui/study_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guías de accesibilidad de Flutter (TalkBack): todo botón tiene nombre y
/// un objetivo táctil ≥ 48 dp.
void main() {
  late Directory tmp;
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
    tmp = Directory.systemTemp.createTempSync('inklus_a11y_');
    AppPaths.rootOverride = tmp;
  });
  tearDown(() {
    AppPaths.rootOverride = null;
    tmp.deleteSync(recursive: true);
  });

  Future<void> check(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: kLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  }

  testWidgets('editor', (tester) async {
    await check(tester, HomeScreen(note: Note.newBlank(), notebookId: 'nb'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('crear cuaderno', (tester) => check(tester, const CreateNotebookScreen(notebookCount: 1)));

  testWidgets('marketplace', (tester) => check(tester, const MarketplaceScreen()));

  testWidgets('biblioteca', (tester) async {
    await check(tester, const NotebookLibraryScreen());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('configuración', (tester) => check(tester, const SettingsScreen()));

  testWidgets('estudiar (sin tarjetas)', (tester) async {
    final c = CanvasController(StorageService(baseDir: tmp));
    addTearDown(c.dispose);
    await check(tester, StudyScreen(controller: c, imageService: ImageService()));
  });

  for (final (name, screen) in [
    ('editor', () => HomeScreen(note: Note.newBlank(), notebookId: 'nb')),
    ('biblioteca', () => const NotebookLibraryScreen()),
    ('configuración', () => const SettingsScreen()),
  ]) {
    testWidgets('$name con texto del sistema al 200 % no desborda', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2), size: Size(1280, 800)),
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: kLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
