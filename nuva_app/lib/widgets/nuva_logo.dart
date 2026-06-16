import 'package:flutter/material.dart';

/// Nuva "ripple" mark — concentric rings + center dot (the support-spreading
/// metaphor from the brand). Ported from nuva-brand.jsx (viewBox 48).
class NuvaLogo extends StatelessWidget {
  final double size;
  final Color color; // ring base (blue)
  final Color accent; // inner ring gradient end + center (teal)
  const NuvaLogo({
    super.key,
    this.size = 48,
    this.color = const Color(0xFF2E6FD6),
    this.accent = const Color(0xFF0FA995),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RipplePainter(color: color, accent: accent),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Color color;
  final Color accent;
  _RipplePainter({required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 48.0;
    final c = Offset(size.width / 2, size.height / 2);

    void ring(double r, Color col, double w) {
      canvas.drawCircle(
        c,
        r * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * k
          ..color = col
          ..isAntiAlias = true,
      );
    }

    ring(20, color.withValues(alpha: 0.30), 2.2);
    ring(14, color.withValues(alpha: 0.55), 2.8);

    // inner ring: blue -> teal gradient
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * k
      ..isAntiAlias = true
      ..shader = LinearGradient(colors: [color, accent]).createShader(
        Rect.fromCircle(center: c, radius: 8 * k),
      );
    canvas.drawCircle(c, 8 * k, inner);

    // center dot
    canvas.drawCircle(c, 3 * k, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.color != color || old.accent != accent;
}

/// The like / "support" heart from the design (a clean rounded line-heart),
/// outline or filled. Replaces Material's favorite icon.
class NuvaHeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;
  final double strokeWidth;
  const NuvaHeartIcon({
    super.key,
    this.size = 18,
    required this.color,
    this.filled = false,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HeartPainter(
        color: color,
        filled: filled,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final double strokeWidth;
  _HeartPainter({
    required this.color,
    required this.filled,
    required this.strokeWidth,
  });

  // Exact transcription of the NuvaIcon "heart" SVG path (viewBox 24):
  // M12 20 s-7-4.3-7-9.3 A3.8 3.8 0 0 1 12 8 a3.8 3.8 0 0 1 7-2.3 c0 5-7 9.3-7 9.3 Z
  Path _heart(double s) {
    final k = s / 24.0;
    final p = Path();
    p.moveTo(12 * k, 20 * k);
    // s-7-4.3-7-9.3 (smooth cubic; prev not a cubic -> cp1 = current point)
    p.cubicTo(12 * k, 20 * k, 5 * k, 15.7 * k, 5 * k, 10.7 * k);
    // A3.8 3.8 0 0 1 12 8
    p.arcToPoint(Offset(12 * k, 8 * k),
        radius: Radius.circular(3.8 * k), clockwise: true);
    // a3.8 3.8 0 0 1 7-2.3  -> abs (19, 5.7)
    p.arcToPoint(Offset(19 * k, 5.7 * k),
        radius: Radius.circular(3.8 * k), clockwise: true);
    // c0 5-7 9.3-7 9.3  -> abs cp(19,10.7) cp(12,15) end(12,15)
    p.cubicTo(19 * k, 10.7 * k, 12 * k, 15 * k, 12 * k, 15 * k);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _heart(size.width);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (filled) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) =>
      old.color != color ||
      old.filled != filled ||
      old.strokeWidth != strokeWidth;
}
