import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/onboarding/splash_screen.dart';
import 'features/shell/driver_gate.dart';
import 'l10n/app_strings.dart';
import 'state/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvcSupabase.init(); // no-op until SUPABASE_URL/ANON_KEY are provided
  runApp(const ProviderScope(child: EvcDriverApp()));
}

/// EVC Driver — partner app. A thin shell over the shared evc_* packages,
/// with real Supabase-backed registration + driver data. English + Arabic (RTL).
class EvcDriverApp extends ConsumerWidget {
  const EvcDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: EvcApp.driver.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Registered on this device → the gate decides: dashboard once all docs
      // are uploaded, otherwise the mandatory upload screen. No re-login.
      home: EvcSupabase.hasSession ? const DriverGate() : const SplashScreen(),
    );
  }
}
