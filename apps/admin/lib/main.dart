import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvcSupabase.init(); // no-op until SUPABASE_URL/ANON_KEY are provided
  runApp(const ProviderScope(child: EvcAdminApp()));
}

/// EVC Admin — ops control panel over the shared evc_* packages, backed by
/// real Supabase data (admins are provisioned in the Supabase dashboard).
class EvcAdminApp extends StatelessWidget {
  const EvcAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.admin.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      // Already signed in on this device → straight to the dashboard.
      home: EvcSupabase.hasSession ? const MainShell() : const LoginScreen(),
    );
  }
}
