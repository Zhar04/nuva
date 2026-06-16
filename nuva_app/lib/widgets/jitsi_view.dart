// Picks the web (iframe) implementation on web, a launch-in-browser fallback
// elsewhere. Real Liquid-Glass-grade in-app video is web here; a future native
// build would use a native Jitsi SDK.
export 'jitsi_view_stub.dart' if (dart.library.html) 'jitsi_view_web.dart';
