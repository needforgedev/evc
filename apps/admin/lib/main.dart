import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'features/auth/login_screen.dart';

void main() => runApp(const ProviderScope(child: EvcAdminApp()));

/// EVC Admin — ops control panel. A thin shell over the shared evc_* packages,
/// running a full mock (sign in → overview → live map → drivers → trips → ops).
class EvcAdminApp extends StatelessWidget {
  const EvcAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.admin.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}