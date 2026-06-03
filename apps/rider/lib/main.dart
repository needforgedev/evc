import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/home/home_screen.dart';
import 'features/onboarding/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvcSupabase.init(); // no-op until SUPABASE_URL/ANON_KEY are provided
  runApp(const ProviderScope(child: EvcRiderApp()));
}

/// EVC Rider — passenger app. A thin shell over the shared evc_* packages,
/// with real Supabase-backed registration + rider data.
class EvcRiderApp extends StatelessWidget {
  const EvcRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.rider.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      // Registered on this device → straight to Home, no re-login.
      home: EvcSupabase.hasSession ? const HomeScreen() : const SplashScreen(),
    );
  }
}
