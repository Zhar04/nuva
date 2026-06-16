import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'avatar.dart';
import 'image_pick.dart';

/// Shows the user's uploaded avatar (a base64 data URL) if present, otherwise a
/// gradient initials placeholder. Drop-in alongside [GradientAvatar].
class UserAvatar extends StatelessWidget {
  final String avatar; // data URL or ''
  final String initials;
  final List<Color> gradient;
  final double size;
  final double radius;
  final double fontSize;
  const UserAvatar({
    super.key,
    required this.avatar,
    required this.initials,
    this.gradient = const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
    this.size = 56,
    this.radius = 18,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataUrl(avatar);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return GradientAvatar(
      initials: initials,
      gradient: gradient,
      size: size,
      radius: radius,
      fontSize: fontSize,
    );
  }
}

/// Decode a `data:...;base64,xxxx` URL (or bare base64) to bytes; null on fail.
Uint8List? decodeDataUrl(String dataUrl) {
  if (dataUrl.isEmpty) return null;
  try {
    final i = dataUrl.indexOf(',');
    return base64Decode(i >= 0 ? dataUrl.substring(i + 1) : dataUrl);
  } catch (_) {
    return null;
  }
}

/// Pick an image from the gallery and return it as a compressed JPEG base64
/// data URL, resized to [maxWidth]. We resize in Dart (the `image` package)
/// because image_picker ignores maxWidth/quality on web. Returns null on cancel.
Future<String?> pickImageDataUrl({int maxWidth = 512, int quality = 75}) async {
  final raw = await pickRawImageBytes();
  if (raw == null) return null;
  try {
    final decoded = img.decodeImage(raw);
    if (decoded != null) {
      final resized = decoded.width > maxWidth
          ? img.copyResize(decoded, width: maxWidth)
          : decoded;
      final jpg = img.encodeJpg(resized, quality: quality);
      return 'data:image/jpeg;base64,${base64Encode(jpg)}';
    }
  } catch (_) {
    // fall through to the raw bytes (the server size-guard still applies)
  }
  return 'data:image/jpeg;base64,${base64Encode(raw)}';
}
