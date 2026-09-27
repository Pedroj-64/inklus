// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Todo (binding + runApp) dentro de la misma zona para evitar el aviso
  // "Zone mismatch" de Flutter.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Registra errores de framework sin perder el reporte por defecto
      // (pantalla roja en debug, log en release).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      runApp(const InklusApp());
    },
    (error, stackTrace) {
      debugPrint('Uncaught exception: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
