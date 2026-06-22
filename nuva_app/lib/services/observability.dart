import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lightweight, dependency-free error capture.
///
/// It does NOT need a third-party SDK to do its most important job: make sure
/// no error is silently swallowed. [guard] installs all three error sinks
/// Flutter exposes (framework, platform, and the surrounding zone), so an
/// uncaught async error can't white-screen the app without a trace. When a real
/// backend (Sentry, or a `/api/v1/telemetry` sink) is wired in, route
/// [report] there — call sites don't change.
class Observability {
  static Future<void> guard(Future<void> Function() runApp) async {
    // 1) Synchronous framework errors (build/layout/paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };
    // 2) Errors that escape the framework to the engine (e.g. in a callback).
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true; // handled — don't crash the isolate
    };
    // 3) Anything thrown in the zone the app runs in (async gaps).
    await runZonedGuarded(runApp, report);
  }

  static Future<void> report(Object error, StackTrace? stack) async {
    // Stub sink: log. Swap for a real telemetry transport in production.
    debugPrint('Observability: $error\n$stack');
  }

  static void breadcrumb(String message, {String? category}) {
    if (kDebugMode) debugPrint('Breadcrumb [$category]: $message');
  }
}
