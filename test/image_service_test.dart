// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/image_service.dart';

void main() {
  group('ImageService.fitWithin', () {
    test('no reduce lo que ya cabe o sin límite', () {
      expect(ImageService.fitWithin(800, 600, 2560), isNull);
      expect(ImageService.fitWithin(2560, 100, 2560), isNull);
      expect(ImageService.fitWithin(9000, 6000, null), isNull);
    });

    test('reduce el lado mayor conservando la proporción', () {
      expect(ImageService.fitWithin(4000, 3000, 2000), (2000, 1500));
      expect(ImageService.fitWithin(3000, 4000, 2000), (1500, 2000));
      expect(ImageService.fitWithin(10000, 1, 1000), (1000, 1));
    });
  });

  testWidgets('decode entrega la imagen reducida al lado máximo', (tester) async {
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('inklus_img_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 400, 200),
        Paint()..color = const Color(0xFF3366FF),
      );
      final src = await recorder.endRecording().toImage(400, 200);
      final png = await src.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${dir.path}/foto.png')
        ..writeAsBytesSync(png!.buffer.asUint8List());

      final service = ImageService();
      final small = await service.decode(file.path, maxSide: 100);
      expect((small.width, small.height), (100, 50));
      final full = await service.decode(file.path, maxSide: null);
      expect((full.width, full.height), (400, 200));
    });
  });
}
