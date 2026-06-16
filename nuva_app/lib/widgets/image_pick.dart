// Web uses a native <input type=file> (most reliable in the browser); other
// platforms use image_picker.
export 'image_pick_stub.dart' if (dart.library.html) 'image_pick_web.dart';
