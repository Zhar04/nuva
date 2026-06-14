import 'package:flutter/material.dart';

/// Nuva design tokens. Liquid Glass palette + spacing + radius.
/// Ported from nuva-tokens.jsx.
class NuvaTokens {
  final bool dark;

  // Core
  final Color text;
  final Color textSec;
  final Color textTer;
  final Color blue;
  final Color blueDeep;
  final Color teal;
  final Color danger;

  // Gradient backdrop layers
  final Color bgBase1;
  final Color bgBase2;
  final Color bgBase3;
  final Color blobA;
  final Color blobB;

  // Glass primitives
  final Color glassBgUp;
  final Color glassBgDown;
  final Color glassBorder;
  final List<BoxShadow> glassShine;

  // Surfaces
  final Color surface;
  final Color surfaceElevated;
  final Color divider;

  const NuvaTokens._({
    required this.dark,
    required this.text,
    required this.textSec,
    required this.textTer,
    required this.blue,
    required this.blueDeep,
    required this.teal,
    required this.danger,
    required this.bgBase1,
    required this.bgBase2,
    required this.bgBase3,
    required this.blobA,
    required this.blobB,
    required this.glassBgUp,
    required this.glassBgDown,
    required this.glassBorder,
    required this.glassShine,
    required this.surface,
    required this.surfaceElevated,
    required this.divider,
  });

  factory NuvaTokens.light() => NuvaTokens._(
        dark: false,
        text: const Color(0xFF0E1E33),
        textSec: const Color(0x850E1E33),
        textTer: const Color(0x520E1E33),
        blue: const Color(0xFF2E6FD6),
        blueDeep: const Color(0xFF1E5688),
        teal: const Color(0xFF0FA095),
        danger: const Color(0xFFE04B4D),
        bgBase1: const Color(0xFFE9EEF6),
        bgBase2: const Color(0xFFDDE6F2),
        bgBase3: const Color(0xFFF4F7FC),
        blobA: const Color(0x554FA0E8),
        blobB: const Color(0x4436C9B6),
        glassBgUp: const Color(0xCCFFFFFF),
        glassBgDown: const Color(0x99FFFFFF),
        glassBorder: const Color(0x40FFFFFF),
        glassShine: const [
          BoxShadow(
            color: Color(0x0F0E1E33),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x80FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
            spreadRadius: -0.5,
          ),
        ],
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFF2F6FC),
        divider: const Color(0x140E1E33),
      );

  factory NuvaTokens.dark() => NuvaTokens._(
        dark: true,
        text: const Color(0xFFEAF1FB),
        textSec: const Color(0x9EE1EBFA),
        textTer: const Color(0x66E1EBFA),
        blue: const Color(0xFF5EA0F0),
        blueDeep: const Color(0xFF3E7BD4),
        teal: const Color(0xFF36C9B6),
        danger: const Color(0xFFFF6B6B),
        bgBase1: const Color(0xFF080C14),
        bgBase2: const Color(0xFF0F1622),
        bgBase3: const Color(0xFF13202E),
        blobA: const Color(0x665EA0F0),
        blobB: const Color(0x4D36C9B6),
        glassBgUp: const Color(0x33FFFFFF),
        glassBgDown: const Color(0x1AFFFFFF),
        glassBorder: const Color(0x33FFFFFF),
        glassShine: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
            spreadRadius: -0.5,
          ),
        ],
        surface: const Color(0xFF0F1622),
        surfaceElevated: const Color(0xFF182438),
        divider: const Color(0x1AFFFFFF),
      );

  LinearGradient get backdrop => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgBase1, bgBase2, bgBase3],
        stops: const [0.0, 0.55, 1.0],
      );
}

class NuvaSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class NuvaRadius {
  static const double s = 12;
  static const double m = 18;
  static const double l = 24;
  static const double xl = 32;
  static const double pill = 999;
}
