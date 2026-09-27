// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/error_log.dart';

void main() {
  // Todo (binding + runApp) dentro de la misma zona para evitar el aviso
  // "Zone mismatch" de Flutter.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Errores de framework: reporte por defecto (pantalla roja en debug,
      // log en release) + registro local (ver ErrorLog; nunca sale del
      // dispositivo salvo que el usuario lo comparta).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        ErrorLog.record(details.exception, details.stack,
            context: details.context?.toDescription());
      };
      // Errores asíncronos del motor/plugins.
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorLog.record(error, stack, context: 'plataforma');
        return true;
      };

      runApp(const InklusApp());
    },
    (error, stackTrace) {
      debugPrint('Uncaught exception: $error');
      debugPrintStack(stackTrace: stackTrace);
      ErrorLog.record(error, stackTrace);
    },
  );
}
