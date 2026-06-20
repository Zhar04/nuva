import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tokens.dart';

/// App theme mode (System / Light / Dark), persisted across launches.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = switch (prefs.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
        (_) => ThemeModeNotifier());

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
  /// Theme tokens. Falls back to the light token set if the theme extension is
  /// somehow missing (e.g. a context above MaterialApp) instead of hard-asserting
  /// with `!` — a missing extension must never white-screen the app.
  NuvaTokens get nuva =>
      Theme.of(this).extension<NuvaThemeExt>()?.tokens ?? NuvaTokens.light();
}
