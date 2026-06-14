import 'package:flutter/foundation.dart';

/// Observability stub. When sentry_flutter is wired back in (see
/// pubspec.yaml), swap this for the Sentry implementation. The contract stays
/// the same — main.dart and call sites do not change.
class Observability {
  static Future<void> guard(Future<void> Function() runApp) async {
    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    };
    await runApp();
  }

  static Future<void> report(Object error, StackTrace? stack) async {
    debugPrint('Observability: $error\n$stack');
  }

  static void breadcrumb(String message, {String? category}) {
    if (kDebugMode) debugPrint('Breadcrumb [$category]: $message');
  }
}
