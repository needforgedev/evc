import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/onboarding/splash_screen.dart';
import 'features/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvcSupabase.init(); // no-op until SUPABASE_URL/ANON_KEY are provided
  runApp(const ProviderScope(child: EvcDriverApp()));
}

/// EVC Driver — partner app. A thin shell over the shared evc_* packages,
/// with real Supabase-backed registration + driver data.
class EvcDriverApp extends StatelessWidget {
  const EvcDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.driver.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      // Once registered on this device, the session is restored from storage —
      // the driver goes straight to the dashboard, no re-login.
      home: EvcSupabase.hasSession ? const MainShell() : const SplashScreen(),
    );
  }
}
