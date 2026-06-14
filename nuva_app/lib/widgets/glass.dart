import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Liquid Glass surface. Translucent, blurred, with subtle inner highlight.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final bool elevated;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.blur = 20,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    // Liquid Glass: elevated cards get a crisp top sheen + a soft blue-tinted
    // lift shadow so they read as tappable glass floating above the backdrop
    // (instead of flat grey panels).
    final sheen = elevated
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: t.dark ? 0.18 : 0.55),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.28],
          )
        : null;
    final shadows = elevated
        ? <BoxShadow>[
            ...t.glassShine,
            BoxShadow(
              color: t.blue.withValues(alpha: t.dark ? 0.22 : 0.15),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ]
        : null;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: elevated ? t.glassBgUp : t.glassBgDown,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: elevated
                  ? (t.dark ? const Color(0x4DFFFFFF) : const Color(0x70FFFFFF))
                  : t.glassBorder,
              width: 1,
            ),
            boxShadow: shadows,
          ),
          foregroundDecoration: sheen == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: sheen,
                ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Animated gradient backdrop with two coloured blobs. The "stage" all glass
/// surfaces refract against.
class GlassBackdrop extends StatelessWidget {
  final Widget child;
  const GlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: t.backdrop),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(color: t.blobA, size: 360),
        ),
        Positioned(
          top: 240,
          right: -100,
          child: _Blob(color: t.blobB, size: 320),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

/// Primary action — solid blue pill with soft elevation.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: t.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(t.blueDeep.withOpacity(0.15)),
        ),
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary action — glass pill, blends with backdrop.
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: t.glassBgUp,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: t.glassBorder),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: t.text),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
