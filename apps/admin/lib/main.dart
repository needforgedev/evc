import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

void main() => runApp(const EvcAdminApp());

/// EVC Admin — ops app. A thin shell over the shared evc_* packages.
class EvcAdminApp extends StatelessWidget {
  const EvcAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.admin.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      home: const EvcLandingScreen(app: EvcApp.admin),
    );
  }
}
