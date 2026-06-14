import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class NuvaTheme {
  static ThemeData light() => _build(NuvaTokens.light(), Brightness.light);
  static ThemeData dark() => _build(NuvaTokens.dark(), Brightness.dark);

  static ThemeData _build(NuvaTokens t, Brightness brightness) {
    final base = ThemeData(brightness: brightness);
    final textTheme = GoogleFonts.onestTextTheme(base.textTheme).apply(
      bodyColor: t.text,
      displayColor: t.text,
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: t.bgBase1,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: t.blue,
        onPrimary: Colors.white,
        secondary: t.teal,
        onSecondary: Colors.white,
        error: t.danger,
        onError: Colors.white,
        surface: t.surface,
        onSurface: t.text,
      ),
      textTheme: textTheme,
      extensions: [NuvaThemeExt(tokens: t)],
    );
  }
}

class NuvaThemeExt extends ThemeExtension<NuvaThemeExt> {
  final NuvaTokens tokens;
  const NuvaThemeExt({required this.tokens});

  @override
  ThemeExtension<NuvaThemeExt> copyWith({NuvaTokens? tokens}) =>
      NuvaThemeExt(tokens: tokens ?? this.tokens);

  @override
  ThemeExtension<NuvaThemeExt> lerp(
          covariant ThemeExtension<NuvaThemeExt>? other, double t) =>
      this;
}

extension NuvaContext on BuildContext {
  NuvaTokens get nuva => Theme.of(this).extension<NuvaThemeExt>()!.tokens;
}
