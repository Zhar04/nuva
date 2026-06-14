import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Photo-placeholder avatar: soft gradient circle/rounded-square with initials.
/// Replace with a real CachedNetworkImage when we have hosted photos.
class GradientAvatar extends StatelessWidget {
  final String initials;
  final List<Color> gradient;
  final double size;
  final double radius;
  final double fontSize;

  const GradientAvatar({
    super.key,
    required this.initials,
    required this.gradient,
    this.size = 56,
    this.radius = 18,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Section header used on detail pages.
class SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const SectionLabel({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: t.textTer,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  const Tag({
    super.key,
    required this.label,
    this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final fg = selected ? Colors.white : (color ?? t.text);
    final bg = selected ? (color ?? t.blue) : t.surfaceElevated.withValues(alpha: 0.6);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: selected ? Colors.transparent : t.divider),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}

class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const StarRow({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Padding(
          padding: const EdgeInsets.only(right: 1),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? t.teal : t.textTer,
          ),
        );
      }),
    );
  }
}
