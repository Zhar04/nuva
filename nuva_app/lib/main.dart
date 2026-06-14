import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/strings.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/backend.dart';
import 'services/observability.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await initializeDateFormatting('ru');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Observability.guard(() async {
    try {
      await Backend.init();
      // Best-effort: attach an anonymous identity so RLS-protected writes work.
      // No-ops if the backend is off or anonymous sign-ins are disabled.
      await AuthService().ensureSession();
    } catch (e, s) {
      await Observability.report(e, s);
    }
    final router = await buildRouter();
    runApp(ProviderScope(child: NuvaApp(router: router)));
  });
}

class NuvaApp extends ConsumerWidget {
  final dynamic router;
  const NuvaApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return MaterialApp.router(
      title: 'Nuva',
      debugShowCheckedModeBanner: false,
      theme: NuvaTheme.light(),
      darkTheme: NuvaTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: lang.locale,
      supportedLocales: const [
        Locale('ru'),
        Locale('kk'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        if (width < 600 || child == null) return child ?? const SizedBox();
        return ColoredBox(
          color: const Color(0xFF0B1220),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: SizedBox(
                width: 390,
                height: 844,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
