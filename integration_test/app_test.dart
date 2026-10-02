// SPDX-License-Identifier: GPL-3.0-or-later
// Flujos críticos de punta a punta sobre la app real (R5 del roadmap).
//
//   flutter test integration_test -d <tablet|emulador|linux>
//
// Usa una carpeta de datos temporal: no toca las notas del dispositivo.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inklus/app.dart';
import 'package:inklus/services/app_paths.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/canvas/drawing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory data;

  setUp(() {
    data = Directory.systemTemp.createTempSync('inklus_it_');
    AppPaths.rootOverride = data;
    SharedPreferences.setMockInitialValues({}); // primer arranque
  });

  tearDown(() {
    AppPaths.rootOverride = null;
    if (data.existsSync()) data.deleteSync(recursive: true);
  });

  /// Espera a que aparezca [finder] (animaciones, E/S real).
  Future<void> waitFor(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        // Deja terminar la transición: en CI (lento) el widget ya existe
        // pero aún se está moviendo, y el tap caería fuera de él.
        await tester.pump(const Duration(milliseconds: 600));
        return;
      }
    }
    final visible = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .take(40)
        .join(' | ');
    throw TestFailure('No apareció: $finder\nEn pantalla: $visible');
  }

  testWidgets('bienvenida → crear cuaderno → escribir con lápiz → se guarda',
      (tester) async {
    await tester.pumpWidget(const InklusApp(locale: Locale('es')));

    // 1. Primer arranque: bienvenida.
    await waitFor(tester, find.text('Saltar'));
    await tester.tap(find.text('Saltar'));
    await waitFor(tester, find.text('Mis cuadernos'));

    // 2. Crear un cuaderno con los valores por defecto ("Cuaderno 1").
    await tester.tap(find.text('Nuevo cuaderno'));
    await waitFor(tester, find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    // .last: la biblioteca vacía (debajo) tiene otro botón "Crear cuaderno".
    final create = find.widgetWithText(FilledButton, 'Crear cuaderno').last;
    await waitFor(tester, create);
    await tester.tap(create);

    // 3. Se abre la lista de notas; abrir la primera.
    await waitFor(tester, find.text('Sin título'));
    await tester.tap(find.text('Sin título'));
    await waitFor(tester, find.byType(DrawingCanvas));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // 4. Escribir un trazo con el lápiz en el centro del lienzo.
    final center = tester.getCenter(find.byType(DrawingCanvas));
    final pen = await tester.startGesture(center, kind: PointerDeviceKind.stylus);
    for (var i = 1; i <= 20; i++) {
      await pen.moveTo(center + Offset(i * 6.0, (i % 5) * 4.0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    await pen.up();
    await tester.pump();

    // 5. Volver: el editor guarda antes de salir.
    await tester.tap(find.byTooltip('Volver a la biblioteca'));
    await waitFor(tester, find.text('Cuaderno 1'));

    // 6. Está en disco.
    final storage = StorageService.instance;
    final metas = await storage.loadIndex();
    expect(metas.single.title, 'Cuaderno 1');
    final nb = (await storage.loadNotebook(metas.single.id))!;
    expect(nb.notes.single.pages.first.strokes, hasLength(1));
  });
}
