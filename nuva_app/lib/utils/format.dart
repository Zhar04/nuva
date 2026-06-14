import 'package:flutter/material.dart';

/// Parse a '#RRGGBB' (or 'RRGGBB' / '#AARRGGBB') hex string into a [Color].
Color hexToColor(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF7FB7E8);
}

const _gradientPalette = <List<Color>>[
  [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
  [Color(0xFFFFB6C1), Color(0xFFFFC8DD)],
  [Color(0xFF93D8B5), Color(0xFFB7E8CC)],
  [Color(0xFFD4B5F0), Color(0xFFE8D4F5)],
  [Color(0xFF7FE0D4), Color(0xFFB0EDE5)],
  [Color(0xFFF5D78E), Color(0xFFFAE4B2)],
];

/// Deterministic soft gradient for an anonymous alias (so the same alias always
/// gets the same colours).
List<Color> aliasGradient(String alias) =>
    _gradientPalette[alias.hashCode.abs() % _gradientPalette.length];

/// Short Russian "time ago" label for a timestamp.
String relativeRu(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'только что';
  if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
  if (diff.inHours < 24) return '${diff.inHours} ч назад';
  if (diff.inDays < 7) return '${diff.inDays} дн назад';
  return '${when.day.toString().padLeft(2, '0')}.${when.month.toString().padLeft(2, '0')}.${when.year}';
}
