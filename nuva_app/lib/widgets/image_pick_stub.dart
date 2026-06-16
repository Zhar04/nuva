import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Non-web: use image_picker (gallery).
Future<Uint8List?> pickRawImageBytes() async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (x == null) return null;
  return x.readAsBytes();
}
