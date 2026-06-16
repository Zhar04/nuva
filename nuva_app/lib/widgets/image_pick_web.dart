import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Pick image bytes via a real browser file input — works reliably across
/// browsers (Chrome/Brave/Safari) without the image_picker web quirks.
Future<Uint8List?> pickRawImageBytes() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.display = 'none';
  html.document.body?.append(input);
  final completer = Completer<Uint8List?>();

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(files.first);
    await reader.onLoad.first;
    input.remove();
    if (!completer.isCompleted) {
      final r = reader.result;
      Uint8List? bytes;
      if (r is Uint8List) {
        bytes = r;
      } else if (r is ByteBuffer) {
        bytes = r.asUint8List();
      } else if (r is List<int>) {
        bytes = Uint8List.fromList(r);
      }
      completer.complete(bytes);
    }
  });

  input.click();
  return completer.future;
}
